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
  
  /// Adds a new category from a creating or editing question request.
  ///
  /// If the created category from the request already exists, just sends
  /// back to the request, won't creates again.
  ///
  /// - Parameters:
  ///   - name: The category's name.
  ///   - question: The created or edited question.
  ///   - req: The request.
  static func addCategory(
    _ name: String,
    to question: Question,
    on req: Request
  ) throws -> Future<Void> {
    return Category.query(on: req)
      .filter(\.name == name).first()
      .flatMap(to: Void.self) { foundCategory in
        if let exisitingCatgory = foundCategory {
          return question.categories
            .attach(exisitingCatgory, on: req)
            .transform(to: ())
        } else {
          let category = Category(name: name)
          return category.save(on: req)
            .flatMap(to: Void.self) { savedCategory in
              return question.categories
                .attach(savedCategory, on: req)
                .transform(to: ())
          }
        }
    }
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
