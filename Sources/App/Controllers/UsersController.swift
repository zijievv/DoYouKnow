//
//  UsersController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor

struct UsersController: RouteCollection {
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "users")
    
    usersRoute.post(User.self, use: createHandler)
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
