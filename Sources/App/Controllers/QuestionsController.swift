//
//  QuestionsController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import Fluent

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
    questionsRoute.post(Question.self, use: createHandler)
    questionsRoute.put(Question.parameter, use: updateHandler)
    questionsRoute.delete(Question.parameter, use: deleteHandler)
    // About User, Answer.
    questionsRoute.get(Question.parameter, "user", use: getUserHandler)
    questionsRoute.get(Question.parameter, "answers", use: getAnswersHandler)
    // About Category.
    questionsRoute.get(Question.parameter, "categories",
                        use: getCategoriesHandler)
    questionsRoute.post(Question.parameter,
                        "categories",
                        Category.parameter,
                        use: addCategoriesHandler)
    questionsRoute.delete(Question.parameter,
                          "categories",
                          Category.parameter,
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
                     question: Question) throws -> Future<Question> {
    return question.save(on: req)
//    // Decode the request's JSON into an `Question` model using `Codable`.
//    return try req.content.decode(Question.self)
//      .flatMap(to: Question.self) { question in
//        // Save the model using Fluen.
//        // Returns `Future<Question>` as it returns the model once it's
//        // saved.
//        return question.save(on: req)
//    }
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
      req.content.decode(Question.self)) {
        question, updatedQuestion in
        question.question = updatedQuestion.question
        question.detail = updatedQuestion.detail
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
  func getUserHandler(_ req: Request) throws -> Future<User> {
    return try req.parameters.next(Question.self)
      .flatMap(to: User.self) { question in
        question.user.get(on: req)
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
