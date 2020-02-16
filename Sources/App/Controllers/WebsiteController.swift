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
import Authentication

/// Handles all website requests.
struct WebsiteController: RouteCollection {
  /// Registers routes to the incoming router.
  ///
  /// - Parameter router: To register any new routes to.
  func boot(router: Router) throws {
    // Runs `AuthenticationSessionsMiddleware` before the route handlers.
    let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
    let protectedRoutes = authSessionRoutes.grouped(
    RedirectMiddleware<User>(path: "/login"))
    
    authSessionRoutes.get(use: indexHandler)
    authSessionRoutes.get("questions", Question.parameter,
                          use: questionHandler)
    authSessionRoutes.get("users", User.parameter, use: userHandler)
    authSessionRoutes.get("users", use: allUsersHandler)
    authSessionRoutes.get("categories", use: allCategoriesHandler)
    authSessionRoutes.get("categories", Category.parameter,
                          use: categoryHandler)
    
    authSessionRoutes.get("login", use: loginHandler)
    authSessionRoutes.post(LoginPostData.self,
                           at: "login",
                           use: loginPostHandler)
    authSessionRoutes.post("logout", use: logoutHandler)
    //---------------
    protectedRoutes.get("questions", "create", use: createQuestionHandler)
    protectedRoutes.post(CreateQuestionData.self,
                         at: "questions", "create",
                         use: createQuestionPostHandler)
    protectedRoutes.get("questions", Question.parameter, "edit",
                        use: editQuestionHandler)
    protectedRoutes.post("questions", Question.parameter, "edit",
                         use: editQuestionPostHandler)
    protectedRoutes.post("questions", Question.parameter, "delete",
                         use: deleteQuestionHandler)
  }
  
  /// Gets rendered index page `View`.
  ///
  /// Leaf generates a page from a template called `index.leaf` inside the
  /// directory `Resources/Views`.
  func indexHandler(_ req: Request) throws -> Future<View> {
    return Question.query(on: req).all()
      .flatMap(to: View.self) { questions in
        let userLoggedIn = try req.isAuthenticated(User.self)
        print("""
          /////////////////////
          \(userLoggedIn)
          /////////////////////
          """)
        let context = IndexContext(title: "Home page",
                                   questions: questions,
                                   userLoggedIn: userLoggedIn)
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
            let categories = try question.categories.query(on: req).all()
            let context = QuestionContext(title: question.question,
                                          question: question,
                                          userOfQuestion: userOfQuestion,
                                          categories: categories)
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
  
  func allCategoriesHandler(_ req: Request) throws -> Future<View> {
    let categories = Category.query(on: req).all()
    let context = AllCategoriesContext(categories: categories)
    
    return try req.view().render("allCategories", context)
  }
  
  func categoryHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(Category.self)
      .flatMap(to: View.self) { category in
        let questions = try category.questions.query(on: req).all()
        let context = CategoryContext(title: category.name,
                                      category: category,
                                      questions: questions)
        return try req.view().render("category", context)
    }
  }
  
  func createQuestionHandler(_ req: Request) throws -> Future<View> {
    let context = CreateQuestionContext()
    return try req.view().render("createQuestion", context)
  }
  
  func createQuestionPostHandler(
    _ req: Request,
    data: CreateQuestionData
  ) throws -> Future<Response> {
    let user = try req.requireAuthenticated(User.self)
    let question = try Question(question: data.question,
                            detail: data.detail,
                            userID: user.requireID())
    return question.save(on: req)
      .flatMap(to: Response.self) { question in
        guard let id = question.id else {
          throw Abort(.internalServerError)
        }
        
        var categorySaves: [Future<Void>] = []
        
        for category in data.categories ?? [] {
          try categorySaves.append(Category.addCategory(category,
                                                        to: question,
                                                        on: req))
        }
        
        let redirect = req.redirect(to: "/questions/\(id)")
        return categorySaves.flatten(on: req).transform(to: redirect)
    }
  }
//  func createQuestionPostHandler(
//    _ req: Request,
//    question: Question
//  ) throws -> Future<Response> {
//    return question.save(on: req).map(to: Response.self) {
//      question in
//      guard let id = question.id else {
//        throw Abort(.internalServerError)
//      }
//      return req.redirect(to: "/questions/\(id)")
//    }
//  }
  
  func editQuestionHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(Question.self)
      .flatMap(to: View.self) { question in
//        let users = User.query(on: req).all()
        let categories = try question.categories.query(on: req).all()
        let context = EditQuestionContext(question: question,
                                          categories: categories)
        return try req.view().render("createQuestion", context)
    }
  }
  
