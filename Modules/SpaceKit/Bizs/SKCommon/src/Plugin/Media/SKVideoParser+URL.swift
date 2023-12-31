//
//  SKVideoParser+URL.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/11/26.
//

import SKFoundation
import RxSwift
import AVFoundation
import Photos

extension SKVideoParser {

    func parserVideo(with url: URL) -> Observable<Info> {
        return baseVideoInfo(with: url).flatMap { [weak self] (info) -> Observable<Info> in
            guard let self = self else { return .empty() }

            if info.filesize <= self.fileMaxSize, let exportPath = info.exportPath {
                info.status = .fillBaseInfo
                if let error = self.loadVideoData(at: url, to: exportPath) {
                    return .error(error)
                }
            } else {
                info.status = .reachMaxSize
                DocsLogger.error("视频过大，filesize=\(info.filesize),duration=\(info.duration) ", component: LogComponents.pickFile)
            }
            return .just(info)
        }
    }

    func baseVideoInfo(with videoURL: URL) -> Observable<Info> {
        guard let fileSize = checkFileExistsAndGetFileSize(at: videoURL) else {
            DocsLogger.error("读取视频文件失败", component: LogComponents.pickFile)
            return .error(PError.getVideoSizeError)
        }
        let fileName = videoURL.lastPathComponent
        let pathExtention = (fileName as NSString).pathExtension

        let uuid = UUID().uuidString
        let cachePath = SKPickContentType.getUploadCacheUrl(uuid: uuid, pathExtension: pathExtention)
        guard !cachePath.pathString.isEmpty else {
            DocsLogger.error("创建缓存目录失败", component: LogComponents.pickFile)
            return .error(PError.createSandboxPathError)
        }

        let avasset = AVURLAsset(url: videoURL)
        let time = avasset.duration
        let seconds = ceil(Double(time.value) / Double(time.timescale))

        let info = Info()
        let size = SKPickImageUtil.resolutionSizeForLocalVideo(url: videoURL)
        info.width = size.width
        info.height = size.height
        info.name = fileName
        info.filesize = fileSize
        info.duration = seconds
        info.uuid = uuid
        info.docSourcePath = SKPickContentType.cacheUrlPrefix + "\(uuid).\(pathExtention)"
        info.exportPath = cachePath
        info.status = .fillBaseInfo

        return .just(info)
    }

    func checkFileExistsAndGetFileSize(at url: URL) -> UInt64? {
        let path = SKFilePath(absUrl: url)
        if path.exists, !path.isDirectory {
            if let fileSize = path.fileSize {
                return fileSize
            } else {
                DocsLogger.error("URL: get video file size error", component: LogComponents.pickFile)
            }
        }
        DocsLogger.error("URL: get video file size error")
        return nil
    }

    func loadVideoData(at url: URL, to targetPath: SKFilePath) -> Error? {
        do {
            try targetPath.moveItemFromUrl(from: url)
        } catch {
            DocsLogger.error("URL: move video fail", error: error, component: LogComponents.pickFile)
            do {
                try targetPath.copyItemFromUrl(from: url)
            } catch {
                DocsLogger.error("URL: copy video fail", error: error, component: LogComponents.pickFile)
                return error
            }
        }
        return nil
    }
}
