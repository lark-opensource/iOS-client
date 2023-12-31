//
//  DownloadQueue.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/7/18.
//

import Foundation
import WebKit
import CookieManager
import LarkStorage
import LarkCache
import LarkSetting
import ECOInfra
import LarkWebViewContainer

let OPEN_PLATFORM_WEB_DRIVE_DOWNLOAD_FOLDER = "OPWDownloads"

protocol OPDownloadDelegate: AnyObject {
    func download(_ download: OPDownload, didComplete error: Error?)
    func download(_ download: OPDownload, didDownloadBytes downloadedBytes: Int64)
    func download(_ download: OPDownload, didFinishDownloadingTo location: String)
}

class OPDownload: NSObject {
    var delegate: OPDownloadDelegate?
    
    fileprivate(set) var filename: String
    fileprivate(set) var mimeType: String
    fileprivate(set) var isComplete = false
    fileprivate(set) var totalBytes: Int64?
    fileprivate(set) var downloadedBytes: Int64
    
    override init() {
        self.filename = "unknown"
        self.mimeType = MIMEType.OctetStream
        self.downloadedBytes = 0
        super.init()
    }
    
    func cancel() {}
    func pause() {}
    func resume() {}
    
    fileprivate func downloadPathForFilename(_ filename: String) throws -> URL {
        let downloadsPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(OPEN_PLATFORM_WEB_DRIVE_DOWNLOAD_FOLDER)
        let pathStr = downloadsPath.path
        WebBrowser.logger.info("OPWDownload atPath: \(pathStr)")
        var isDir: ObjCBool = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: pathStr, isDirectory: &isDir) {
            try FileManager.default.createDirectory(atPath: pathStr, withIntermediateDirectories: true, attributes: nil)
            WebBrowser.logger.debug("OPWDownload createDirectory success")
        }
        
        let basePath = downloadsPath.appendingPathComponent(filename)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension = fileExtension.count > 0 ? String(filename.dropLast(fileExtension.count + 1)) : filename
        
        var targetPath = basePath
        var count = 0
        while FileManager.default.fileExists(atPath: targetPath.path) {
            count += 1
            let targetPathWithoutExtension = "\(filenameWithoutExtension) (\(count))"
            targetPath = downloadsPath.appendingPathComponent(targetPathWithoutExtension).appendingPathExtension(fileExtension)
        }
        
        return targetPath
    }
    
    fileprivate func downloadIsoPath(_ filename: String, isEmbed: Bool) throws -> IsoPath {
        let folderPath = Self.downloadsFolderPath(isEmbed: isEmbed)
        WebBrowser.logger.info("OPWDownload atPath: \(folderPath.absoluteString)")
        if !folderPath.isDirectory {
            try folderPath.createDirectoryIfNeeded(withIntermediateDirectories: true)
            WebBrowser.logger.debug("OPWDownload createDirectory success")
        }
        let basePath = folderPath + filename
        let fileExtension = (filename as NSString).pathExtension
        let filenameWithoutExtension = fileExtension.count > 0 ? String(filename.dropLast(fileExtension.count + 1)) : filename
        
        var targetPath = basePath
        var count = 0
        while targetPath.exists {
            count += 1
            let withoutExtension = "\(filenameWithoutExtension) (\(count))"
            let withExtension = (withoutExtension as NSString).appendingPathExtension(fileExtension)
            let targetFilename = withExtension ?? withoutExtension
            targetPath = folderPath + targetFilename
        }
        
        return targetPath
    }
    
    static func downloadsFolderPath(isEmbed: Bool) -> IsoPath {
        let space = WebDownloadStorage.space()
        if Self.isEncryptedEnable() {
            if isEmbed {
                return .in(space: space, domain: Domain.biz.webApp).build(forType: .cache, relativePart: "CipherEmbedDownloads").usingCipher(suite: .default)
            }
            return .in(space: space, domain: Domain.biz.webApp).build(forType: .cache, relativePart: "CipherDownloads").usingCipher(suite: .default)
        }
        return .in(space: space, domain: Domain.biz.webApp).build(forType: .cache, relativePart: "Downloads")
    }
    
    private static func webPreviewEncryptDownloadEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.file_cipher.enable"))// user:global
    }
    
    static func isEncryptedEnable() -> Bool {
        return Self.webPreviewEncryptDownloadEnable() && LarkCache.isCryptoEnable()
    }
}

