//
//  SKFileParser+URL.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/12/4.
//

import SKFoundation
import RxSwift
import AVFoundation
import Photos
import LarkDocsIcon

extension SKFileParser {

    public func parserFile(with url: URL) -> Observable<Info> {
        return baseFileInfo(with: url).flatMap { [weak self] (info) -> Observable<Info> in
            guard let self = self else { return .empty() }

            if info.filesize <= self.fileMaxSize {
                info.status = .fillBaseInfo
                if let error = self.loadFileData(at: url, to: info.exportPath) {
                    return .error(error)
                }
            } else {
                info.status = .reachMaxSize
                DocsLogger.error("文件过大，filesize=\(info.filesize)", component: LogComponents.pickFile)
            }
            return .just(info)
        }
    }

    func baseFileInfo(with fileURL: URL) -> Observable<Info> {
        let absPath = SKFilePath(absUrl: fileURL)
        guard absPath.isFile() else {
            DocsLogger.error("不是文件", component: LogComponents.pickFile)
            return .error(PError.notFileError)
        }
        guard let fileSize = absPath.sizeExt() else {
            DocsLogger.error("获取大小失败", component: LogComponents.pickFile)
            return .error(PError.getFileSizeError)
        }

        let fileName = fileURL.lastPathComponent
        let pathExtention = (fileName as NSString).pathExtension

        let uuid = UUID().uuidString
        let cachePath = SKPickContentType.getUploadCacheUrl(uuid: uuid, pathExtension: pathExtention)
        guard !cachePath.pathString.isEmpty else {
            DocsLogger.error("创建缓存目录失败", component: LogComponents.pickFile)
            return .error(PError.createSandboxPathError)
        }

        let info = SKFileParser.Info()
        info.name = fileName
        info.filesize = fileSize
        info.uuid = uuid
        info.exportPath = cachePath
        info.docSourcePath = SKPickContentType.cacheUrlPrefix + "\(uuid).\(pathExtention)"
        info.status = .fillBaseInfo
        if DriveFileType(fileExtension: pathExtention).isMedia {
            let size = SKPickImageUtil.resolutionSizeForLocalVideo(url: fileURL)
            info.width = size.width
            info.height = size.height
            info.fileType = "video"
        }
        return .just(info)
    }

    func loadFileData(at url: URL, to targetURL: SKFilePath?) -> Error? {
        guard let targetPath = targetURL else {
            DocsLogger.error("URL: move File fail targetURL nil", component: LogComponents.pickFile)
            return nil
        }
        do {
            try targetPath.moveItemFromUrl(from: url)
        } catch {
            DocsLogger.error("URL: move File fail", error: error, component: LogComponents.pickFile)
            do {
                try targetPath.copyItemFromUrl(from: url)
            } catch {
                DocsLogger.error("URL: copy File fail", error: error, component: LogComponents.pickFile)
                return error
            }
        }
        return nil
    }
}
