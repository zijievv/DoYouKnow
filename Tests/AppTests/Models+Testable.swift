//
//  Models+Testable.swift
//  DoYouKnow
//
//  Created by Zijie Wang
//  Copyright © 2020 Zijie Wang. All rights reserved.
//

import FluentMySQL
@testable import App

extension User {
    static func create(name: String = "Lisa",
                       username: String = "u_lisa",
                       on connection: MySQLConnection) throws -> User {
        let user = User(name: name, username: username)
        return try user.save(on: connection).wait()
    }
}
