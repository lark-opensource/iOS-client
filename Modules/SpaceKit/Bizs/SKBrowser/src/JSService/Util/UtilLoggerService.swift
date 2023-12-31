//
//  UtilLoggerService.swift
//  SpaceKit
//
//  Created by zenghao on 2018/8/9.
//

import Foundation
import WebKit
import SKCommon
import SKFoundation

public final class UtilLoggerService: BaseJSService {
    private lazy var internalPlugin: SKBaseLogPlugin = {
        let plugin = SKBaseLogPlugin()
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        plugin.pluginProtocol = self
        return plugin
    }()
    let logQueue = DispatchQueue(label: "com.bytedance.docs.log")
}

extension UtilLoggerService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return internalPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        internalPlugin.handle(params: params, serviceName: serviceName)
    }

    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
//        11-21 20:44:57.839
        formatter.dateFormat = "MM-DD HH:mm:ss.SSS"
        return formatter
    }

    func handleLog(_ log: String) {
        if log.contains("fileopen pull_data_start") {
            NotificationCenter.default.post(name: Notification.Name.JSLog.pullStart, object: nil, userInfo: ["date": getDateFrom(log)])
            DocsLogger.info("send \(Notification.Name.JSLog.pullStart)")
        } else if log.contains("fileopen pull_data_end") {
            NotificationCenter.default.post(name: Notification.Name.JSLog.pullEnd, object: nil, userInfo: ["date": getDateFrom(log)])
            DocsLogger.info("send \(Notification.Name.JSLog.pullEnd)")
        } else if log.contains("fileopen render_doc_start") {
            NotificationCenter.default.post(name: Notification.Name.JSLog.renderStart, object: nil, userInfo: ["date": getDateFrom(log)])
            DocsLogger.info("send \(Notification.Name.JSLog.renderStart)")
        } else if log.contains("fileopen render_doc_end") {
            NotificationCenter.default.post(name: Notification.Name.JSLog.renderEnd, object: nil, userInfo: ["date": getDateFrom(log)])
            DocsLogger.info("send \(Notification.Name.JSLog.renderEnd)")
        }
    }

    func getDateFrom(_ log: String) -> Date {
        let dateStr = log.components(separatedBy: " ")[0...1].joined(separator: " ")
        return UtilLoggerService.dateFormatter.date(from: dateStr)!
    }
}

extension UtilLoggerService: SKBaseLogPluginProtocol {
    public func didReceiveLog(_ msg: String) {
        let webviewIdendity = String(describing: model?.jsEngine.editorIdentity)
        logQueue.async {
            DocsLogger.info("\(webviewIdendity) js log: \(msg)")
        }
        if DocsSDK.isBeingTest {
            handleLog(msg)
        }
    }
}
