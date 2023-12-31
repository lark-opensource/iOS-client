//
//  DocSourceSchemeHandler.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/9/4.
//

import UIKit
import WebKit
import SKFoundation
import ThreadSafeDataStructure
import SKUIKit
import SpaceInterface
import SKInfra

public final class DocSourceSchemeHandler: NSObject, WKURLSchemeHandler {

    class URLSchemeTaskWrapper {
        weak var task: WKURLSchemeTask? //task
        var dataSession: CustomSchemeDataSession? //对应的网络请求
        init(task: WKURLSchemeTask, dataSession: CustomSchemeDataSession) {
            self.task = task
            self.dataSession = dataSession
        }
    }

    /// 存储正在进行的所有请求
    private var taskTable = NSMapTable<WKURLSchemeTask, URLSchemeTaskWrapper>.weakToStrongObjects()

    /// 文档类型
    private var fileType: DocsType?

    public override init() {
        super.init()
    }

    public func updateCurrentFileTye(_ fileType: DocsType?) {
        self.fileType = fileType
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        //Check that the url path is of interest for you, etc...
        spaceAssert(Thread.isMainThread)
        guard urlSchemeTask.request.url?.scheme == DocSourceURLProtocolService.scheme else {
            DocsLogger.error("wrong url scheme", error: nil, component: nil)
            spaceAssertionFailure()
            return
        }
        let downloadFileUrl = urlSchemeTask.request.url
//        DocsLogger.info("webView is \(ObjectIdentifier(webView)), task is \(urlSchemeTask) start load url \(urlSchemeTask.request.url?.absoluteString ?? "")")
        let tmpWebViewUrl = webView.url
        let dataSession = CustomSchemeDataSession(request: urlSchemeTask.request, delegate: self)
        dataSession.webviewWidth = webView.frame.size.width
        dataSession.webviewUrl = tmpWebViewUrl
        dataSession.fileType = fileType
        dataSession.webIdentifyId = webView.editorIdentity
        
        let taskWrapper = URLSchemeTaskWrapper(task: urlSchemeTask, dataSession: dataSession)
        taskTable.setObject(taskWrapper, forKey: urlSchemeTask)
        dataSession.start { [weak self, weak urlSchemeTask, weak taskWrapper] (data1, response, error) in
            DispatchQueue.main.async {
                guard let strongSelf = self, let taskWrapper = taskWrapper else { return }
                defer {
                    strongSelf.taskTable.removeObject(forKey: taskWrapper.task)
                }
                let hadStoppedTask = (strongSelf.taskTable.object(forKey: taskWrapper.task) == nil)
                guard hadStoppedTask == false else {
                	    DocsLogger.info("DocSourceSchemeHandler, task had stop, return")
                    //spaceAssertionFailure()
                    return
                }

                if let error = error {
                    let extraInfo = ["error": error.underlyingError.localizedDescription]
                    DocsLogger.error("urlschemeTask end with error", extraInfo: extraInfo, error: nil, component: nil)
                    taskWrapper.task?.didFailWithError(error)
                    JSFileDownloadStatistics.statisticsDownloadJSFileTaskIfNeed(isStart: false, isSuccess: false, for: downloadFileUrl)

                } else {
                    guard let urlSchemeTask = urlSchemeTask else { return }
                    guard let data = data1, let originUrl = urlSchemeTask.request.url else {
                        let extraInfo: [String: Any] = ["dataCount": data1?.count ?? 0]
                        DocsLogger.error("urlschemeTask fail with data", extraInfo: extraInfo, error: nil, component: nil)
                        spaceAssertionFailure("urlschemeTask fail with no data")
                        return
                    }
                    if let response = response {
//                        DocsLogger.info("task is \(urlSchemeTask)  load url \(urlSchemeTask.request.url?.absoluteString ?? "") succ with response")
                        taskWrapper.task?.didReceive(response)
                    } else {
                        let response1 = strongSelf.createResponseForWeb(webUrl: tmpWebViewUrl, urlSchemeTask: urlSchemeTask,
                                                                        originUrl: originUrl, data: data)
                        taskWrapper.task?.didReceive(response1)
                    }
                    taskWrapper.task?.didReceive(data)
                    taskWrapper.task?.didFinish()
                    JSFileDownloadStatistics.statisticsDownloadJSFileTaskIfNeed(isStart: false, isSuccess: true, for: originUrl)
                    DispatchQueue.global().async {
                        strongSelf.saveDataIfNeeded(data, for: downloadFileUrl)
                    }
                }
            }
        }
    }

    private func saveDataIfNeeded(_ data: Data, for url: URL?) {

        guard
            let fileUrl = url,
            let fePkgPath = GeckoPackageManager.shared.filesRootPath(for: GeckoChannleType.webInfo) else {
                return
        }

        guard GeckoPackageManager.shared.isInRemoteResourcesJson(targetFilePath: fileUrl.path) else { return }
        let targetUrl = fePkgPath.appendingRelativePath(fileUrl.path)
        DocsLogger.info("will save js file data to: \(targetUrl.pathString)")
        do {
            try data.write(to: targetUrl, options: .atomic)
        } catch {
            DocsLogger.error("can't save js file data to target path: \(targetUrl.pathString)， error：\(error)")
        }

        GeckoPackageManager.shared.removeMarkFileNotFound(filePath: fileUrl.path)
    }

