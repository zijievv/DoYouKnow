//
//  UserTests.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

@testable import App
import Vapor
import XCTest
import FluentMySQL

final class UserTests: XCTestCase {
  let usersName = "Anna"
  let usersUsername = "u_anna"
  let usersURI = "/api/users/"
  var app: Application!
  var conn: MySQLConnection!
  
  override func setUp() {
    try! Application.reset()
    app = try! Application.testable()
    conn = try! app.newConnection(to: .mysql).wait()
  }
  
  override func tearDown() {
    conn.close()
    try? app.syncShutdownGracefully()
  }
  
  func testUsersCanBeRetrievedFromAPI() throws {
    let user = try User.create(name: usersName,
                               username: usersUsername,
                               on: conn)
    _ = try User.create(on: conn)
    
    let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
    
    print("""
    //////////////////
    user 0
      name: \(users[0].name)
      username: \(users[0].username)
      
    user 1
      name: \(users[1].name)
      username: \(users[1].username)
    //////////////////
    """)
    
    XCTAssertEqual(users.count, 2)
    XCTAssertEqual(users[1].name, usersName)
    XCTAssertEqual(users[1].username, usersUsername)
    XCTAssertEqual(users[1].id, user.id)
    
    conn.close()
  }
}
