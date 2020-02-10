//
//  Question.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import FluentSQLite

final class Question: Codable {
  var id: Int?
  var question: String
  var detail: String
  
  init(question: String, detail: String) {
    self.question = question
    self.detail = detail
  }
}

/// Allows `Question` to be used as a dynamis migration.
extension Question: Migration {}

extension Question: SQLiteModel {}
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
