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
import Authentication

final class User: Codable {
  /// The ID of the model assigned by the database when it's saved.
  var id: UUID?
  /// The user's name.
  var name: String
  /// The user's username. It should be unique.
  var username: String
  /// The user's password
  var password: String
  
  init(name: String, username: String, password: String) {
    self.name = name
    self.username = username
    self.password = password
  }
  
  /// The public appearance, hidding the user's private data.
  final class Public: Codable {
    /// The ID of the model assigned by the database when it's saved.
    var id: UUID?
    /// The user's name.
    var name: String
    /// The user's username. It should be unique.
    var username: String
    
    init(id: UUID?, name: String, username: String) {
      self.id = id
      self.name = name
      self.username = username
    }
  }
}

extension User {
  /// The computed property gets the owned `Question` objects.
  var questions: Children<User, Question> {
    return children(\.userID)
  }
  
  /// The computed property gets the owned `Answer` objects.
  var answers: Children<User, Answer> {
    return children(\.userID)
  }
}

/// Allows `User` to be used as a dynamic migration.
extension User: Migration {
  static func prepare(on connection: MySQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { (builder) in
      try addProperties(to: builder)
      builder.unique(on: \.username)
    }
  }
}

/// Makes the `User` model conform to Fluent's `Model`.
extension User: MySQLUUIDModel {}
/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content {}
/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter {}

/// Allows `User.Public` to be encoded to and decoded from HTTP messages.
/// Allows to return the public view in response.
extension User.Public: Content {}

extension User {
  /// Appears user's non-private data.
  func convertToPublic() -> User.Public {
    return User.Public(id: id, name: name, username: username)
  }
}

extension Future where T: User {
  /// Appears user's non-private data.
  func convertToPublic() -> Future<User.Public> {
    return self.map(to: User.Public.self) { user in
      return user.convertToPublic()
    }
  }
}

extension User: BasicAuthenticatable {
  /// Tells Vapor which key path of `User` is the username.
  static var usernameKey: UsernameKey = \User.username
  /// Tells Vapor which key path of `User` is the password.
  static var passwordKey: PasswordKey = \User.password
}

/// Allows a token to authenticate a user.
extension User: TokenAuthenticatable {
  /// Tells Vapor what a token is.
  typealias TokenType = Token
}

struct AdminUser: Migration {
  typealias Database = MySQLDatabase
  
  static func prepare(on connection: MySQLConnection) -> Future<Void> {
    let password = try? BCrypt.hash("adminpassword")
    guard let hashedPassword = password else {
      fatalError("Failed to create admin user")
    }
    
    let user = User(name: "Admin",
                    username: "admin",
                    password: hashedPassword)
    return user.save(on: connection).transform(to: ())
  }
  
  static func revert(on connection: MySQLConnection) -> Future<Void> {
    return .done(on: connection)
  }
}

/// Allows Vapor to authenticate users with a username and password when
/// they login.
extension User: PasswordAuthenticatable {}
/// Allows the app to save and retrieve your user as part of a session.
extension User: SessionAuthenticatable {}
