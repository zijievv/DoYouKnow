//
//  QuestionsController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import Fluent
import Authentication

struct QuestionsController: RouteCollection {
  /// Registers `Question`'s routes to the incoming router.
  ///
  /// - Parameter Router: To register any new routes to.
  func boot(router: Router) throws {
    let questionsRoute = router.grouped("api", "questions")
    
    // About Question.
    questionsRoute.get(use: getAllHandler)
    questionsRoute.get(Question.parameter, use: getHandler)
    questionsRoute.get("first", use: getFirstHandler)
    questionsRoute.get("sorted", use: sortedHandler)
    // About User, Answer.
    questionsRoute.get(Question.parameter, "user", use: getUserHandler)
    questionsRoute.get(Question.parameter, "answers", use: getAnswersHandler)
    // About Category.
    questionsRoute.get(Question.parameter, "categories",
                       use: getCategoriesHandler)
    
//    // Instantiate a basic authentication middleware which uses
//    // `BCryptDigest` to verify passwords. Since `User` conforms to
//    // `BasicAuthenticatable`, this is a vailable as a static function on
//    // the model.
//    let basicAuthMiddleware = User.basicAuthMiddleware(
//      using: BCryptDigest())
//    // Create an instance of `GuardAuthenticationMiddleware` which ensures
//    // that requests contain valid authorization.
//    let guardAuthMiddleware = User.guardAuthMiddleware()
//    // Create a middleware group which uses `basicAuthMiddleware` and
//    // `guardAuthMiddleware`.
//    let protected = questionsRoute.grouped(basicAuthMiddleware,
//                                           guardAuthMiddleware)
//    // Connect the *create question* path to `createHandler(_:question:)`
//    // through this middleware group.
//    protected.post(Question.self, use: createHandler)
    let tokenAuthMiddleware = User.tokenAuthMiddleware()
    let guardAuthMiddleware = User.guardAuthMiddleware()
    let tokenAuthGroup = questionsRoute.grouped(tokenAuthMiddleware,
                                                guardAuthMiddleware)
    // About Question.
    tokenAuthGroup.post(QuestionCreateData.self, use: createHandler)
    tokenAuthGroup.put(Question.parameter, use: updateHandler)
    tokenAuthGroup.delete(Question.parameter, use: deleteHandler)
    // About Category.
    tokenAuthGroup.post(
      Question.parameter, "categories", Category.parameter,
      use: addCategoriesHandler)
    tokenAuthGroup.delete(
      Question.parameter, "categories", Category.parameter,
      use: removeCategoriesHandler)
  }
  
  // MARK:- About `Question`.
  /// Gets all the questions.
  ///
  /// Route at `/api/questions/` that accepts a GET request and returns
  /// `Future<Questions>`.
  func getAllHandler(_ req: Request) throws -> Future<[Question]> {
    return Question.query(on: req).all()
  }
  
  /// Get a question with specified ID.
  ///
  /// Route at `/api/questions/<question ID>` that accepts a GET request and
  /// returns `Future<Questions>`.
  func getHandler(_ req: Request) throws -> Future<Question> {
    return try req.parameters.next(Question.self)
  }
  
  /// Gets the first question.
  ///
  /// Route at `/api/questions/first`.
  func getFirstHandler(_ req: Request) throws -> Future<Question> {
    return Question.query(on: req).first().unwrap(or: Abort(.notFound))
  }
  
  /// Gets the sorted questions.
  ///
  /// Route at `/api/questions/sorted`.
  func sortedHandler(_ req: Request) throws -> Future<[Question]> {
    return Question.query(on: req).sort(\.question, .ascending).all()
  }
  
  /// Creates a new question.
  ///
  /// Route at `/api/questions/` that accepts a POST request and returns
  /// `Future<Question>`.
  ///
  /// - Returns: The question once it's saved.
  func createHandler(_ req: Request,
                     data: QuestionCreateData) throws -> Future<Question> {
    let user = try req.requireAuthenticated(User.self)
    let question = try Question(question: data.question,
                                detail: data.detail,
                                userID: user.requireID())
    return question.save(on: req)
  }
  
  /// Updates a question with specified ID.
  ///
  /// Route at `/api/questions/<question ID>` that accepts a PUT request and
  /// returns `Future<Questions>`.
  ///
  /// - Returns: The question once it's saved.
  func updateHandler(_ req: Request) throws -> Future<Question> {
    return try flatMap(
      to: Question.self,
      req.parameters.next(Question.self),
      req.content.decode(QuestionCreateData.self)) {
        question, updatedData in
        question.question = updatedData.question
        question.detail = updatedData.detail
        
        let user = try req.requireAuthenticated(User.self)
        question.userID = try user.requireID()
        
        return question.save(on: req)
    }
  }
  
  /// Deletes a question with specified ID.
  ///
  /// Route at `/api/questions/<question ID>`.
  ///
  /// - Returns: The `HTTPStatus` once the question is deleted.
  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters
      .next(Question.self)
      .delete(on: req)
      .transform(to: .noContent)
  }
  
  // MARK:- About `User`, `Category`.
  /// Gets the user owning the question.
  ///
  /// Route at `/api/questions/<question ID>/user`.
  func getUserHandler(_ req: Request) throws -> Future<User.Public> {
    return try req.parameters.next(Question.self)
      .flatMap(to: User.Public.self) { question in
        question.user.get(on: req).convertToPublic()
    }
  }
  
  /// Gets all answers of the question.
  ///
  /// Route at `/api/questions/<question ID>/answers`.
  func getAnswersHandler(_ req: Request) throws -> Future<[Answer]> {
    return try req.parameters.next(Question.self)
      .flatMap(to: [Answer].self) { question in
        try question.answers.query(on: req).all()
    }
  }
  
  /// Gets the categories of the question.
  ///
  /// Route at `/api/questions/<question ID>/categories`.
  func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
    return try req.parameters.next(Question.self)
      .flatMap(to: [Category].self) { question in
        try question.categories.query(on: req).all()
    }
  }
  
  /// Sets up the relationship between a question and a category.
  ///
  /// Route at `/api/questions/<question ID>/categories/<category ID>`.
  ///
  /// - Returns: The `HTTPStatus` once the relationship is
  /// setted up.
  func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
    // Use `flatMap(to:_:_:)` to extract both the `question` and `category`
    // from the request's parameters.
    return try flatMap(
      to: HTTPStatus.self,
      req.parameters.next(Question.self),
      req.parameters.next(Category.self)) {
        question, category in
        return question.categories
          // Use `attach(to:on:)` to set up the relationship between
          // `question` and `category`.
          // Creates a pivot model and saves it in the database.
          .attach(category, on: req)
          // Transform the result into a `201 Created` response.
          .transform(to: .created)
    }
  }
  
  /// Removes the relationship between a question and a category.
  ///
  /// Route at `/api/questions/<question ID>/categories/<categories ID>`.
  func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
    // Use `flatMap(to:_:_:)` to extract both the question and category from
    // the request's parameters.
    return try flatMap(
      to: HTTPStatus.self,
      req.parameters.next(Question.self),
      req.parameters.next(Category.self)) { question, category in
        return question.categories
          // Use `detach(_:on:)` to remove the relationship between
          // `question` and `category`.
          // This finds the pivot model in the database and deletes it.
          .detach(category, on: req)
          // Transform the result into a `204 No Content` response.
          .transform(to: .noContent)
    }
  }
}

/// Defines the request data that a user now has to send to create a
/// question.
struct QuestionCreateData: Content {
  let question: String
  let detail: String
}
