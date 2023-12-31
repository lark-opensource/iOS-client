//
//  LarkOPFileCacheManager.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/9/19.
//

import Foundation
import Swinject
import LarkStorage
import LarkAccountInterface
import LarkSetting
import LKCommonsLogging
import LarkContainer
import OPFoundation

class LarkOPFileCacheManager {
    private let maxCacheCount: Int
    var filePath: String
    static let LarkOPBaseDirct = "LarkOpenPlatform"
    static let logger = Logger.oplog(LarkOPFileCacheManager.self, category: "FileCacheManager")

    init(maxCacheCount: Int = 40, filePath: String?) {
        self.maxCacheCount = maxCacheCount
        if let path = filePath {
            self.filePath = path
        } else {
            self.filePath = AbsPath.cache.absoluteString
            self.filePath.append(LarkOPFileCacheManager.LarkOPBaseDirct)
        }
    }

    func writeToFile(fileName: String, data: String) {
        guard !fileName.isEmpty else { return }
        removeLastFileIfNeeded()
        LarkOPFileCacheManager.writeToFile(filePath: "\(filePath)/\(fileName)", data: data)
    }
    
    func readFromFile(fileName: String) -> String? {
        guard !fileName.isEmpty else { return nil }
        return LarkOPFileCacheManager.readFromFile(filePath: "\(filePath)/\(fileName)")
    }

    private func removeLastFileIfNeeded() {
        guard LarkOPFileCacheManager.isFileExist(filePath: filePath) else { return }
        let subFiles = try? LSFileSystem.contentsOfDirectory(dirPath: filePath)
        guard let files = subFiles, files.count >= maxCacheCount else { return }
        try? LSFileSystem.openBusiness.removeItem(atPath: "\(filePath)/\(files.first!)")
    }

    static func isFileExist(filePath: String) -> Bool {
        guard !filePath.isEmpty else { return false }
        return LSFileSystem.fileExists(filePath: filePath)
    }
    
    func createDirectoryIfNeeded() {
        if !LarkOPFileCacheManager.isFileExist(filePath: filePath) {
            LarkOPFileCacheManager.createDirectory(directoryPath: filePath)
        }
    }

    static func createDirectory(directoryPath: String) {
        guard !directoryPath.isEmpty else { return }
        try? LSFileSystem.openBusiness.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }

    static func writeToFile(filePath: String, data: String) {

        guard !filePath.isEmpty else { return }
        if !isFileExist(filePath: filePath) {
            createFile(filePath: filePath)
        }
        let realData = data.data(using: String.Encoding.utf8)
        if let realData = realData {
            try? LSFileSystem.openBusiness.write(data: realData, to: filePath)
        }
    }
    
    static func createFile(filePath: String) {
        guard !filePath.isEmpty, !isFileExist(filePath: filePath) else { return }
        LSFileSystem.openBusiness.createFile(atPath: filePath, contents: nil)
    }
    
    static func readFromFile(filePath: String) -> String? {
        guard !filePath.isEmpty else { return nil }
        return try? LSFileSystem.openBusiness.readString(from: filePath)
    }
}
