//
//  SendAttachedFileDataCenter.swift
//  Lark
//
//  Created by ChalrieSu on 18/12/2017.
//  Copyright © 2017 Bytedance.Inc. All rights reserved.
//
//  用于从document/dowloads目录下以及从相册中读取文件，并展示在发送附件列表中

import Foundation
import Photos
import LarkFoundation
import LarkSDKInterface
import LarkMessengerInterface

struct LocalFileFetchServiceImpl: LocalFileFetchService {
    let userID: String

    func fetchAttachedFilesFromDownloadDirectory(and extraPaths: [URL]) -> [AttachedFile] {
        SendAttachedFileDataCenter.fetchAttachedFilesFromDownloadDirectory(userID: userID, and: extraPaths)
    }
}

final class SendAttachedFileDataCenter {

    class func fetchAttachedFilesFromDownloadDirectory(userID: String, and extraPaths: [URL]) -> [AttachedFile] {
        var paths: [URL] = []
        let downloadPath = URL(fileURLWithPath: fileDownloadCache(userID).rootPath)

        paths.append(downloadPath)

        // 允许搜寻指定目录
        paths.append(contentsOf: extraPaths)
        return SendAttachedFileDataCenter.fetchAttachedFilesFromSandBox(directorys: paths)
    }

    class func fetchAttachedFilesFromSandBox(directorys: [URL]?) -> [AttachedFile] {
        guard let directorys = directorys else { return [] }

        var fileInfos: [FileInfo] = []
        directorys.forEach { (path) in
            fileInfos.append(contentsOf: (Utils.getSubdirectoryFilesInfo(path.path) ?? []))
        }

        // 因为扩展成能读取多个路径下，所以可能存在同名情况。如果重名需要加标识。
        var nameCountMap: [String: Int] = [:]
        func createFileName(_ fileName: String) -> String {
            if let current = nameCountMap[fileName] {
                nameCountMap[fileName] = current + 1
                let array = fileName.split(separator: ".")
                var name = fileName
                if array.count > 1 {
                    name = "\(array[0])(\(current + 1)).\(array[1])"
                }
                return name
            }
            nameCountMap[fileName] = 0
            return fileName
        }

        return fileInfos
            .compactMap { (fileInfo) -> LocalFile? in
                guard !fileInfo.isFolder,
                    fileInfo.fileName != ".DS_Store",
                    !fileInfo.fileName.hasSuffix(".larkcache"),
                    !fileInfo.path.contains("/temp/"),
                    !fileInfo.path.contains("/CacheDB/")
                    else { return nil }
                return LocalFile(type: fileTypeFromPath(fileInfo.path),
                                 filePath: fileInfo.path,
                                 name: createFileName(fileInfo.fileName),
                                 size: Int64(fileInfo.fileSize),
                                 createDate: fileInfo.creationDate,
                                 videoDuration: fileInfo.duration)
            }
            .sorted { $0.createDate > $1.createDate }
            .map { $0 as AttachedFile }
    }

    /// 从沙盒中获取文件
    class func fetchFilesFromSandBox(directorys: [URL]?) -> [AggregateAttachedFiles] {
        self.fetchAttachedFilesFromSandBox(directorys: directorys)
            .aggregateAttachedFiles
            .sorted { $0.type.rawValue < $1.type.rawValue }
    }

    class func fileTypeFromPath(_ path: String?) -> AttachedFileType {
        guard let path = path else {
            return .unkown
        }

        let fileFormat = path.lf.fileFormat()
        switch fileFormat {
        case .video:
            return .localVideo
        case .pdf:
            return .PDF
        case .office(.xls):
            return .EXCEL
        case .office(.doc):
            return .WORD
        case .office(.ppt):
            return .PPT
        case .txt:
            return .TXT
        case .md:
            return .MD
        case .json:
            return .JSON
        case .html:
            return .HTML
        default:
            return .unkown
        }
    }
}
