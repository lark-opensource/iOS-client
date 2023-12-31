//
//  MailHttpSchemeHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2022/11/16.
//

import Foundation
import WebKit
import Kingfisher
import Alamofire
import LarkStorage

extension URLSchemeTaskWrapper {
    var dataRequest: DataRequest? {
        return request as? DataRequest
    }
}

protocol MailCustomSchemeHandling: WKURLSchemeHandler {
    var taskTable: NSMapTable<WKURLSchemeTask, URLSchemeTaskWrapper> { get }
    
    @discardableResult
    func sendResponseToTask(_ urlSchemeTask: WKURLSchemeTask, response: URLResponse, data: Data, dataDecorator: ((Data) -> Data)?) -> Bool
    func sendErrorToTask(_ urlSchemeTask: WKURLSchemeTask, error: Error)
}

extension MailCustomSchemeHandling {
    @discardableResult
    func sendResponseToTask(_ urlSchemeTask: WKURLSchemeTask, response: URLResponse, data: Data, dataDecorator: ((Data) -> Data)?) -> Bool {
        let logURL = urlSchemeTask.request.url?.mailSchemeLogURLString ?? ""
        guard taskTable.object(forKey: urlSchemeTask) != nil else {
            MailLogger.info("urlSchemeTask removed on response, \(logURL)")
            return false
        }
        if let dataDecorator = dataDecorator {
            DispatchQueue.global(qos: .userInteractive).async { [weak urlSchemeTask] in
                // 后台线程对数据进行加工
                let mimeType = response.mimeType ?? ""
                MailLogger.info("Mail dataDecorator start: \(logURL), \(mimeType), dataCount \(data.count)")
                let data = dataDecorator(data)
                var response = response
                if let url = response.url {
                    // update response
                    response = URLResponse(url: url, mimeType: response.mimeType, expectedContentLength: data.count, textEncodingName: nil)
                }
                MailLogger.info("Mail dataDecorator finish: \(logURL), \(mimeType), dataCount \(data.count)")
                DispatchQueue.main.async {
                    urlSchemeTask?.didReceive(response)
                    urlSchemeTask?.didReceive(data)
                    urlSchemeTask?.didFinish()
                }
            }
        } else {
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        }
        taskTable.removeObject(forKey: urlSchemeTask)
        return true
    }
    
    func sendErrorToTask(_ urlSchemeTask: WKURLSchemeTask, error: Error) {
        guard taskTable.object(forKey: urlSchemeTask) != nil else {
            MailLogger.info("urlSchemeTask removed on error \(error.desensitizedMessage), \(urlSchemeTask.request.url?.mailSchemeLogURLString ?? "")")
            return
        }
        urlSchemeTask.didFailWithError(error)
        taskTable.removeObject(forKey: urlSchemeTask)
    }
}

protocol MailCustomSchemeDownloading {
    func startDownload(with url: URL, tid: String,
                       beforeHandler: ((URL, Bool) -> Void)?,
                       completionHandler: ((Data, String?, Bool) -> Void)?,
                       progressHandler: ((Progress) -> Void)?,
                       errorHandler: ((Int?, Error?) -> Void)?) -> Any?
}

class MailNewCustomSchemeHandler: NSObject, MailCustomSchemeHandling {
    /// 存储正在进行的所有请求
    private(set) var taskTable = NSMapTable<WKURLSchemeTask, URLSchemeTaskWrapper>.weakToStrongObjects()
    /// 任务出队开始下载时间
    private lazy var eventDequeueTime = [String: Date]()
    /// 实际下载能力
    private let downloader: MailCustomSchemeDownloading
    
    init(downloader: MailCustomSchemeDownloading) {
        self.downloader = downloader
    }
    