  func editQuestionPostHandler(_ req: Request) throws -> Future<Response> {
    return try flatMap(
      to: Response.self,
      req.parameters.next(Question.self),
      req.content.decode(CreateQuestionData.self)) { question, data in
        let user = try req.requireAuthenticated(User.self)
        question.question = data.question
        question.detail = data.detail
        question.userID = try user.requireID()
        
        guard let id = question.id else {
          throw Abort(.internalServerError)
        }
        
        return question.save(on: req)
          .flatMap(to: [Category].self) { _ in
            try question.categories.query(on: req).all()
        }.flatMap(to: Response.self) { existingCategories in
          // Stores categories' names.
          let existingStringArray = existingCategories.map { $0.name }
          
          // Stores the categories
          let existingSet = Set<String>(existingStringArray)
          // For categories supplied with the request.
          let newSet = Set<String>(data.categories ?? [])
          
          // Calculate the categories to add to the question and the
          // categories to remove.
          let categoriesToAdd = newSet.subtracting(existingSet)
          let categoriesToRemove = existingSet.subtracting(newSet)
          
          // Create an array of category operation results.
          var categoryResults: [Future<Void>] = []
          
          // Loop through all the categories to add and call
          // `Category.addCategory(_:to:on:)` to set up the relationship.
          // Add each result to the results array.
          for newCategory in categoriesToAdd {
            categoryResults.append(try Category.addCategory(newCategory,
                                                            to: question,
                                                            on: req))
          }
          
          // Loop through all the category names to remove from the question.
          for categoryNameToRemove in categoriesToRemove {
            // Gets the `Category` object from the name of the category to
            // remove.
            let categoryToRemove = existingCategories.first {
              $0.name == categoryNameToRemove
            }
            
            // If the `Category` object exists, use `detach(_:on:)` to
            // remove the relationship and delete the pivot.
            if let category = categoryToRemove {
              categoryResults.append(question.categories.detach(category,
                                                                on: req))
            }
          }
          
          let redirect = req.redirect(to: "/questions/\(id)")
          // Flatten all the future category results. Transform the result
          // to redirect to the updated question's page.
          return categoryResults.flatten(on: req).transform(to: redirect)
        }
    }
//    return try flatMap(
//      to: Response.self,
//      req.parameters.next(Question.self),
//      req.content.decode(Question.self)) { question, data in
//        question.question = data.question
//        question.detail = data.detail
//        question.userID = data.userID
//
//        guard let id = question.id else {
//          throw Abort(.internalServerError)
//        }
//
//        let redirect = req.redirect(to: "/questions/\(id)")
//        return question.save(on: req).transform(to: redirect)
//    }
  }
  
  func deleteQuestionHandler(_ req: Request) throws -> Future<Response> {
    return try req.parameters.next(Question.self)
      .delete(on: req)
      .transform(to: req.redirect(to: "/"))
  }
  
  /// Gets rendered login page.
  ///
  /// Route at `/login`.
  func loginHandler(_ req: Request) throws -> Future<View> {
    let context: LoginContext
    
    if req.query[Bool.self, at: "error"] != nil {
      context = LoginContext(loginError: true)
    } else {
      context = LoginContext()
    }
    
    return try req.view().render("login", context)
  }
  
  /// Sends login request.
  ///
  /// Route at `/login`.
  func loginPostHandler(_ req: Request,
                        userData: LoginPostData) throws -> Future<Response> {
    return User.authenticate(
      username: userData.username,
      password: userData.password,
      using: BCryptDigest(),
      on: req).map(to: Response.self) { user in
        guard let user = user else {
          return req.redirect(to: "/login?error")
        }
        
        try req.authenticateSession(user)
        return req.redirect(to: "/")
    }
  }
  
  func logoutHandler(_ req: Request) throws -> Response {
    try req.unauthenticateSession(User.self)
    return req.redirect(to: "/")
  }
}

/// Context for index page.
struct IndexContext: Encodable {
  let title: String
  let questions: [Question]
  let userLoggedIn: Bool
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
}

struct EditQuestionContext: Encodable {
  let title = "Edit Question"
  let question: Question
//  let users: Future<[User]>
  let editing = true
  let categories: Future<[Category]>
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
