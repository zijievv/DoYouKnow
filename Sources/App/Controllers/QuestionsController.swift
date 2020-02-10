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
    questionsRoutes.post(use: createHandler)
  }
  
  // MARK: GET requests.
  /// Gets all questions.
  func getAllHandler(_ req: Request) throws -> Future<[Question]> {
    return Question.query(on: req).all()
  }
  
  // MARK: POST & PUT & DELETE requests.
  /// Creates a new question.
  ///
  /// Route at `/api/questions` that accepts a POST request and returns
  /// `Future<Question>`.
  /// It returns the answer once it's saved.
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
}
