//
//  Database.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/23.
//

import Foundation
import SQLite
import LKCommonsLogging
import LarkSecurityComplianceInfra

final class Database {

    static let logger = Logger.log(Database.self, category: "SecurityAudit.Database")
    static let shared: Database = Database()

    let serialQueue = DispatchQueue(label: "security.audit.db", qos: .background)
    
    private lazy var dbPath: String? = {
        let libraryDirectory = SCSandBox.globalSandboxWithLibrary(business: .securityAudit)
        do {
            try libraryDirectory.createDirectoryIfNeeded(withIntermediateDirectories: true)
        } catch {
            Self.logger.error("create db dir failed with dir:\(libraryDirectory)", error: error)
            return nil
        }
        return libraryDirectory.appendingRelativePath(Const.dbFileName).pathString
    }()

    lazy var db: Connection? = {
        guard let path = dbPath else {
            return nil
        }
        do {
            let conn = try Connection(path)
            return conn
        } catch {
            Self.logger.error("connect sql db failed with path:\(path)", error: error)
            return nil
        }
    }()

    lazy var aduitLogTable: AuditLogTable = {
        return AuditLogTable(db: db)
    }()

    init() {}

}
