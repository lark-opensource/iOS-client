//
//  MailEditorLogHandler.swift
//  MailSDK
//
//  Created by zhongtianren on 2019/9/12.
//

import UIKit
import LKCommonsLogging
import Homeric
import RxSwift
import RustPB

extension EditorJSService {
    static let editorLog = EditorJSService(rawValue: "biz.mail.log")
    static let editorTracker = EditorJSService(rawValue: "biz.mail.tracker")
    static let editorHitPoint = EditorJSService(rawValue: "biz.mail.hitPoint")
}

class MailEditorLogHandler: EditorJSServiceHandler {
    let disposeBag = DisposeBag()
    weak var uiDelegate: MailSendController?
    static let logger = Logger.log(MailEditorLogHandler.self, category: "Module.MailEditorLogHandler")

    var handleServices: [EditorJSService] = [.editorLog, .editorTracker, .editorHitPoint]

    func handle(params: [String: Any], serviceName: String) {
        if serviceName == EditorJSService.editorLog.rawValue {
            handleEditorLog(params)
        } else if serviceName == EditorJSService.editorTracker.rawValue {
            handleEditorTracker(params)
        } else if serviceName == EditorJSService.editorHitPoint.rawValue {
            handleEditorHitPoint(params)
        }
    }

    func handleEditorLog(_ args: [String: Any]) {
        guard let content = args["content"] as? String,
            let level = args["level"] as? Int,
            let logLevel = TemplateLogLevel(rawValue: level) else {
                mailAssertionFailure("unexpected param")
                return
        }
        switch logLevel {
        case .debug:
            MailEditorLogHandler.logger.debug(content)
        case .info:
            MailEditorLogHandler.logger.info(content)
        case .warn:
            MailEditorLogHandler.logger.warn(content)
        case .error:
            if content.contains("error in unhandledrejection") {
                MailTracker.log(event: "mail_compose_unhandled_rejection", params: nil)
            }
            MailEditorLogHandler.logger.error(content)
        }
    }

    func handleEditorTracker(_ args: [String: Any]) {
        guard let event = args["event"] as? String,
            let isStart = args["isStart"] as? Bool,
            let timestamp = args["timestamp"] as? Int else {
                mailAssertionFailure("unexpected param")
                return
        }
        let params = args["params"] as? [String: Any]
        if isStart {
            MailTracker.startRecordTimeConsuming(event: event, params: params, currentTime: timestamp)
        } else {
            MailTracker.endRecordTimeConsuming(event: event, params: params, currentTime: timestamp)
        }

    }

    func handleEditorHitPoint(_ args: [String: Any]) {
        guard let url = args["url"] as? String else {
            mailAssertionFailure("unexpected param")
            return
        }
        let method = args["method"] as? String
        let header = args["header"] as? [String: String]
        let bodyDict = args["body"] as? [String: Any]

        var req = SendHttpRequest()
        req.url = url
        if method == "post" {
            req.method = .post
        } else {
            req.method = .get
        }
        req.headers = header ?? [:]
        if let array = bodyDict?["list"] as? [[String: Any]] {
            let useCache = self.uiDelegate?.scrollContainer.webView.useCached ?? true
            for item in array {
                if let type = item["ev_type"] as? String, type == "performance" && useCache {
                    // 由于有预加载导致performance数据不准，因此排除useCache的数据
                    return
                }
            }
        }
        if bodyDict != nil {
            guard let body = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
                MailLogger.info("handleEditorHitPoint json transform fail")
                return
            }
            req.body = body
        }
        req.retryNum = 3
        MailDataServiceFactory.commonDataService?.sendHttpRequest(req: req).subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self else { return }
            guard let json = try? JSONSerialization.jsonObject(with: resp.body, options: []) else {
                MailLogger.info("parse resp json fail")
                return
            }
            guard let strJson = json as? [String: Any] else {
                MailLogger.info("json to stringJson fail")
                return
            }
            let dataMap = strJson["data"]
            guard let dataDic = dataMap as? [String: Any],
                  let fileMap = dataDic["succ_files"] as? [String: Any] else {
                MailLogger.info("parse succ_files fail")
                return
            }
        }, onError: { (err) in
            MailLogger.error("http multicopy failed, \(err)")
        }).disposed(by: self.disposeBag)
    }
}
