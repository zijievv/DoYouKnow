//
//  User.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Foundation
import Vapor
import FluentMySQL

final class User: Codable {
  /// The ID of the model assigned by the database when it's saved.
  var id: UUID?
  /// The user's name.
  var name: String
  /// The user's username.
  var username: String
  
  init(name: String, username: String) {
    self.name = name
    self.username = username
  }
}

extension User {
  var questions: Children<User, Question> {
    return children(\.userID)
  }
}

/// Makes the `User` model conform to Fluent's `Model`.
extension User: MySQLUUIDModel {}
/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content {}
/// Allows `User` to be used as a dynamic migration.
extension User: Migration {}
/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter {}
