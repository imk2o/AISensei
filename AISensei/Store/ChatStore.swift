//
//  ChatStore.swift
//  AISensei
//
//  Created by k2o on 2023/04/08.
//

import Foundation
import GRDB

final class ChatStore {
    static let shared = ChatStore(
//        path: FileManager.default.applicationSupportFileURL(path: "chat.sqlite").path(percentEncoded: false)
        path: FileManager.default.documentFileURL(path: "chat.sqlite").path(percentEncoded: false)
    )
    
    private init(path: String) {
        self.database = {
            let database = try! DatabaseQueue(path: path)
            let migrator = Self.databaseMigrator()
            try! migrator.migrate(database)
            return database
        }()
    }

    func allSessions() async throws -> [ChatSessionRecord] {
        return try await database.read { db in
            try ChatSessionRecord
                .all()
                .orderByPrimaryKey()
                .fetchAll(db)
        }
    }

    func session(for id: ChatSessionRecord.ID) async throws -> ChatSessionRecord? {
        return try await database.read { db in
            try ChatSessionRecord.fetchOne(db, id: id)
        }
    }
    
    func createSession(_ session: ChatSessionRecord) async throws -> ChatSessionRecord {
        return try await database.write { db in
            try session.inserted(db)
        }
    }

    func updateSession(_ session: ChatSessionRecord) async throws {
        return try await database.write { db in
            try session.update(db)
        }
    }

    func deleteSession(id: ChatSessionRecord.ID) async throws {
        return try await database.write { db in
            try ChatSessionRecord.deleteOne(db, id: id)
        }
    }
    func insertMessage(_ message: ChatMessageRecord) async throws -> ChatMessageRecord {
        return try await database.write { db in
            try message.inserted(db)
        }
    }

    func messages(for sessionID: ChatSessionRecord.ID) async throws -> [ChatMessageRecord] {
        return try await database.read { db in
            try ChatMessageRecord
                .filter(Column(ChatMessageRecord.CodingKeys.sessionID) == sessionID)
                .orderByPrimaryKey()
                .fetchAll(db)
        }
    }
    
    // MARK: - private
    
    private let database: DatabaseQueue
    
    private static func databaseMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try ChatSessionRecord.migrateV1(with: db)
            try ChatMessageRecord.migrateV1(with: db)
        }

        return migrator
    }
}

// MARK: -

extension ChatSessionRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName = "session"
    
    static func migrateV1(with db: Database) throws {
        try db.create(table: databaseTableName) { table in
            table.autoIncrementedPrimaryKey("id")
            table.column("title", .text)
                .indexed()
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

import GRDB
extension ChatMessageRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName = "message"
    
    static func migrateV1(with db: Database) throws {
        try db.create(table: databaseTableName) { table in
            table.autoIncrementedPrimaryKey("id")
            table.column("role", .text)
            table.column("content", .text)
                .indexed()
            table.column("session_id", .integer)
                .notNull()
                .indexed()
                .references(ChatSessionRecord.databaseTableName, onDelete: .cascade)
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
