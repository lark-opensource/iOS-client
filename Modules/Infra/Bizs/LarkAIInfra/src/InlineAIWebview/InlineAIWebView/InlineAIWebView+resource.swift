//
//  InlineAIWebView+resource.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/11/21.
//

import Foundation
import WebKit
import LarkStorage
import MobileCoreServices

public struct InlineAIExtraOperation {
    /// 拦截URL读取沙盒资源
    public static let getLocalResource = "__kGetLocalResource"
}

extension InlineAIWebView {
    
    private static var customScheme: String { "inlineai" }
    
    static func setupConfiguration(origin: WKWebViewConfiguration) -> WKWebViewConfiguration {
        let configuration = origin
        configuration.setURLSchemeHandler(InlineAIURLSchemeHandler(), forURLScheme: customScheme)
        LarkInlineAILogger.info("setup custom scheme handler of: \(customScheme)")
        return configuration
    }
}

class InlineAIURLSchemeHandler: NSObject {
    
    // 用于保证task不被多次调用 didFinish 或者 didFailWithError, 否则可能会crash
    private var taskTable = NSHashTable<WKURLSchemeTask>(options: .weakMemory)
    
    private func mimeTypeForPath(_ path: String) -> String? {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension ?? ""
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
           let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
        return nil
    }
    
    private func getInfoFor(originUrl: URL, pathsDict: [String: String]) -> ([String: String], Data)? {
        let fileName = originUrl.fixedLastPathComponent // 文件名,保证唯一
        guard let fileAbsPath = pathsDict[fileName] else {
            LarkInlineAILogger.error("cannot find local resource, originUrl:\(originUrl), fileName:\(fileName)")
            return nil
        }
        do {
            let data = try Data.read(from: AbsPath(fileAbsPath))
            var header: [String: String] = ["Access-Control-Allow-Origin": "*"] // roadster前端使用fetch请求
            header["Content-Length"] = "\(data.count)"
            if let mineType = mimeTypeForPath(fileAbsPath) {
                header["Content-Type"] = mineType
            }
            return (header, data)
        } catch {
            LarkInlineAILogger.error("read from fileAbsPath:\(fileAbsPath), error:\(error)")
            return nil
        }
    }
    
    private func createError(_ description: String) -> Error {
        NSError(domain: "inlineAI.webView.urlScheme",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    private func loadResource(_ webView: WKWebView, url: URL, urlSchemeTask: WKURLSchemeTask) {
        defer {
            taskTable.remove(urlSchemeTask)
        }
        let taskStopped = taskTable.contains(urlSchemeTask) == false
        if taskStopped {
            LarkInlineAILogger.info("loadResource for url:\(url), task did stop, return")
            return
        }
        guard let (header, data) = getInfoFor(originUrl: url, pathsDict: webView.fileNamePathsDict) else {
            urlSchemeTask.didFailWithError(createError("urlSchemeTask didFail, get resource error:\(url)"))
            return
        }
        let succCode = 200; let version = "HTTP/1.1"
        guard let resp = HTTPURLResponse(url: url, statusCode: succCode, httpVersion: version, headerFields: header) else {
            urlSchemeTask.didFailWithError(createError("urlSchemeTask didFail, response init error:\(url)"))
            return
        }
        urlSchemeTask.didReceive(resp)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
}

extension InlineAIURLSchemeHandler: WKURLSchemeHandler {
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        taskTable.add(urlSchemeTask)
        loadResource(webView, url: url, urlSchemeTask: urlSchemeTask)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let urlString = urlSchemeTask.request.url?.absoluteString ?? ""
        taskTable.remove(urlSchemeTask)
        LarkInlineAILogger.error("urlSchemeTask stoped:\(urlString)")
    }
}

extension WKWebView {
    
    /// key: 资源文件名，value: 资源文件路径
    fileprivate var fileNamePathsDict: [String: String] {
        get {
            objc_getAssociatedObject(self, &associationKey) as? [String: String] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &associationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var associationKey: UInt8 = 0

extension InlineAIWebView {
    
    func setFileNamePathsDict(_ dict: [String: String]) {
        self.fileNamePathsDict = dict
    }
}

extension URL {
    
    fileprivate var fixedLastPathComponent: String {
        if lastPathComponent.isEmpty == false {
            return lastPathComponent
        }
        // scheme://dx_6574.6ff40348.chunk.js   这种URL, lastPathComponent为空
        let nsString = absoluteString as NSString
        let range = nsString.range(of: "/", options: .backwards)
        let subRangeLocation = range.location + 1
        if range.location != NSNotFound, subRangeLocation <= nsString.length {
            return nsString.substring(from: subRangeLocation)
        } else {
            return absoluteString
        }
    }
}
