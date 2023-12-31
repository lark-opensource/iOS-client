//
//  ExtensionLogCleaner.swift
//  LarkExtensionAssembly
//
//  Created by 王元洵 on 2021/3/25.
//

import Foundation
import LKCommonsLogging
import LarkExtensionServices
import LarkStorage

enum ExtensionLogCleaner {
    private static let fileMaxCacheCount = 5
    private static let logger = Logger.log(ExtensionLogCleaner.self, category: "module.extension.log.clean")

    /// extension 日志路径
    private static var extensionLogPath: IsoPath? = LarkExtensionServices.logBasePath()

    /// 主 App 的日志路径
    private static var mainAppLogPath: IsoPath? {
        guard let ret = try? IsoPath.rustSdk(relativePart: "log/extension") else {
            return nil
        }
        do {
            try ret.createDirectoryIfNeeded()
        } catch {
            logger.error("failed crated log dir for extension", error: error)
        }
        return ret
    }

    static func moveAndClean() {
        guard
            let extensionlogPath = self.extensionLogPath,
            let mainAppLogPath = self.mainAppLogPath,
            extensionlogPath.exists
        else {
            return
        }

        // 将「extension」所有日志移动到「主 App」目录下
        do {
            try extensionlogPath.contentsOfDirectory_().forEach {
                let source = extensionlogPath + $0
                let destination = mainAppLogPath + $0

                if destination.exists { try destination.removeItem() }
                try destination.copyItem(from: source.asAbsPath())
            }
            Self.logger.info("move extension succeed")
        } catch {
            Self.logger.error("move extension log failed", error: error)
        }

        // 删除extension下的日志，仅保留最后一个
        cleanOldFiles(logDir: extensionlogPath, fileMaxCacheCount: 2)

        // 删除主App下较早的extension日志
        cleanOldFiles(logDir: mainAppLogPath, fileMaxCacheCount: Self.fileMaxCacheCount)
    }

    private static func cleanOldFiles(logDir: IsoPath, fileMaxCacheCount: Int) {
        do {
            let entries = try logDir.childrenOfDirectory(recursive: false)

            if entries.count > fileMaxCacheCount {
                var cleanFiles = entries.sorted() { firstPath, secondaryPath in
                    if let firstDate = try? firstPath.attributesOfItem()[.creationDate] as? Date,
                       let secondaryDate = try? secondaryPath.attributesOfItem()[.creationDate] as? Date {
                        return firstDate.compare(secondaryDate) == .orderedAscending
                    }
                    return true
                }

                cleanFiles.removeSubrange((entries.count - fileMaxCacheCount)..<entries.count)
                try cleanFiles.forEach { try $0.removeItem() }
            }
        } catch {
            Self.logger.error("clear failed: \(logDir.absoluteString)", error: error)
        }
    }
}
