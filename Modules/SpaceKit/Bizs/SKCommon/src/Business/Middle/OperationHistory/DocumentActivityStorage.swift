//
//  DocumentActivityStorage.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/9.
//

import Foundation
import SQLite
import SKFoundation
import RxSwift
import RxRelay

class DocumentActivityStorage {
    private static let dbName = "document-activity.sqlite"
    private let workQueue = DispatchQueue(label: "document-activity.db")
    private let userID: String
    private var database: Connection?
    private var table: DocumentActivityTable?
    let dbReadyRelay = BehaviorRelay<Bool>(value: false)

    init(userID: String) {
        self.userID = userID
        workQueue.async {
            self.setup()
        }
    }

    private func setup() {
        let dbFolderPath = SKFilePath.userSandboxWithLibrary(userID).appendingRelativePath("document-activity")
        dbFolderPath.createDirectoryIfNeeded()
        
        let dbPath = dbFolderPath.appendingRelativePath(Self.dbName)
        let (_, connection) = Connection.getEncryptDatabase(unEncryptPath: nil, encryptPath: dbPath)
        database = connection
        if connection == nil {
            DocsLogger.error("document-activity.storage --- db setup failed")
            spaceAssertionFailure()
            // 删除后重试一次
            try? dbPath.removeItem()
            let (_, connection) = Connection.getEncryptDatabase(unEncryptPath: nil, encryptPath: dbPath)
            database = connection
        }

        guard let db = database else {
            DocsLogger.error("document-activity.storage --- db setup failed")
            spaceAssertionFailure()
            return
        }
        let table = DocumentActivityTable(connection: db)
        do {
            try table.setup()
            self.table = table
            dbReadyRelay.accept(true)
        } catch {
            DocsLogger.error("document-activity.storage --- table setup failed", error: error)
            spaceAssertionFailure()
            return
        }
    }

    func getNextBatchActivities() -> BatchDocumentActivity? {
        workQueue.sync {
            table?.getNextBatchActivities(limit: 100)
        }
    }

    func save(activity: DocumentActivity) {
        workQueue.async {
            self.table?.save(activity: activity)
        }
    }

    func delete(uuids: [String]) {
        workQueue.async {
            self.table?.delete(uuids: uuids)
        }
    }
}
