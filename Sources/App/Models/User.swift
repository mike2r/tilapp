//
//  User.swift
//  App
//
//  Created by Mike Ruch on 12.18.18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String
    
    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Parameter {}

extension User.Public: Content {}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
}

extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) {builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        let user = User(name: "Admin", username: "admin", password: hashedPassword)
        return user.save(on: connection).transform(to: ())
    }
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}



// struct AddUserPassword: Migration {
//    typealias Database = PostgreSQLDatabase
//    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.update(User.self, on: connection) { builder in
//            let defaultValueConstraint = PostgreSQLColumnConstraint.default(.literal("password"))
//            builder.field(for: \.password, type: .text, defaultValueConstraint)
//        }
//    }
//    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.update(User.self, on: connection) { builder in
//            builder.deleteField(for: \.password)
//        }
//    }
//}
