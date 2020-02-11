//
//  Question.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import FluentMySQL

/// Stores the submitted questions of users.
final class Question: Codable {
  /// The ID of the question.
  var id: Int?
  /// The question.
  var question: String
  /// The detail of the question.
  var detail: String
  /// The user's ID.
  var userID: User.ID
  
  /// Creates a `Question` instance.
  ///
  /// - Parameters:
  ///   - question: The question.
  ///   - detail: The detail of the question.
  ///   - userID: The user's ID.
  init(question: String, detail: String, userID: User.ID) {
    self.question = question
    self.detail = detail
    self.userID = userID
  }
}

extension Question {
  /// The computed property gets the `User` object who owns the question.
  var user: Parent<Question, User> {
    return parent(\.userID)
  }
  
  /// The computed property gets the question's categories.
  var categories: Siblings<Question, Category, QuestionCategoryPivot> {
    return siblings()
  }
}

/// Allows `Question` to be used as a dynamis migration.
extension Question: Migration {
  static func prepare(on connection: MySQLConnection) -> Future<Void> {
    // Create the table for `Question` in the database.
    return Database.create(self, on: connection) { builder in
      // Use `addProperties(to:)` to add all the fields to the database.
      try addProperties(to: builder)
      // Add a reference between the userID on `Question` and the id property
      // on `User`. This sets up the foreign key constraint between the
      // two tables.
      builder.reference(from: \.userID, to: \User.id)
    }
  }
}

/// Allows `Question` to be encoded to and decoded from HTTP messages.
extension Question: Content {}
/// Allows `Question` to be used as a dynamic parameter in route definitions.
extension Question: Parameter {}

/// Makes `Question` conform to Fluent's `Model`.
extension Question: MySQLModel {}
//
// Above ↑
// replaces
// below ↓
//
// /// Makes `Question` conform to Fluent's `Model`.
//extension Question: Model {
//  /// Tell Fluent what database to use for this model.
//  typealias Database = SQLiteDatabase
//  /// Tell Fluent what type the ID is.
//  typealias ID = Int
//  /// Tell Fluent the key path of the model's ID property.
//  public static var idKey: IDKey = \Question.id
//}
