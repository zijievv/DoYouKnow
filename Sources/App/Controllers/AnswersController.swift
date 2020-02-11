//
//  AnswersController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
//import Fluent

struct AnswersController: RouteCollection {
  func boot(router: Router) throws {
    let answersRoute = router.grouped("api", "answers")
    
    // About Answer
    answersRoute.get(use: getAllHandler)
    answersRoute.get(Answer.parameter, use: getHandler)
    answersRoute.post(Answer.self, use: createHandler)
    answersRoute.put(Answer.parameter, use: updateHandler)
    answersRoute.delete(Answer.parameter, use: deleteHandler)
    // About Question, User.
    answersRoute.get(Answer.parameter, "question", use: getQuestionHandler)
    answersRoute.get(Answer.parameter, "user", use: getUserHandler)
  }
  
  // MARK:- About `Answer`.
  /// Gets all the questions.
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
  func createHandler(_ req: Request, answer: Answer) throws -> Future<Answer> {
    return answer.save(on: req)
  }
  
  /// Updates a answer with specified ID.
  ///
  /// Route at `/api/answers/<answer ID>` that accepts a PUT request and
  /// returns `Future<Answer>`.
  ///
  /// - Returns: The answer once it's saved.
  func updateHandler(_ req: Request) throws -> Future<Answer> {
    return try flatMap(to: Answer.self,
      req.parameters.next(Answer.self),
      req.content.decode(Answer.self)) {
        answer, updatedAnswer in
        answer.answer = updatedAnswer.answer
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
  
  // MARK:- About `Question` and `User`.
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
  func getUserHandler(_ req: Request) throws -> Future<User> {
    return try req.parameters.next(Answer.self)
      .flatMap(to: User.self) { answer in
        answer.user.get(on: req)
    }
  }
}
