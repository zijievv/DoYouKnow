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
  /// ID of the question.
  var id: Int?
  /// The question.
  var question: String
  /// The detail of the question.
  var detail: String
  
  /// Creates a `Question` instance.
  ///
  /// - Parameters:
  ///   - question: The question.
  ///   - detail: The detail of the question.
  init(question: String, detail: String) {
    self.question = question
    self.detail = detail
  }
}

/// Allows `Question` to be used as a dynamis migration.
extension Question: Migration {}
/// Allows `Question` to be encoded to and decoded from HTTP messages.
extension Question: Content {}
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
