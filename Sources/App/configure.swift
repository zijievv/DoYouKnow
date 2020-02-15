//
//  configure.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import FluentMySQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config,
                      _ env: inout Environment,
                      _ services: inout Services) throws {
  // Register providers first
  try services.register(FluentMySQLProvider())
  try services.register(LeafProvider())
  try services.register(AuthenticationProvider())

  // Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)

  // Register middleware
  // Create _empty_ middleware config
  var middlewares = MiddlewareConfig()
  // Serves files from `Public/` directory
  middlewares.use(FileMiddleware.self)
  // Catches errors and converts to HTTP response
  middlewares.use(ErrorMiddleware.self)
  services.register(middlewares)

  // Register the configured SQLite database to the database config.
  var databases = DatabasesConfig()
  let databaseName: String
  let databasePort: Int
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
  //
  //
  // IF TEST:
  // mysql/mysql-server:5.7
  // docker container run \
  // -d \
  // --name mysql-test \
  // --env MYSQL_ROOT_PASSWORD=rootpassword \
  // --env MYSQL_USER=vapor \
  // --env MYSQL_PASSWORD=password \
  // --env MYSQL_DATABASE=vapor-test \
  // -p 3307:3306 \
  // mysql/mysql-server:5.7
  if (env == .testing) {
    databaseName = "vapor-test"
    databasePort = 3307
  } else {
    databaseName = "vapor"
    databasePort = 3306
  }
  
  let databaseConfig = MySQLDatabaseConfig(hostname: "localhost",
                                           port: databasePort,
                                           username: "vapor",
                                           password: "password",
                                           database: databaseName)
  let database = MySQLDatabase(config: databaseConfig)
  databases.add(database: database, as: .mysql)
  services.register(databases)

  // Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: User.self, database: .mysql)
  migrations.add(model: Question.self, database: .mysql)
  migrations.add(model: Answer.self, database: .mysql)
  migrations.add(model: Category.self, database: .mysql)
  migrations.add(model: QuestionCategoryPivot.self, database: .mysql)
  services.register(migrations)
  
  // Adds the Fluent commands to application, which allows you to manually
  // run migrations. It also allows to revert migrations.
  var commandConfig = CommandConfig.default()
  commandConfig.useFluentCommands()
  services.register(commandConfig)
  
  // Tells Vapor to use `LeafRenderer` when asked for a `ViewRenderer` type.
  config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
