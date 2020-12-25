//
//  Answer.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import FluentMySQL
import Vapor

/// Stores the submitted answer of a question.
final class Answer: Codable {
    /// The ID of the answer.
    var id: Int?
    /// The answer of the question
    var answer: String
    /// The ID of the user owning the answer
    var userID: User.ID
    /// The question's ID of the answer.
    var questionID: Question.ID

    init(answer: String, userID: User.ID, questionID: Question.ID) {
        self.answer = answer
        self.userID = userID
        self.questionID = questionID
    }
}

extension Answer {
    /// The computed property gets the `User` object who owns the answer.
    var user: Parent<Answer, User> {
        return parent(\.userID)
    }

    /// The computed property gets the `Question` object owning the answer.
    var question: Parent<Answer, Question> {
        return parent(\.questionID)
    }
}

/// Allows `Answer` to be used as a dynamis migration.
extension Answer: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        // Create the table for `Answer` in the database.
        return Database.create(self, on: connection) { builder in
            // The `String` type property `answer` should be type `TEXT` in MySQL
            // database. Cannot use `addProperties(to:)` to add all the fields to
            // the database, otherwise the field `answer` will be setted up by
            // default as `VARCHAR`.
            builder.field(for: \.id, type: .bigint(20), .primaryKey)
            builder.field(for: \.answer, type: .text)
            builder.field(for: \Answer.userID, type: .varbinary(16))
            builder.field(for: \Answer.questionID, type: .bigint(20))

            // Add a reference between the userID on `Answer` and the id property
            // on `User`. This sets up the foreign key constraint between the
            // two tables.
            builder.reference(from: \.userID, to: \User.id)
            // Same as above.
            builder.reference(from: \.questionID, to: \Question.id)
        }
    }
}

/// Allows `Answer` to be encoded to and decoded from HTTP messages.
extension Answer: Content {}
/// Allows `Answer` to be used as a dynamic parameter in route definitions.
extension Answer: Parameter {}
/// Makes `Answer` conform to Fluent's `Model`.
extension Answer: MySQLModel {}