class OPHTTPDownload: OPDownload {
    let response: URLResponse
    let request: URLRequest
    
    fileprivate(set) var session: URLSession?
    fileprivate(set) var task: URLSessionDownloadTask?
    fileprivate(set) var cookieStore: WKHTTPCookieStore
    
    private var resumeData: Data?
    
    var state: URLSessionTask.State {
        return task?.state ?? .suspended
    }
    
    // 避免使用Unicode RTL改变文件类型, 造成命名欺骗
    public static func stripUnicode(fromFilename string: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet.punctuationCharacters)
        return string.components(separatedBy: allowed.inverted).joined()
    }
    
    deinit {
        WebBrowser.logger.info("OPWDownload OPHTTPDownload deinit")
    }
    
    init?(response: URLResponse, request: URLRequest, cookieStore: WKHTTPCookieStore) {
        self.response = response
        self.request = request
        self.cookieStore = cookieStore
        
        guard let scheme = request.url?.scheme, (scheme == "http" || scheme == "https") else {
            return nil
        }
        
        super.init()
        
        if let filename = response.suggestedFilename {
            self.filename = OPHTTPDownload.stripUnicode(fromFilename: filename)
            // 优化文件名太长（超过255个字符）导致文件下载后保存失败的问题
            if OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.file_name_too_long.optimize")), !filename.isEmpty {
                var rawFilename = OPHTTPDownload.stripUnicode(fromFilename: filename)
                let max_length = LarkWebSettings.shared.settingsModel?.downloads?.filename_max_length ?? 25
                
                if rawFilename.count > max_length {
                    // 超过 max_length 长度的文件名将被截取至 max_length
                    var shortfilename = ""
                    if let fileExtensionFromName = filename2FileExtension(filename: rawFilename) {
                        // 为了避免截断行为影响文件名尾缀，此处先预留尾缀长度
                        let cutCount = max(max_length - fileExtensionFromName.count - 1, 0)
                        let endIndex = rawFilename.index(rawFilename.startIndex, offsetBy: cutCount)
                        shortfilename = String(rawFilename[..<endIndex]) + "." + fileExtensionFromName
                    } else {
                        let endIndex = rawFilename.index(rawFilename.startIndex, offsetBy: max_length)
                        shortfilename = String(rawFilename[..<endIndex])
                    }
                    self.filename = shortfilename
                    WebBrowser.logger.info("OPWDownload OPHTTPDownload, filename length is cut to \(max_length)")
                } else {
                    WebBrowser.logger.info("OPWDownload OPHTTPDownload, filename length is equal to or below \(max_length)")
                }
            }
        }
        if let mimeType = response.mimeType {
            self.mimeType = mimeType
        }
        self.totalBytes = response.expectedContentLength > 0 ? response.expectedContentLength : nil
        self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
        self.task = session?.downloadTask(with: request)
    }
    
    override func cancel() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }
    
    override func pause() {
        task?.cancel(byProducingResumeData: { resumeData in
            self.resumeData = resumeData
        })
    }
    
    override func resume() {
        cookieStore.getAllCookies { [self] cookies in
            cookies.forEach { cookie in
                session?.configuration.httpCookieStorage?.setCookie(cookie)
            }
            guard let resumeData = self.resumeData else {
                self.task?.resume()
                return
            }
            self.task = session?.downloadTask(withResumeData: resumeData)
            self.task?.resume()
            self.resumeData = nil
        }
    }
}

