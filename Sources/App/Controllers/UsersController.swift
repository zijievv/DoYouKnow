//
//  UsersController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import Fluent

struct UsersController: RouteCollection {
  /// Required to register the `User`'s routes.
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "users")
    
    // About User
    usersRoute.get(use: getAllHandler)
    usersRoute.get(User.parameter, use: getHandler)
    usersRoute.get("search", use: searchHandler)
    usersRoute.post(User.self, use: createHandler)
    // About Question, Answer.
    usersRoute.get(User.parameter, "questions", use: getQuestionsHandler)
    usersRoute.get(User.parameter, "answers", use: getAnswersHandler)
  }
  
  // MARK:- About `User`.
  /// Gets all users
  ///
  /// Route at `/api/users/`.
  func getAllHandler(_ req: Request) throws -> Future<[User]> {
    return User.query(on: req).all()
  }
  
  /// Gets a user with the specified ID.
  ///
  /// Route at `/api/users/<user ID>`.
  func getHandler(_ req: Request) throws -> Future<User> {
    return try req.parameters.next(User.self)
  }
  
  /// Searches all users matched the term.
  ///
  /// Route at `/api/users/search`.
  ///
  /// Example:
  /// ```ascii
  /// http://localhost:8080/api/answer/search?term=Tim
  /// ```
  func searchHandler(_ req: Request) throws -> Future<[User]> {
    guard let searchTerm = req.query[String.self, at: "term"] else {
      throw Abort(.badRequest)
    }
    
    return User.query(on: req).group(.or) { or in
      or.filter(\.username == searchTerm)
      or.filter(\.name == searchTerm)
    }.all()
  }
  
  /// Creates a new user.
  ///
  /// Route at `/api/users/`.
  ///
  /// - parameters:
  ///   - req: The request.
  ///   - user: The created user saved in the database.
  func createHandler(_ req: Request, user: User) throws -> Future<User> {
    return user.save(on: req)
  }
  
  // MARK:- About `Question`, `Answer`.
  /// Gets user's all questions.
  ///
  /// Route at `/api/users/<user ID>/questions`.
  func getQuestionsHandler(_ req: Request) throws -> Future<[Question]> {
    return try req.parameters.next(User.self)
      .flatMap(to: [Question].self) { user in
        try user.questions.query(on: req).all()
    }
  }
  
  /// Gets user's all answers.
  ///
  /// Route at `/api/users/<user ID>/answers`.
  func getAnswersHandler(_ req: Request) throws -> Future<[Answer]> {
    return try req.parameters.next(User.self)
      .flatMap(to: [Answer].self) { user in
        try user.answers.query(on: req).all()
    }
  }
}
