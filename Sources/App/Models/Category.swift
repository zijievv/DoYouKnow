//
//  Category.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import Vapor
import FluentMySQL

final class Category: Codable {
  var id: Int?
  var name: String
  
  init(name: String) {
    self.name = name
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
