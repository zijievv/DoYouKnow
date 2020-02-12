//
//  WebsiteController.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import Leaf

/// Handles all website requests.
struct WebsiteController: RouteCollection {
  /// Registers routes to the incoming router.
  ///
  /// - Parameter router: To register any new routes to.
  func boot(router: Router) throws {
    router.get(use: indexHandler)
  }
  
  /// Gets rendered index page `View`.
  ///
  /// Leaf generates a page from a template called `index.leaf` inside the
  /// directory `Resources/Views`.
  func indexHandler(_ req: Request) throws -> Future<View> {
    // Renders the `index` template and returns the result.
    return try req.view().render("index")
  }
}
