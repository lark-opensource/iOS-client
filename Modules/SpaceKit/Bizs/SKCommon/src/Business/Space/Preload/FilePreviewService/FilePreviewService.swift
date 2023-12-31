//
//  FilePreviewService.swift
//  SpaceKit
//
//  Created by bytedance on 2018/9/29.
//

import Foundation
import SKFoundation

public protocol FilePreviewServiceProtocol: AnyObject {
    func download(progress: Float)
    func didFinishDownloadingTo(location: SKFilePath)
}

public final class FilePreviewService: NSObject {

    // 本地 Document 路径 + "缓存目录"
    static let localFileDir = SKFilePath.globalSandboxWithCache.appendingRelativePath("preview_file_cache")

    public weak var delegate: FilePreviewServiceProtocol?
    private var file: FilePreviewModel
    private var downloadRequest: DocsDownloadRequest?

    typealias FilePerviewHandler = (_ filePath: SKFilePath?, _ error: NSError?) -> Void
    private var filePreviewHandler: FilePerviewHandler

    init(file: FilePreviewModel, delegate: FilePreviewServiceProtocol, completionHandler: @escaping FilePerviewHandler) {
        self.file = file
        self.delegate = delegate
        self.filePreviewHandler = completionHandler
        super.init()

        createCacheDirIfNeeded()
    }

    // 开始下载
    func start() {
        donwloadFileIfNeeded(file)
    }

    // 停止下载
    func stopDownload() {
        downloadRequest?.cancel()
    }

    // 检查本地是否已经存在文件
    public static func checkIfLocalFileExisted(file: FilePreviewModel) -> Bool {
        DocsLogger.debug("文件路径: \(FilePreviewService.localFileDir)")
        if getLocalFilePath(file: file) != nil {
            return true
        }

        return false
    }

    // 获取本地文件路径
    public static func getLocalFilePath(file: FilePreviewModel) -> SKFilePath? {
        let filePath = FilePreviewService.localFileDir.appendingRelativePath(file.cacheName)
        guard filePath.exists else {
            DocsLogger.info("找不到缓存文件")
            return nil
        }
        return filePath
    }

    // 清理缓存目录
    // 超过 500MB，删除最新 10 篇
    public static func cleanCacheIfNeeded() {
        let path = FilePreviewService.localFileDir
        let maxSize = 500 * 1024 * 1024
        guard path.exists else {
            DocsLogger.info("文件不存在，不处理缓存文件")
            return
        }

        var tmpFiles: [(SKFilePath, Double)] = []
        do {
            let files = try path.contentsOfDirectory()
            var totalSize: UInt64 = 0
            // 遍历目录获取（创建日志，文件大小）
            for file in files {
                let filePath = path.appendingRelativePath(file)
                let fileAttrs = filePath.fileAttribites
                guard let creationDate = fileAttrs[FileAttributeKey.creationDate] as? NSDate,
                      let fileSize = fileAttrs[FileAttributeKey.size] as? NSNumber else {
                    continue
                }
                totalSize += fileSize.uint64Value
                tmpFiles.append((filePath, creationDate.timeIntervalSince1970))
            }

            // 获取目录大小
            // 小于 500MB 不处理
            if totalSize <= maxSize {
                DocsLogger.info("小于 500 MB，不处理缓存文件 \(totalSize)")
                return
            }

            tmpFiles = tmpFiles.sorted { (s1, s2) -> Bool in
                s1.1 < s2.1
            }

            if tmpFiles.count >= 10 {
                for i in 0 ..< 10 {
                    let path = tmpFiles[i].0
                    try path.removeItem()
                }
                DocsLogger.info("Delete the latest 10 cached documents")
            } else {
                try path.removeItem()
                DocsLogger.info("删除整个缓存目录")
            }
        } catch {
            DocsLogger.info("删除目录出错了")
        }
    }
}

extension FilePreviewService {
    // 创建缓存目录
    private func createCacheDirIfNeeded() {
        do {
            try FilePreviewService.localFileDir.createDirectoryIfNeeded()
        } catch {
            //缓存目录创建失败
            DocsLogger.error("Failed to create the cache directory")
        }
    }

    // 下载文件
    @discardableResult
    private func donwloadFileIfNeeded(_ file: FilePreviewModel) -> Bool {
        if FilePreviewService.checkIfLocalFileExisted(file: file) { // 文件存在
            let filePath = FilePreviewService.localFileDir.appendingRelativePath(file.cacheName)
            filePreviewHandler(filePath, nil)
            return false
        }

        guard let url = file.url, let downloadUrl = URL(string: url) else {
            //文件下载 URL 为空
            DocsLogger.info("file download URL is empty")
            filePreviewHandler(nil, NSError(domain: "file download URL is empty", code: 10_001, userInfo: nil))
            return false
        }

        // 开始下载
        let filePath = FilePreviewService.localFileDir.appendingRelativePath(file.cacheName)
        downloadRequest = DocsDownloadRequest(sourceURL: downloadUrl, destination: filePath)
        downloadRequest?.set(downloadProgressBlock: { [weak self] (progress) in
            self?.delegate?.download(progress: Float(progress))
        }).startDownload { [weak self] (_, response, error) in
            guard let `self` = self else { return }
            guard error == nil else {
                //下载中断
                self.filePreviewHandler(nil, NSError(domain: "Download interrupt", code: 10_003, userInfo: nil))
                DocsLogger.info("下载预览文件失败， \(String(describing: error))")
                return
            }
            DocsLogger.info("下载预览文件成功")
            guard self.checkResponseIsOK(response) else { return }
            self.onDownloadSuccessTo(filePath)
        }
        return true
    }

    private func checkResponseIsOK(_ httpresponse: URLResponse?) -> Bool {
        guard let httpResponse = httpresponse as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
                //服务端错误
                filePreviewHandler(nil, NSError(domain: "Server error", code: 10_002, userInfo: nil))
                return false
        }
        return true
    }

    private func onDownloadSuccessTo(_ filePath: SKFilePath) {
        filePreviewHandler(filePath, nil)
        delegate?.didFinishDownloadingTo(location: filePath)

        // 下载成功上报
        let paras = ["status_code": "1",
                     "file_id": DocsTracker.encrypt(id: file.id),
                     "file_type": file.type.rawValue,
                     "file_size": file.size
            ] as [String: Any]
        DocsTracker.log(enumEvent: .clientAttachmentCache, parameters: paras)
    }
}
