//
//  Token.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

/// Stores user's token the client can save.
final class Token: Codable {
  /// The token's ID.
  var id: UUID?
  /// The token string provided to clients.
  var token: String
  /// The ID of the user owning the token.
  var userID: User.ID
  
  init(token: String, userID: User.ID) {
    self.token = token
    self.userID = userID
  }
}

extension Token {
  /// Generates a token for a user.
  ///
  /// - Parameter user: The user the generated token for.
  /// - Returns: A token for the user.
  static func generate(for user: User) throws -> Token {
    let random = try CryptoRandom().generateData(count: 16)
    return try Token(token: random.base64EncodedString(),
                     userID: user.requireID())
  }
}

/// Allows `User` to be used as a dynamic migration.
extension Token: Migration {
  static func prepare(on connection: MySQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.reference(from: \.userID, to: \User.id)
    }
  }
}

/// Makes the `Token` model conform to Fluent's `Model`.
extension Token: MySQLUUIDModel {}
/// Allows `Token` to be encoded to and decoded from HTTP messages.
extension Token: Content {}

extension Token: Authentication.Token {
  /// The userID key on `Token`.
  static let userIDKey: UserIDKey = \Token.userID
  /// Tells Vapor what type the user is.
  typealias UserType = User
}

/// Allows to use `Token` with bearer authentication.
///
/// Bearer authentication is a mechanism for sending a token to authenticate
/// requests. It uses the Authorization header, like HTTP basic
/// authentication, but the header looks like Authorization:
/// `Bearer <TOKEN STRING>`.
extension Token: BearerAuthenticatable {
  /// Tells Vapor the key path to the token key.
  static let tokenKey: TokenKey = \Token.token
}
