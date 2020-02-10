//
//  configure.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config,
                      _ env: inout Environment,
                      _ services: inout Services) throws {
  // Register providers first
  try services.register(FluentMySQLProvider())

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

  // Register the configured SQLite database to the database config.
  var databases = DatabasesConfig()
  // Set up a MySQL database configuration using the same values supplied
  // to Docker.
  //
  // Info about MySQL in Docker:
  // docker container run \
  // -d \
  // --name mysql \
  // --env MYSQL_ROOT_PASSWORD=rootpassword \
  // --env MYSQL_USER=vapor \
  // --env MYSQL_PASSWORD=password \
  // --env MYSQL_DATABASE=vapor \
  // -p 3306:3306 \
  // mysql/mysql-server:5.7
  let databaseConfig = MySQLDatabaseConfig(hostname: "localhost",
                                           port: 3306,
                                           username: "vapor",
                                           password: "password",
                                           database: "vapor")
  let database = MySQLDatabase(config: databaseConfig)
  databases.add(database: database, as: .mysql)
  services.register(databases)

  // Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: Question.self, database: .mysql)
  services.register(migrations)
}
