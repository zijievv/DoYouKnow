//
//  routes.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  // Basic "It works" example
  router.get("api") { req in
      return "It works!"
  }
  
  // Basic "Hello, world!" example
  router.get("api", "hello") { req in
      return "Hello, world!"
  }

  let questionsController = QuestionsController()
  try router.register(collection: questionsController)
  
  let usersController = UsersController()
  try router.register(collection: usersController)
  
  let categoriesController = CategoriesController()
  try router.register(collection: categoriesController)
  
  let answerController = AnswersController()
  try router.register(collection: answerController)
  
  let websiteController = WebsiteController()
  try router.register(collection: websiteController)
}
