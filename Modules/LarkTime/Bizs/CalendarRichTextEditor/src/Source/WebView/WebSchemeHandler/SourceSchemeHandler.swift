//
//  DocSourceSchemeHandler.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/9/4.
//

import UIKit
import WebKit

final class SourceSchemeHandler: NSObject, WKURLSchemeHandler {

    static var scheme = "docsource"

    final class URLSchemeTaskWrapper {
        weak var task: WKURLSchemeTask? //task
        var dataSession: CustomSchemeDataSession? //对应的网络请求
        init(task: WKURLSchemeTask, dataSession: CustomSchemeDataSession) {
            self.task = task
            self.dataSession = dataSession
        }
    }

    /// 存储正在进行的所有请求
    private var taskTable = NSMapTable<WKURLSchemeTask, URLSchemeTaskWrapper>.weakToStrongObjects()

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        guard urlSchemeTask.request.url?.scheme == SourceSchemeHandler.scheme else {
            Logger.error("wrong url scheme", error: nil, component: nil)
            assertionFailure()
            return
        }
        let tmpWebViewUrl = webView.url
        let dataSession = CustomSchemeDataSession(request: urlSchemeTask.request, delegate: self)
        dataSession.webviewUrl = tmpWebViewUrl
        let taskWrapper = URLSchemeTaskWrapper(task: urlSchemeTask, dataSession: dataSession)
        taskTable.setObject(taskWrapper, forKey: urlSchemeTask)
        dataSession.start { [weak self, weak urlSchemeTask] (data1, response, error) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                assert(Thread.isMainThread)
                defer {
                    strongSelf.taskTable.removeObject(forKey: taskWrapper.task)
                }

                guard strongSelf.taskTable.object(forKey: taskWrapper.task) != nil else {
                    Logger.info("DocSourceSchemeHandler, task had stop, return")
                    assertionFailure()
                    return
                }

                if let error = error {
                    let extraInfo = ["error": error.underlyingError.localizedDescription]
                    Logger.error("urlschemeTask end with error", extraInfo: extraInfo, error: nil, component: nil)
                    taskWrapper.task?.didFailWithError(error)
                } else {
                    guard let urlSchemeTask = urlSchemeTask else { return }
                    guard let data = data1, let originUrl = urlSchemeTask.request.url else {
                        let extraInfo: [String: Any] = ["dataCount": data1?.count ?? 0]
                        Logger.error("urlschemeTask fail with data", extraInfo: extraInfo, error: nil, component: nil)
                        assertionFailure("urlschemeTask fail with no data")
                        return
                    }
                    if let response = response {
                        taskWrapper.task?.didReceive(response)
                    } else {
                        let response1 = strongSelf.createResponseForWeb(webUrl: tmpWebViewUrl, urlSchemeTask: urlSchemeTask,
                                                                        originUrl: originUrl, data: data)
                        taskWrapper.task?.didReceive(response1)
                    }
                    taskWrapper.task?.didReceive(data)
                    taskWrapper.task?.didFinish()
                }
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread)
        Logger.info("task is \(urlSchemeTask) stop loading")
        let schemeTaskWrapper = self.taskTable.object(forKey: urlSchemeTask)
        schemeTaskWrapper?.task = nil
        schemeTaskWrapper?.dataSession?.stop()
        self.taskTable.removeObject(forKey: urlSchemeTask)
    }

    private func createResponseForWeb(webUrl: URL?, urlSchemeTask: WKURLSchemeTask, originUrl: URL, data: Data) -> URLResponse {
        // 必须提供。。。 mimetype
        let mimetype = "text/html"
        let defaultResponse = URLResponse(url: originUrl, mimeType: mimetype, expectedContentLength: data.count, textEncodingName: nil)
        return defaultResponse
    }
}

extension SourceSchemeHandler: CustomSchemeDataSessionDelegate {
    func session(_ session: CustomSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest) {
    }
}
