//
//  WebsiteController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import Leaf
import Fluent

/// Handles all website requests.
struct WebsiteController: RouteCollection {
  /// Registers routes to the incoming router.
  ///
  /// - Parameter router: To register any new routes to.
  func boot(router: Router) throws {
    router.get(use: indexHandler)
    router.get("questions", Question.parameter, use: questionHandler)
    router.get("users", User.parameter, use: userHandler)
    router.get("users", use: allUsersHandler)
  }
  
  /// Gets rendered index page `View`.
  ///
  /// Leaf generates a page from a template called `index.leaf` inside the
  /// directory `Resources/Views`.
  func indexHandler(_ req: Request) throws -> Future<View> {
    return Question.query(on: req).all()
      .flatMap(to: View.self) { questions in
        let questionsData = questions.isEmpty ? nil : questions
        let context = IndexContext(title: "Home page",
                                   questions: questionsData)
        return try req.view().render("index", context)
    }
  }
  
//  func questionHandler(_ req: Request) throws -> Future<View> {
//    return try req.parameters.next(Question.self)
//      .flatMap(to: View.self) { question in
//        return question.user.get(on: req)
//          .flatMap(to: View.self) { userOfQuestion in
//            return try question.answers.query(on: req).all()
//              .flatMap(to: View.self) { answers in
//                let usersOfAnswers: [User] = try answers
//                  .compactMap { answer in
//                    try answer.user.get(on: req).wait()
//                }
//                let context = QuestionContext(
//                  title: question.question,
//                  question: question,
//                  userOfQuestion: userOfQuestion, answers: answers, usersOfAnswers: usersOfAnswers)
//                return try req.view().render("question", context)
//            }
//        }
//    }
//  }
  
//  func questionHandler(_ req: Request) throws -> Future<View> {
//    return try req.parameters.next(Question.self)
//      .flatMap(to: View.self) { question in
//        return question.user.get(on: req)
//          .flatMap(to: View.self) { userOfQuestion in
//            return try question.answers.query(on: req).all()
//              .flatMap(to: View.self) { answers in
//                let usersOfAnswersIDs = answers.compactMap { $0.userID }
//                return User.query(on: req).filter(\.id ~~ usersOfAnswersIDs).all()
//                  .flatMap(to: View.self) { usersOfAnswers in
//                    let context = QuestionContext(title: question.question,
//                                                  question: question,
//                                                  userOfQuestion: userOfQuestion,
//                                                  answers: answers,
//                                                  usersOfAnswers: usersOfAnswers)
//                    return try req.view().render("question", context)
//                }
//            }
//        }
//    }
//  }
  
  func questionHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(Question.self)
      .flatMap(to: View.self) { question in
        return question.user.get(on: req)
          .flatMap(to: View.self) { userOfQuestion in
            let context = QuestionContext(title: question.question, question: question, userOfQuestion: userOfQuestion)
            return try req.view().render("question", context)
        }
    }
  }
  
  func userHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(User.self)
      .flatMap(to: View.self) { user in
        return try user.questions.query(on: req).all()
          .flatMap(to: View.self) { questions in
            let context = UserContext(title: user.name,
                                      user: user,
                                      questions: questions)
            return try req.view().render("user", context)
        }
    }
  }
  
  func allUsersHandler(_ req: Request) throws -> Future<View> {
    return User.query(on: req).all()
      .flatMap(to: View.self) { users in
        let context = AllUsersContext(title: "All Users", users: users)
        return try req.view().render("allUsers", context)
    }
  }
}

/// Context for index page.
struct IndexContext: Encodable {
  let title: String
  let questions: [Question]?
}

/// Context for question detail page.
struct QuestionContext: Encodable {
  /// Page's title
  let title: String
  /// The question rendered on the page.
  let question: Question
  /// The user owning the question.
  let userOfQuestion: User
}

/// Context for user page.
struct UserContext: Encodable {
  /// Page's title
  let title: String
  /// The user.
  let user: User
  // The questions the user owning.
  let questions: [Question]
}

/// Context for all users page.
struct AllUsersContext: Encodable {
  let title: String
  let users: [User]
}
