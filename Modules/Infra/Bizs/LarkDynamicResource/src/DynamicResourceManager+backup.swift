//
//  DynamicResourceManager+backup.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/4/6.
//

import Foundation
import LKCommonsLogging
import LarkResource

// lint:disable lark_storage_check - 即将下线，不处理

extension String {
    public func appendingPathComponent(_ path: String) -> String {
        let fileURL = URL(fileURLWithPath: self)
        let result = fileURL.appendingPathComponent(path)

        return result.path
    }
}

extension DynamicResourceManager {
    final class Folder {
        class func channelFolderPath(accessKey: String, channel: String) -> String {
            let location = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? "/Library"
            let dataFolderName = "DynamicResource/" + accessKey + "/" + channel
            let rootPath = URL(string: location)?.appendingPathComponent(dataFolderName).path ?? "\(NSHomeDirectory())/Library/\(dataFolderName)"
            return rootPath
        }

        class func backupFolderPath(accessKey: String, channel: String, version: UInt64) -> String {
            return channelFolderPath(accessKey: accessKey, channel: channel).appending("/").appending(String(version))
        }

        class func featureConfigFilePath(path: String) -> String {
            let indexPath = ResourceManager.get(key: "Feature_Switch", type: "file") ?? "Feature_Switch.json"
            return path.appending("/\(indexPath)")
        }

        class func versionFilePath(accessKey: String, channel: String) -> String {
            let folderPath = channelFolderPath(accessKey: accessKey, channel: channel)
            return folderPath.appending("/").appending("version")
        }

        class func sizeOfFile(filePath: String) -> UInt64? {
            guard isFile(at: filePath), let fileSize = attributeOfItem(at: filePath, key: .size) as? UInt64 else { return nil }
            return fileSize
        }

        class func sizeOfDirectory(at path: String) -> UInt64? {
            guard isDirectory(at: path), let paths = fileList(at: path, recursive: true) else {
                return nil
            }
            let fullPaths = paths.map { path.appendingPathComponent($0) }
            let foldSize = fullPaths.reduce(0) { (result, path) -> UInt64 in
                return result + ((attributeOfItem(at: path, key: .size) as? UInt64) ?? 0)
            }
            return foldSize
        }

        class func fileListInDirectory(at path: String, recursive: Bool = false) -> [String]? {
            let manager = FileManager.default
            let paths = try? (recursive ? manager.subpathsOfDirectory(atPath: path) : manager.contentsOfDirectory(atPath: path))
            return paths
        }

        class func fileList(at path: String, recursive: Bool = false) -> [String]? {
            guard isExist(at: path) else {
                return nil
            }
            return fileListInDirectory(at: path, recursive: recursive)
        }

        class func isExist(at path: String) -> Bool {
            return FileManager.default.fileExists(atPath: path)
        }

        class func directory(at path: String) -> String {
            return (path as NSString).deletingLastPathComponent
        }

        class func attributesOfItem(at path: String) -> [FileAttributeKey: Any]? {
            return (try? FileManager.default.attributesOfItem(atPath: path))
        }

        class func attributeOfItem(at path: String, key: FileAttributeKey) -> Any? {
            return attributesOfItem(at: path)?[key]
        }

        class func isDirectory(at path: String) -> Bool {
            guard let fileType = attributeOfItem(at: path, key: .type) as? FileAttributeType,
                fileType == .typeDirectory else { return false }
            return true
        }

        class func isFile(at path: String) -> Bool {
            guard let fileType = attributeOfItem(at: path, key: .type) as? FileAttributeType,
                fileType == .typeRegular else { return false }
            return true
        }

        @discardableResult
        class func createFile(at path: String) -> Bool {
            return FileManager.default.createFile(atPath: path, contents: nil)
        }

        @discardableResult
        class func createDir(at path: String, attributes: [FileAttributeKey: Any]? = nil) -> Bool {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: attributes)
                return true
            } catch {
                return false
            }
        }

        @discardableResult
        class func removeItem(at path: String) -> Bool {
            do {
                try FileManager.default.removeItem(atPath: path)
                return true
            } catch {
                return false
            }
        }

        @discardableResult
        public class func copyItem(at sourcePath: String, to targetPath: String, overwrite: Bool = true) -> Bool {
            guard isExist(at: sourcePath) else {
                return false
            }

            let targetDirPath = directory(at: targetPath)
            if !isExist(at: targetDirPath), !createDir(at: targetDirPath) {
                return false
            }

            if overwrite, isExist(at: targetPath) {
                removeItem(at: targetPath)
            }

            do {
                try FileManager.default.copyItem(atPath: sourcePath, toPath: targetPath)
                return FileManager.default.contentsEqual(atPath: sourcePath, andPath: targetPath)
            } catch {
                return false
            }
        }
    }
}

extension DynamicResourceManager {
    func updateLatestVersion(for accessKey: String, channel: String, latestVersion: UInt64) {
        updateVersion(for: accessKey, channel: channel, version: latestVersion, key: "latest_version")
    }

    func updateCurrentVersion(for accessKey: String, channel: String, currentVersion: UInt64) {
        updateVersion(for: accessKey, channel: channel, version: currentVersion, key: "current_version")
    }

    func latestVersion(for accessKey: String, channel: String) -> UInt64? {
        var version: UInt64?
        if let map = readVersionInfo(for: accessKey, channel: channel) {
            if let versionString = map["latest_version"] {
                version = UInt64(versionString)
            }
        }
        return version
    }

    func currentVersion(for accessKey: String, channel: String) -> UInt64? {
        var version: UInt64?
        if let map = readVersionInfo(for: accessKey, channel: channel) {
            if let versionString = map["current_version"] {
                version = UInt64(versionString)
            }
        }
        return version
    }

    func readVersionInfo(for accessKey: String, channel: String) -> [String: String]? {
        var versionMap: [String: String]?
        let versionFilePath = DynamicResourceManager.Folder.versionFilePath(accessKey: accessKey, channel: channel)
        if DynamicResourceManager.Folder.isExist(at: versionFilePath) {
            if let dict = NSKeyedUnarchiver.unarchiveObject(withFile: versionFilePath) as? [String: String] {
                versionMap = dict
            }
        }
        return versionMap
    }

    private func updateVersion(for accessKey: String, channel: String, version: UInt64, key: String) {
        let versionFilePath = DynamicResourceManager.Folder.versionFilePath(accessKey: accessKey, channel: channel)
        var map: [String: String] = [:]
        if DynamicResourceManager.Folder.isExist(at: versionFilePath) {
            if let dict = NSKeyedUnarchiver.unarchiveObject(withFile: versionFilePath) as? [String: String] {
                map = dict
            }
        }
        map[key] = String(version)
        NSKeyedArchiver.archiveRootObject(map, toFile: versionFilePath)
    }
}
