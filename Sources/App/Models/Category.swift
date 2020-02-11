//
//  Category.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import FluentMySQL

/// Stores the categories using to tag the questions.
final class Category: Codable {
  /// The ID of the category.
  var id: Int?
  /// The category's name.
  var name: String
  
  init(name: String) {
    self.name = name
  }
}

extension Category {
  /// The computed property gets the categories the question tagged.
  var questions: Siblings<Category, Question, QuestionCategoryPivot> {
    return siblings()
  }
}

/// Allows `Category` to be used as a dynamis migration.
extension Category: Migration {}
/// Allows `Category` to be encoded to and decoded from HTTP messages.
extension Category: Content {}
/// Allows `Category` to be used as a dynamic parameter in route definitions.
extension Category: Parameter {}
/// Makes `Category` conform to Fluent's `Model`.
extension Category: MySQLModel {}
