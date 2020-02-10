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
  func boot(router: Router) throws {
    let questionsRoutes = router.grouped("api", "questions")
    
    questionsRoutes.get(use: getAllHandler)
    questionsRoutes.get(Question.parameter, use: getHandler)
    questionsRoutes.get("first", use: getFirstHandler)
    questionsRoutes.get("sorted", use: sortedHandler)
    questionsRoutes.post(use: createHandler)
    questionsRoutes.put(Question.parameter, use: updateHandler)
    questionsRoutes.delete(Question.parameter, use: deleteHandler)
  }
  
  // MARK: GET requests.
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
  
  // MARK: POST & PUT & DELETE requests.
  /// Creates a new question.
  ///
  /// Route at `/api/questions/` that accepts a POST request and returns
  /// `Future<Question>`.
  /// It returns the question once it's saved.
  func createHandler(_ req: Request) throws -> Future<Question> {
    // Decode the request's JSON into an `Question` model using `Codable`.
    return try req.content.decode(Question.self)
      .flatMap(to: Question.self) { question in
        // Save the model using Fluen.
        // Returns `Future<Question>` as it returns the model once it's
        // saved.
        return question.save(on: req)
    }
  }
  
  /// Updates a question with specified ID.
  ///
  /// Route at `/api/questions/<question ID>` that accepts a PUT request and
  /// returns `Future<Questions>`.
  /// It returns the question once it's saved.
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
  /// Route at `/api/questions/<question ID>` that accepts a DELETE request
  /// and returns `Future<HTTPStatus>`.
  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters
      .next(Question.self)
      .delete(on: req)
      .transform(to: .noContent)
  }
}
