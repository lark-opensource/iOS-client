//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
// lint:disable lark_storage_check
enum FileStorageType: CaseIterable {
    case Tmp
    case Cache
    case Document

    var webRootPath: String {
        let rootPath = "LarkWebFileStorege"
        var result = (NSTemporaryDirectory() as NSString).appendingPathComponent(rootPath)
        switch self {
        case .Cache:
            let libraryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            result = (libraryPath[0] as NSString).appendingPathComponent(rootPath)
        case .Document:
            let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            result = (docPath[0] as NSString).appendingPathComponent(rootPath)
        case .Tmp:
            let tmpPath = NSTemporaryDirectory()
            result = (tmpPath as NSString).appendingPathComponent(rootPath)
        }
        return result
    }

    var webRootTemplatePath: String {
        var result = "larkwebfile://"
        switch self {
        case .Cache:
            result += "c:"
        case .Document:
            result += "d:"
        case .Tmp:
            result += "t:"
        }
        return result
    }
 }

class LarkWebFileManager {
    static func pathForHttpResp(
        url: URL,
        fileName: String,
        storageType: FileStorageType
        ) -> String {
        let fm = FileManager.default
        let root = storageType.webRootPath
        if !fm.fileExists(atPath: storageType.webRootPath) {
            do {
                try fm.createDirectory(atPath: root, withIntermediateDirectories: true, attributes: nil)
            } catch {

            }
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let fileName = (url.absoluteString + String(now)).md5() + "_" + fileName
        return (root as NSString).appendingPathComponent(fileName)
    }

    static func toTemplatePath(absolutePath: String) -> String? {
        for ca in FileStorageType.allCases {
            let prefix = ca.webRootPath + "/"
            if absolutePath.hasPrefix(prefix) {
                return absolutePath.replacingOccurrences(of: prefix, with: (ca.webRootTemplatePath))
            }
        }
        return nil
    }

    static func toAbsolutePath(templatePath: String) -> String? {
        for ca in FileStorageType.allCases {
            let prefix = ca.webRootTemplatePath
            if templatePath.hasPrefix(prefix) {
                return templatePath.replacingOccurrences(of: prefix, with: (ca.webRootPath + "/"))
            }
        }
        return nil
    }

    static func getOriginFileName(absolutePath: String) -> String {
        let last = (absolutePath as NSString).lastPathComponent
        if let range = last.range(of: "_") {
            return String(last[range.upperBound...])
        }

        if !last.isEmpty {
            return last
        }
        return absolutePath
    }

    static func pathValid(templatePath: String, storageType: FileStorageType = .Tmp) -> Bool {
        return (templatePath as NSString).standardizingPath.hasPrefix(storageType.webRootPath)
    }
    /*
    static func folderSize(folderPath: String) -> UInt{

        var fileSize: UInt = 0
        if let filesArray:[String] = FileManager.default.subpaths(atPath: folderPath) {
            for fileName in filesArray{
                let filePath = (folderPath as NSString).appendingPathComponent(fileName)
                fileSize += UInt(self.fileSize(filePath: filePath))
            }
        }
        return fileSize
    }

    static func fileSize(filePath: String) -> UInt64 {

        var fileSize: UInt64 = 0
        do {
            //return [FileAttributeKey : Any]
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = (attr[FileAttributeKey.size] as? UInt64) ?? 0

        } catch {

        }

        return fileSize
    }
 */
}
// lint:enable lark_storage_check
