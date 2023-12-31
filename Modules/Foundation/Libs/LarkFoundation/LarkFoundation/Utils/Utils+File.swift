//
//  Utils+File.swift
//  Lark
//
//  Created by lichen on 2017/11/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import Photos

public struct FileInfo {
    public var fileName: String
    public var path: String
    public var isFolder: Bool
    public var attributes: [FileAttributeKey: Any]

    public var fileSize: Int {
        if let fileSize = attributes[FileAttributeKey.size] as? Int {
            return fileSize
        }
        return 0
    }

    public var creationDate: Date {
        if let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
            return creationDate
        }
        return Date()
    }

    public var modificationDate: Date {
        if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
            return modificationDate
        }
        return Date()
    }

    public var MIMEType: String {
        return Utils.getMime(fileName: self.fileName)
    }

    /// 文件时长(单位s)，对于非视频文件,返回nil
    public var duration: TimeInterval? {
        if MIMEType.hasPrefix("video") {
            let asset = AVURLAsset(url: URL(fileURLWithPath: path))
            let time = asset.duration
            let second = ceil(Double(time.value) / Double(time.timescale))
            return second
        }
        return nil
    }
}

public extension Utils {
    class func getFileInfo(_ filePath: String) -> FileInfo? {
        var fileInfo: FileInfo?
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: transformLocalPath(filePath))
            let fileName = (filePath as NSString).lastPathComponent
            let isFolder = directoryExistsAtPath(filePath)
            fileInfo = FileInfo(fileName: fileName, path: filePath, isFolder: isFolder, attributes: attributes)
        } catch {
        }

        return fileInfo
    }

    class func getSubdirectoryFilesInfo(_ folderPath: String) -> [FileInfo]? {
        let folderPath = transformLocalPath(folderPath)
        if let subPaths = FileManager.default.subpaths(atPath: folderPath) {
            var fileInfos: [FileInfo] = []
            subPaths.forEach({ (subPath) in
                let filePath = (folderPath as NSString).appendingPathComponent(subPath)
                if let info = Utils.getFileInfo(filePath) {
                    fileInfos.append(info)
                }
            })
            return fileInfos
        }
        return nil
    }

    class func getMime(fileName: String) -> String {
        // iOS 14 以上使用新的 API
        if #available(iOS 14.0, *) {
            var start = fileName.startIndex

            if let index = fileName.lastIndex(of: "."), fileName.index(after: index) < fileName.endIndex {
                start = fileName.index(after: index)
            }

            return UTType(filenameExtension: String(fileName[start...]))?.preferredMIMEType ?? ""
        }

        let pathExtension = (fileName as NSString).pathExtension
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                          pathExtension as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        return ""
    }

    // 去掉 file://
    class func transformLocalPath(_ path: String) -> String {
        let filrPrefix = "file://"
        if !path.hasPrefix(filrPrefix) { return path }
        return String(path[path.index(path.startIndex, offsetBy: filrPrefix.count)...])
    }

    class func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