    private func createResponseForWeb(webUrl: URL?, urlSchemeTask: WKURLSchemeTask, originUrl: URL, data: Data) -> URLResponse {
        // 必须提供。。。 mimetype
        let mimetype = mimeTypeFor(urlSchemeTask.request)
//        DocsLogger.info("task is \(urlSchemeTask )  load url \(urlSchemeTask.request.url?.absoluteString ?? "") succ with data minitype \(mimetype ?? "")")
        let defaultResponse = URLResponse(url: originUrl, mimeType: mimetype, expectedContentLength: data.count, textEncodingName: nil)
        if let originHeaders = urlSchemeTask.request.allHTTPHeaderFields, originHeaders.keys.contains("Origin") {
            var headers: [String: String] = SpaceHttpHeaders.common
            if let originHeaderUrl = URL(string: originHeaders["Origin"] ?? "*") {
                headers.merge(other: [DocsCustomHeader.accessCredentials.rawValue: "true",
                                      DocsCustomHeader.accessMethods.rawValue: "POST, GET, OPTIONS, PUT, DELETE",
                                      DocsCustomHeader.accessOrigin.rawValue: originHeaderUrl.absoluteString])
            }
            let modifiedResponse = HTTPURLResponse(url: originUrl, statusCode: 200, httpVersion: nil, headerFields: headers)
            return modifiedResponse ?? defaultResponse
        } else {
            return defaultResponse
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        spaceAssert(Thread.isMainThread)
        DocsLogger.info("task is \(urlSchemeTask) stop loading")
        let schemeTaskWrapper = self.taskTable.object(forKey: urlSchemeTask)
        schemeTaskWrapper?.task = nil
        schemeTaskWrapper?.dataSession?.stop()
        self.taskTable.removeObject(forKey: urlSchemeTask)
    }

    private func mimeTypeFor(_ request: URLRequest) -> String? {
        guard let originUrl = request.url else {
            return nil
        }
        var mimeType: String?
        if originUrl.pathExtension == "js" {
            mimeType = "application/javascript"
        } else if originUrl.pathExtension == "css" {
            mimeType = "text/css"
        } else if originUrl.pathExtension == ".html" {
            mimeType = "text/html"
        } else if originUrl.absoluteString.contains("/api/box/stream/download/all/"), originUrl.absoluteString.contains("mount_point=comment") {
            mimeType = "audio/mp4"
        } else if let acceptField = request.allHTTPHeaderFields?["Accept"] {
            mimeType = acceptField.components(separatedBy: ",").first
        } else {
            DocsLogger.error("no minitype", error: nil, component: nil)
//            spaceAssertionFailure("no mimetype!!!")
        }
        return mimeType ?? "text/html"
    }

}

extension DocSourceSchemeHandler: CustomSchemeDataSessionDelegate {
    public func session(_ session: CustomSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest) {
    }
}

enum JSFileDownloadStatistics {
    private static var downloadTimeCountDict = ThreadSafeDictionary<String, TimeInterval>()

    static func statisticsDownloadJSFileTaskIfNeed(isStart: Bool, isSuccess: Bool, for url: URL?) {
        guard let fileUrl = url else { return }
        guard GeckoPackageManager.shared.isInRemoteResourcesJson(targetFilePath: fileUrl.path) else { return }
        DocsLogger.info("按需加载js等文件，是否开始：\(isStart), 是否成功：\(isSuccess), targetUrl:\(fileUrl.absoluteString)")
        let now = Date().timeIntervalSince1970
        if isStart {
            downloadTimeCountDict.updateValue(now, forKey: fileUrl.path)
        } else if let startTime = downloadTimeCountDict.value(ofKey: fileUrl.path) {
            let diff = (now - startTime) * 1000
            let version = GeckoPackageManager.shared.currentVersion(type: .webInfo)
            let params: [String: Any] = [
                                        "path": fileUrl.path,
                                        "isSuccess": isSuccess ? "1" : "0",
                                        "cost_time": diff,
                                        "pkg_version": version,
                                        "isBlank": "0",
                                        ]
            DocsTracker.log(enumEvent: .loadFeRemoteResource, parameters: params)

            downloadTimeCountDict.removeValue(forKey: fileUrl.path)
        }

    }

    //预加载Blank页面的时候，下载js，进行埋点上传
    static func statisticsForbidDownloadJSFileTask(for url: URL?) {
        guard let fileUrl = url else { return }
        let version = GeckoPackageManager.shared.currentVersion(type: .webInfo)
        let params: [String: Any] = [
                                    "path": fileUrl.path,
                                    "isSuccess": "0",
                                    "cost_time": 0,
                                    "pkg_version": version,
                                    "isBlank": "1",
                                    ]
        DocsTracker.log(enumEvent: .loadFeRemoteResource, parameters: params)

        downloadTimeCountDict.removeValue(forKey: fileUrl.path)
    }
}
