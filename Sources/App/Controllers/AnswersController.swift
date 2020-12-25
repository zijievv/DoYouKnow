//
//  AnswersController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

//import Fluent
import Authentication
import Vapor

struct AnswersController: RouteCollection {
    /// Registers `Answer`'s routes to the incoming router.
    ///
    /// - Parameter Router: To register any new routes to.
    func boot(router: Router) throws {
        let answersRoute = router.grouped("api", "answers")

        // About Answer
        answersRoute.get(use: getAllHandler)
        answersRoute.get(Answer.parameter, use: getHandler)
        // About Question, User.
        answersRoute.get(Answer.parameter, "question", use: getQuestionHandler)
        answersRoute.get(Answer.parameter, "user", use: getUserHandler)

//    let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
//    let guardAuthMiddleware = User.guardAuthMiddleware()
//    let protected = answersRoute.grouped(basicAuthMiddleware,
//                                         guardAuthMiddleware)
//    protected.post(Answer.self, use: createHandler)
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = answersRoute.grouped(tokenAuthMiddleware,
                                                  guardAuthMiddleware)
        tokenAuthGroup.post(AnswerCreateData.self, use: createHandler)
        tokenAuthGroup.put(Answer.parameter, use: updateHandler)
        tokenAuthGroup.delete(Answer.parameter, use: deleteHandler)
    }

    // MARK: - About `Answer`.
    /// Gets all the answers.
    ///
    /// Route at `/api/answers/`.
    func getAllHandler(_ req: Request) throws -> Future<[Answer]> {
        return Answer.query(on: req).all()
    }

    /// Gets a answer with specified ID.
    ///
    /// Route at `/api/answers/<answer ID>`.
    func getHandler(_ req: Request) throws -> Future<Answer> {
        return try req.parameters.next(Answer.self)
    }

    /// Creates a new answer.
    ///
    /// Route at `/api/answers/` that accepts a POST request and returns
    /// `Future<Answer>`.
    ///
    /// - Returns: The answer once it's saved.
    func createHandler(_ req: Request, data: AnswerCreateData) throws -> Future<Answer> {
        let user = try req.requireAuthenticated(User.self)
        let answer = try Answer(answer: data.answer,
                                userID: user.requireID(),
                                questionID: data.questionID)
        return answer.save(on: req)
    }

    /// Updates a answer with specified ID.
    ///
    /// Route at `/api/answers/<answer ID>` that accepts a PUT request and
    /// returns `Future<Answer>`.
    ///
    /// - Returns: The answer once it's saved.
    func updateHandler(_ req: Request) throws -> Future<Answer> {
        return try flatMap(
            to: Answer.self,
            req.parameters.next(Answer.self),
            req.content.decode(AnswerCreateData.self)
        ) {
            answer, updatedData in
            answer.answer = updatedData.answer
            answer.questionID = updatedData.questionID

            let user = try req.requireAuthenticated(User.self)
            answer.userID = try user.requireID()
            return answer.save(on: req)
        }
    }

    /// Deletes a answer with specified ID.
    ///
    /// Route at `/api/answers/<answer ID>`.
    ///
    /// - Returns: The `HTTPStatus` once the answer is deleted.
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters
            .next(Answer.self)
            .delete(on: req)
            .transform(to: .noContent)
    }

    // MARK: - About `Question` and `User`.
    /// Gets the question of the answer.
    ///
    /// Route at `/api/answers/<answer ID>/question`.
    func getQuestionHandler(_ req: Request) throws -> Future<Question> {
        return try req.parameters.next(Answer.self)
            .flatMap(to: Question.self) { answer in
                answer.question.get(on: req)
            }
    }

    /// Gets the user owning the answer.
    ///
    /// Route at `/api/answers/<answer ID>/user`.
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Answer.self)
            .flatMap(to: User.Public.self) { answer in
                answer.user.get(on: req).convertToPublic()
            }
    }
}

/// Defines the request data that a user now has to send to create a
/// answer.
struct AnswerCreateData: Content {
    let answer: String
    let questionID: Question.ID
}
