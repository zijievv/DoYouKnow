//
//  QuestionCategoryPivot.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import FluentMySQL
import Foundation

/// Sets up the sibling relationship between `Question` and `Category`.
final class QuestionCategoryPivot: MySQLUUIDPivot {
    /// The ID of the model assigned by the database when it's saved.
    var id: UUID?
    /// The `Question`'s id.
    var questionID: Question.ID
    /// The `Category`'s id.
    var categoryID: Category.ID

    /// Tells Fluent the `Question` model in the relationship.
    ///
    /// Required by `Pivot`.
    typealias Left = Question
    /// Tells Fluent the `Category` model in the relationship.
    ///
    /// Required by `Pivot`.
    typealias Right = Category

    /// Tells Fluent the key path of the `questionID` property for the left
    /// side of the relationship.
    static let leftIDKey: LeftIDKey = \.questionID
    /// Tells Fluent the key path of the `categoryID` property for the left
    /// side of the relationship.
    static let rightIDKey: RightIDKey = \.categoryID

    /// Create the `Pivot` instance.
    ///
    /// Required by `ModifiablePivot`.
    /// - Parameters:
    ///   - question: The left side model of the relationship.
    ///   - category: The right side model of the relationship.
    init(_ question: Question, _ category: Category) throws {
        self.questionID = try question.requireID()
        self.categoryID = try category.requireID()
    }
}

/// Allows `QuestionCategoryPivot` to be used as a dynamic migration.
extension QuestionCategoryPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        // Create the table for `QuestionCategoryPivot` in the database.
        return Database.create(self, on: connection) { builder in
            // Use `addProperties(to:)` to add all the fields to the database.
            try addProperties(to: builder)
            // Add a reference between the `questionID` property on
            // `QuestionCategoryPivot` and the `id` property on `Question`.
            // This sets up the foreign key constraint.
            // `.cascade` sets a cascade schema reference action when delete the
            // question. This means that the relationship is automatically removed
            // instead of an error being thrown.
            builder.reference(from: \.questionID,
                              to: \Question.id,
                              onDelete: .cascade)
            // Same as above.
            builder.reference(from: \.categoryID,
                              to: \Category.id,
                              onDelete: .cascade)
        }
    }
}

/// Allows `QuestionCategoryPivot` to use the syntactic sugar Vapor provides
/// for adding and removing the relationship.
extension QuestionCategoryPivot: ModifiablePivot {}