extension OPHTTPDownload: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let urlError = error as? URLError, .cancelled == urlError.code, resumeData != nil {
            return
        }
        delegate?.download(self, didComplete: error)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadedBytes = totalBytesWritten
        totalBytes = totalBytesExpectedToWrite
        delegate?.download(self, didDownloadBytes: bytesWritten)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        cancel()
        do {
            var path: String
            if WebBrowser.webDrivePreviewEnhancedEnable() {
                path = try pathPushDownloadingTo(location)
            } else {
                path = try pathEmbedDownloadingTo(location)
            }
            delegate?.download(self, didFinishDownloadingTo: path)
            isComplete = true
        } catch let error {
            delegate?.download(self, didComplete: error)
        }
    }
    
    private func pathEmbedDownloadingTo(_ location: URL) throws -> String {
        if Self.isEncryptedEnable() {
            let destIsoPath = try downloadIsoPath(filename, isEmbed: true)
            try destIsoPath.notStrictly.moveItem(from: AbsPath(location.path))
            return destIsoPath.absoluteString
        }
        let destURL = try downloadPathForFilename(filename)
        try FileManager.default.moveItem(at: location, to: destURL)
        return destURL.path
    }
    
    private func pathPushDownloadingTo(_ location: URL) throws -> String {
        let destIsoPath = try downloadIsoPath(filename, isEmbed: false)
        try destIsoPath.notStrictly.moveItem(from: AbsPath(location.path))
        return destIsoPath.absoluteString
    }
    
    private func filename2FileExtension(filename: String) -> String? {
        let components = filename.components(separatedBy: ".")
        if components.count > 1, let last = components.last, !last.isEmpty {
            return last
        }
        return nil
    }
}

// MARK: - DownloadQueue
protocol OPDownloadQueueDelegate: AnyObject {
    func downloadQueue(_ queue: OPDownloadQueue, didStartDownload download: OPDownload)
    func downloadQueue(_ queue: OPDownloadQueue, didDownloadBytes bytes: Int64, totalBytes: Int64?)
    func downloadQueue(_ queue: OPDownloadQueue, download: OPDownload, didFinishDownloadingTo location: String)
    func downloadQueue(_ queue: OPDownloadQueue, didComplete error: Error?)
}

class OPDownloadQueue {
    var downloads: [OPDownload]
    weak var delegate: OPDownloadQueueDelegate?
    var isEmpty: Bool {
        return downloads.isEmpty
    }
    
    fileprivate var combinedBytes: Int64 = 0
    fileprivate var combinedTotalBytes: Int64?
    fileprivate var lastDownloadError: Error?
    
    deinit {
        WebBrowser.logger.info("OPWDownload OPDownloadQueue deinit")
    }
    
    init() {
        self.downloads = []
    }
    
    func enqueue(_ download: OPDownload) {
        if downloads.isEmpty {
            combinedBytes = 0
            combinedTotalBytes = 0
            lastDownloadError = nil
        }
        
        downloads.append(download)
        download.delegate = self
        
        if let totalBytes = download.totalBytes, combinedTotalBytes != nil {
            combinedTotalBytes! += totalBytes
        } else {
            combinedTotalBytes = nil
        }
        
        download.resume()
        delegate?.downloadQueue(self, didStartDownload: download)
    }
    
    func cancelAll() {
        for download in downloads where !download.isComplete {
            download.cancel()
        }
    }
    
    func pauseAll() {
        for download in downloads where !download.isComplete {
            download.pause()
        }
    }
    
    func resumeAll() {
        for download in downloads where !download.isComplete {
            download.resume()
        }
    }
}

extension OPDownloadQueue: OPDownloadDelegate {
    func download(_ download: OPDownload, didComplete error: Error?) {
        guard let error = error, let index = downloads.firstIndex(of: download) else {
            return
        }
        lastDownloadError = error
        downloads.remove(at: index)
        if downloads.isEmpty {
            delegate?.downloadQueue(self, didComplete: lastDownloadError)
        }
    }
    
    func download(_ download: OPDownload, didDownloadBytes downloadedBytes: Int64) {
        combinedBytes += downloadedBytes
        delegate?.downloadQueue(self, didDownloadBytes: combinedBytes, totalBytes: combinedTotalBytes)
    }
    
    func download(_ download: OPDownload, didFinishDownloadingTo location: String) {
        guard let index = downloads.firstIndex(of: download) else {
            return
        }
        downloads.remove(at: index)
        delegate?.downloadQueue(self, download: download, didFinishDownloadingTo: location)
        if downloads.isEmpty {
            delegate?.downloadQueue(self, didComplete: lastDownloadError)
        }
    }
}
