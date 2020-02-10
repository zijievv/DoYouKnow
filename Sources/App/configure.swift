//
//  configure.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config,
                      _ env: inout Environment,
                      _ services: inout Services) throws {
  // Register providers first
  try services.register(FluentSQLiteProvider())

  // Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)

  // Register middleware
  // Create _empty_ middleware config
  var middlewares = MiddlewareConfig()
  // Serves files from `Public/` directory
  // middlewares.use(FileMiddleware.self)
  // Catches errors and converts to HTTP response
  middlewares.use(ErrorMiddleware.self)
  services.register(middlewares)

  // Configure a SQLite database
  let sqlite = try SQLiteDatabase(storage: .memory)

  // Register the configured SQLite database to the database config.
  var databases = DatabasesConfig()
  databases.add(database: sqlite, as: .sqlite)
  services.register(databases)

  // Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: Question.self, database: .sqlite)
  services.register(migrations)
}
