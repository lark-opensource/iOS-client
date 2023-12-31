//  Created by weidong fu on 29/11/2017.

import Foundation
import SQLite
import SKFoundation
import SKCommon
import LarkStorage

extension Connection {
    public final class Docs: DocsDBConnectionProvidor {
        private let dbDirectory = "docsDB"
        // 加密前的数据库
        private let unEncryptdbName = "docs.sqltie3"
        // 加密成功后的数据库，如果这个文件存在，那么会删掉unEncryptdbName明文数据库
        private let encryptdbName = "encryptDocs.sqltie3"

        public private(set) var file: Connection?
        private var currentUserIdStr: String {
            return User.current.info?.userID ?? "unknown"
        }

        private func sqlRootPath(userID: String) -> SKFilePath {
            // Library + DocsSDK + UserID + dbDirectory
            let path = SKFilePath.userSandboxWithLibrary(userID).appendingRelativePath(dbDirectory)
            do {
                try path.createDirectoryIfNeeded(withIntermediateDirectories: true)
            } catch {
                DocsLogger.error("db create file error", extraInfo: nil, error: error, component: nil)
            }
            return path
        }

        private func moveLegacyDBFolderIfNeeded(_ userID: String) {
            let oldDBPath = SKFilePath.globalSandboxWithLibrary.appendingRelativePath(dbDirectory)
            let newDBPath = SKFilePath.userSandboxWithLibrary(userID).appendingRelativePath(dbDirectory)
            if oldDBPath.exists {
                do {
                    try oldDBPath.moveItem(to: newDBPath)
                } catch {
                    DocsLogger.error("move old db path file failed", error: error)
                }
            }
        }


        private func setupNewDbConnection(_ userID: String) -> Connection? {
            let sqlRootPath = self.sqlRootPath(userID: userID)
            let unEncryptPath = sqlRootPath.appendingRelativePath(unEncryptdbName)
            let encryptPath = sqlRootPath.appendingRelativePath(encryptdbName)
            let (_, connection) = Connection.getEncryptDatabase(unEncryptPath: unEncryptPath, encryptPath: encryptPath, fromsource: .fileList)
            return connection
        }

        public func setup(userID: String) -> Bool {
            moveLegacyDBFolderIfNeeded(userID)
            file = setupNewDbConnection(userID)
            if let db = file {
                _ = NewFileDBMigrationManager(db: db)
                DocsLogger.info("setup ok", component: LogComponents.db)
                return true
            } else {
                DocsLogger.error("file is nil", component: LogComponents.db)
                return false
            }
        }

        public func reset() {
            DocsLogger.info("reset db", component: LogComponents.db)
            file = nil
        }
    }
    public static let docs = Docs()
}

public protocol DocsDBConnectionProvidor: AnyObject {
    var file: Connection? { get }

    func setup(userID: String) -> Bool

    func reset()
}
