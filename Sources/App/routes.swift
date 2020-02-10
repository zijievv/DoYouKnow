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
  router.get { req in
      return "It works!"
  }
  
  // Basic "Hello, world!" example
  router.get("hello") { req in
      return "Hello, world!"
  }

  let questionsController = QuestionsController()
  try router.register(collection: questionsController)
//  // Example of configuring a controller
//  let todoController = TodoController()
//  router.get("todos", use: todoController.index)
//  router.post("todos", use: todoController.create)
//  router.delete("todos", Todo.parameter, use: todoController.delete)
}
