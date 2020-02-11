//
//  CategoriesController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor

struct CategoriesController: RouteCollection {
  func boot(router: Router) throws {
    let categoriesRoute = router.grouped("api", "categories")
    
    categoriesRoute.get(use: getAllHandler)
    categoriesRoute.get(Category.parameter, use: getHandler)
    categoriesRoute.get(Category.parameter, "questions",
                        use: getQuestionsHandler)
    categoriesRoute.post(Category.self, use: createHandler)
  }
  
  // MARK: GET requests.
  /// Gets all categories.
  ///
  /// Route at `/api/categories/`.
  func getAllHandler(_ req: Request) throws -> Future<[Category]> {
    return Category.query(on: req).all()
  }
  
  /// Gets a categories with specified category ID.
  ///
  /// Route at `/api/categories/<category ID>`.
  func getHandler(_ req: Request) throws -> Future<Category> {
    return try req.parameters.next(Category.self)
  }
  
  /// Gets the questions tagged by the category.
  ///
  /// Route at `/api/categories/<category ID>/questions/`.
  func getQuestionsHandler(_ req: Request) throws -> Future<[Question]> {
    return try req.parameters.next(Category.self)
      .flatMap(to: [Question].self) { category in
        try category.questions.query(on: req).all()
    }
  }
  
  // MARK: POST & PUT & DELETE requests.
  /// Creates a new category.
  ///
  /// Route at `/api/categories/`. It returns the category once it's saved.
  func createHandler(_ req: Request,
                     category: Category) throws -> Future<Category> {
    return category.save(on: req)
  }
}