    static func imgDataCompressorFor(tid: String) -> ((Data) -> Data)? {
        // WebView第二次被杀时，对图片进行压缩，减少图片内存占用
        let terminatedCount = MailMessageListViewsPool.threadTerminatedCountDict[tid] ?? 0
        if terminatedCount > 1 {
            mailAssertionFailure("MailWebTerminated compress with count:\(terminatedCount), tid:\(tid)")
            return { originData in
                let percentage: CGFloat = 0.5
                if let img = UIImage(data: originData)?.resized(withPercentage: percentage), let compressData = img.data(quality: 0) {
                    return compressData
                }
                return originData
            }
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            return
        }
        let wrapTask = URLSchemeTaskWrapper(task: urlSchemeTask)
        taskTable.setObject(wrapTask, forKey: urlSchemeTask)

        let logURL = urlSchemeTask.request.url?.mailSchemeLogURLString ?? ""
        let tid = (webView as? MailBaseWebViewAble)?.identifier ?? ""
        MailLogger.info("webview start url http scheme task t_id \(tid), with md5URL \(logURL)")
        let superContainer = webView.superview as? MailMessageListView
        superContainer?.onWebViewStartURLSchemeTask(with: urlSchemeTask.request.url?.absoluteString)
        let isMessagePage = superContainer != nil
        
        let onComplete: ((Data, Bool) -> Void) = { [weak self] imgData, fromCache in
            defer {
                self?.taskTable.removeObject(forKey: urlSchemeTask)
            }
            MailLogger.info("webview start url http scheme task complete t_id \(tid), with md5URL \(logURL), length \(imgData.count)")
            let defaultResponse = URLResponse.mail.customImageResponse(urlSchemeTask: urlSchemeTask, originUrl: url, data: imgData)
            self?.sendResponseToTask(urlSchemeTask, response: defaultResponse, data: imgData, dataDecorator: MailNewCustomSchemeHandler.imgDataCompressorFor(tid: tid))
        }
        
        wrapTask.request = downloader.startDownload(with: url, tid: tid, beforeHandler: { [weak superContainer] originUrl, fromCache in
            superContainer?.onWebViewSetUpURLSchemeTask(with: originUrl.absoluteString, fromCache: fromCache)
        }, completionHandler: { data, _, fromCache in
            // success
            superContainer?.onWebViewFinishImageDownloading(with: url.absoluteString,
                                                            dataLength: data.count,
                                                            finishWithDrive: false,
                                                            downloadType: .http)
            onComplete(data, fromCache)
        }, progressHandler: { [weak superContainer] _ in
            // progress
            guard let viewController = superContainer?.controller else { return }
            let hasInqueue = (self.eventDequeueTime[url.absoluteString] != nil)
            if !hasInqueue && isMessagePage {
                // 第一次有进度，记录inqueue时间
                self.eventDequeueTime[url.absoluteString] = Date()
                viewController.callJavaScript("window.onImageStartDownloading('\(url.absoluteString)')")
                superContainer?.onWebViewImageDownloading(with: url.absoluteString)
            }
        }, errorHandler: { [weak self, weak urlSchemeTask] statusCode, error in
            guard let urlSchemeTask = urlSchemeTask else {
                MailLogger.info("urlSchemeTask deinit on error \(logURL)")
                return
            }
            // error
            let dummyErrorCode = -99
            let error = error ?? MailURLError.unexpected(code: dummyErrorCode, msg: "Error without real error")
            var logMessage = ""
            if let statusCode = statusCode {
                logMessage += " s-\(statusCode)"
            }
            logMessage += " e-\(error.mailErrorCode)"
            self?.sendErrorToTask(urlSchemeTask, error: error)

            // 失败场景上报到tea，成功会通过imageOnLoad上报
            let debugMessage = (error as? MailURLError)?.errorMessage ?? error.underlyingError.localizedDescription
            let errorInfo: APMErrorInfo = (code: error.mailErrorCode, errMsg: "\(debugMessage);\(logMessage)")
            superContainer?.onWebViewImageDownloadFailed(with: url.absoluteString, finishWithDrive: false, downloadType: .http, errorInfo: errorInfo)
            MailLogger.error("MailHttpSchemeHandler fail to get image with \(error.desensitizedMessage)")
        })
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        MailLogger.info("MailNewCustomSchemeHandler stop urlSchemeTask")
        if let schemeTaskWrapper = taskTable.object(forKey: urlSchemeTask) {
            schemeTaskWrapper.dataRequest?.cancel()
            schemeTaskWrapper.task = nil
            schemeTaskWrapper.dataSession?.stop()
        }
        taskTable.removeObject(forKey: urlSchemeTask)
    }
}

class MailHttpSchemeDownloader: MailCustomSchemeDownloading {
    let cacheService: MailCacheService?
    private let serialQueue = DispatchQueue(label: "MailSDK.Downloader.Queue",
                                                           attributes: .init(rawValue: 0))

    init(cacheService: MailCacheService?) {
        self.cacheService = cacheService
    }
    
