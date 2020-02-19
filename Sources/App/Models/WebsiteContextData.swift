//
//  WebsiteContextData.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
//import Leaf
//import Fluent
//import Authentication

/// Context for index page.
struct IndexContext: Encodable {
  let title: String
  let questions: [Question]
  let userLoggedIn: Bool
  let showCookieMessage: Bool
}

/// Context for question detail page.
struct QuestionContext: Encodable {
  /// Page's title
  let title: String
  /// The question rendered on the page.
  let question: Question
  /// The user owning the question.
  let userOfQuestion: User
  let categories: Future<[Category]>
  ///
  let answersData: [AnswerData]
}

struct AnswerData: Encodable {
  let answer: Answer
  let user: Future<User>
}

/// Context for Answer detail page.
struct AnswerContext: Encodable {
  let title: String
  let question: Question
  let userOfQuestion: User
  let answer: Answer
  let userOfAnswer: User
}

/// Context for user page.
struct UserContext: Encodable {
  /// Page's title
  let title: String
  /// The user.
  let user: User
  /// The questions the user owning.
  let questions: [Question]
}

/// Context for all users page.
struct AllUsersContext: Encodable {
  let title: String
  let users: [User]
}

/// Context for all categories page.
struct AllCategoriesContext: Encodable {
  let title = "All Categories"
  let categories: Future<[Category]>
}

struct CategoryContext: Encodable {
  let title: String
  let category: Category
  let questions: Future<[Question]>
}

/// Stores the required data when cerating or editing a question.
struct CreateQuestionData: Content {
//  let userID: User.ID
  let question: String
  let detail: String
  let categories: [String]?
}

struct CreateQuestionContext: Encodable {
  let title = "Create A Question"
//  let users: Future<[User]>
  /// Supports The Cross-Site Request Forgery token.
  let csrfToken: String
}

struct CreateAnswerContext: Encodable {
  let title = "Write Your Answer"
  let users: Future<[User]>
  let questions: Future<[Question]>
}

struct EditQuestionContext: Encodable {
  let title = "Edit Question"
  let question: Question
//  let users: Future<[User]>
  let editing = true
  let categories: Future<[Category]>
}

struct EditAnswerContext: Encodable {
  let title = "Edit Answer"
  let questions: Future<[Question]>
  let answer: Answer
  let users: Future<[User]>
  let editing = true
}

struct LoginContext: Encodable {
  let title = "Log In"
  let loginError: Bool
  
  init(loginError: Bool = false) {
    self.loginError = loginError
  }
}

struct LoginPostData: Content {
  let username: String
  let password: String
}

struct RegisterContext: Encodable {
  let title = "Register"
  let message: String?
  
  init(message: String? = nil) {
    self.message = message
  }
}

struct RegisterData: Content {
  let name: String
  let username: String
  let password: String
  let confirmPassword: String
}

extension RegisterData: Validatable, Reflectable {
  static func validations() throws -> Validations<RegisterData> {
    var validations = Validations(RegisterData.self)
    try validations.add(\.name, .ascii)
    try validations.add(\.username, .alphanumeric && .count(3...))
    try validations.add(
      \.password,
      .characterSet(.alphanumerics + .punctuationCharacters + .symbols)
        && .count(8...)
    )
    
    validations.add("passwords match") { model in
      guard model.password == model.confirmPassword else {
        throw BasicValidationError("password don't match")
      }
    }
    return validations
  }
}
