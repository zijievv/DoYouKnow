//
//  UsersController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor

struct UsersController: RouteCollection {
  /// Required to register the `User`'s routes.
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "users")
    
    usersRoute.get(use: getAllHandler)
    usersRoute.get(User.parameter, use: getHandler)
    usersRoute.get(User.parameter, "questions", use: getQuestionsHandler)
    usersRoute.post(User.self, use: createHandler)
  }
  
  // MARK: GET requests.
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
  
  /// Gets user's all questions.
  ///
  /// Route at `/api/users/<user ID>/questions`.
  func getQuestionsHandler(_ req: Request) throws -> Future<[Question]> {
    return try req.parameters.next(User.self)
      .flatMap(to: [Question].self) { user in
        try user.questions.query(on: req).all()
    }
  }
  
  // MARK: POST & PUT & DELETE requests.
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
}