    func startDownload(with url: URL, tid: String = "", isCrypto: Bool = true, checkOtherCache: Bool = false,
                       beforeHandler: ((URL, Bool) -> Void)? = nil,
                       completionHandler: ((Data, String?, Bool) -> Void)?,
                       errorHandler: ((Int?, Error?) -> Void)?) -> DataRequest? {
        let logURL = url.mailSchemeLogURLString
        if let cachedData = cacheService?.object(forKey: url.absoluteString, crypto: isCrypto) as? Data {
            // 先从预期的是否crypto里面查数据
            if MailMessageListViewsPool.fpsOpt {
                self.serialQueue.async { [weak self] in
                    var cachedPath = self?.cacheService?.cachedFilePath(forKey: url.absoluteString, crypto: isCrypto)
                    if let path = cachedPath, !AbsPath(path).exists {
                        cachedPath = nil
                    }
                    MailLogger.info("webview start url http scheme task get cahce t_id \(tid), with md5URL \(logURL)")
                    asyncRunInMainThread {
                        beforeHandler?(url, true)
                        completionHandler?(cachedData, cachedPath, true)
                    }
                }
            } else {
                var cachedPath = self.cacheService?.cachedFilePath(forKey: url.absoluteString, crypto: isCrypto)
                if let path = cachedPath, !AbsPath(path).exists {
                    cachedPath = nil
                }
                MailLogger.info("webview start url http scheme task get cahce t_id \(tid), with md5URL \(logURL)")
                beforeHandler?(url, true)
                completionHandler?(cachedData, cachedPath, true)
            }
            return nil
        } else if checkOtherCache, let cachedData = cacheService?.object(forKey: url.absoluteString, crypto: !isCrypto) as? Data {
            // 再从检查另外一个cache，避免重复下载
            // 保存回预期的cache
            if MailMessageListViewsPool.fpsOpt {
                self.serialQueue.async { [weak self] in
                    self?.cacheService?.set(object: cachedData as NSCoding, for: url.absoluteString, crypto: isCrypto)
                    var cachedPath = self?.cacheService?.cachedFilePath(forKey: url.absoluteString, crypto: isCrypto)
                    if let path = cachedPath, !AbsPath(path).exists {
                        cachedPath = nil
                    }
                    MailLogger.info("webview start url http scheme task get othercahce t_id \(tid), with md5URL \(logURL)")
                    asyncRunInMainThread {
                        beforeHandler?(url, true)
                        completionHandler?(cachedData, cachedPath, true)
                    }
                }
            } else {
                self.cacheService?.set(object: cachedData as NSCoding, for: url.absoluteString, crypto: isCrypto)
                var cachedPath = self.cacheService?.cachedFilePath(forKey: url.absoluteString, crypto: isCrypto)
                if let path = cachedPath, !AbsPath(path).exists {
                    cachedPath = nil
                }
                MailLogger.info("webview start url http scheme task get othercahce t_id \(tid), with md5URL \(logURL)")
                beforeHandler?(url, true)
                completionHandler?(cachedData, cachedPath, true)
            }
            
            return nil
        } else {
            beforeHandler?(url, false)
            MailLogger.info("webview start url http scheme task start request t_id \(tid), with md5URL \(logURL)")
            return Alamofire.request(url).responseData { [weak self] response in
                guard let self = self else { return }
                if let data = response.result.value {
                    if MailMessageListViewsPool.fpsOpt {
                        self.serialQueue.async { [weak self] in
                            guard let self = self else { return }
                            self.cacheService?.set(object: data as NSCoding, for: url.absoluteString, crypto: isCrypto)
                            var cachedPath = self.cacheService?.cachedFilePath(forKey: url.absoluteString, crypto: isCrypto)
                            if let path = cachedPath, !AbsPath(path).exists {
                                cachedPath = nil
                            }
                            MailLogger.info("webview start url http scheme task finish request t_id \(tid), with md5URL \(logURL), length \(data.count)")
                            asyncRunInMainThread {
                                completionHandler?(data, cachedPath, false)
                            }
                        }
                    } else {
                        self.cacheService?.set(object: data as NSCoding, for: url.absoluteString, crypto: isCrypto)
                        var cachedPath = self.cacheService?.cachedFilePath(forKey: url.absoluteString, crypto: isCrypto)
                        if let path = cachedPath, !AbsPath(path).exists {
                            cachedPath = nil
                        }
                        MailLogger.info("webview start url http scheme task finish request t_id \(tid), with md5URL \(logURL), length \(data.count)")
                        completionHandler?(data, cachedPath, false)
                    }
                } else {
                    errorHandler?(response.response?.statusCode, response.error)
                    MailLogger.error("webview start url http scheme task request error t_id \(tid), with md5URL \(logURL)")
                }
            }
        }
    }
    
    func startDownload(with url: URL, tid: String, beforeHandler: ((URL, Bool) -> Void)?, completionHandler: ((Data, String?, Bool) -> Void)?, progressHandler: ((Progress) -> Void)?, errorHandler: ((Int?, Error?) -> Void)?) -> Any? {
        return startDownload(with: url, tid: tid, isCrypto: true, checkOtherCache: false, beforeHandler: beforeHandler, completionHandler: completionHandler, errorHandler: errorHandler)?.downloadProgress(closure: { p in
            progressHandler?(p)
        })
    }
}

// hack
@available(iOS 11.0, *)
extension WKWebView {
    /// 支持HTTP的URLSchemeHandlers
    static func enableHttpIntercept() -> Bool {
        /// 这种方式支持通过Configuration适配支持的HTTP，但没法取消(configuration是不可变的)。
        /// todo: 这里需要判断FG
        return switchHandlesURLScheme()
    }
    private static func switchHandlesURLScheme() -> Bool {
        if
            case let cls = WKWebView.self,
            let m1 = class_getClassMethod(cls, NSSelectorFromString("handlesURLScheme:")),
            let m2 = class_getClassMethod(cls, #selector(WKWebView.wrapHandles(urlScheme:)))
        {
            method_exchangeImplementations(m1, m2)
            return true
        } else {
            return false
        }
    }
    /// 返回true如果WKWebview支持处理这种协议, 但WKWebview默认支持http，所以返回false支持用自定义的http Handlers
    ///
    /// NOTE: 如果不在configuration里注册http handlers, 则仍然会用WKWebView默认的HTTP进行处理
    @objc dynamic
    private static func wrapHandles(urlScheme: String) -> Bool {
        if urlScheme == "http" || urlScheme == "https" { return false }
        return self.wrapHandles(urlScheme: urlScheme)
    }
}
