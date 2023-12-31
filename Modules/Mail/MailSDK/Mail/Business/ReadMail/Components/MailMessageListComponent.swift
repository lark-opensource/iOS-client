//
//  MailMessageListComponent.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/12/4.
//

import Foundation
import WebKit

/// html 替换component
protocol MailMessageReplaceComponent {
    // MARK: 替换逻辑
    func getSection(template: MailMessageListTemplate)
    func replaceTemplate(keyword: String, mailItem: MailItem?, messageItem: MailMessageItem) -> String?
}

extension MailMessageReplaceComponent {
    /// 替换模板内容的工具方法。
    func replaceFor(template: String, patternHandler: (String) -> String?) -> String {
        MailMessageListTemplateRender.replaceFor(template: template, patternHandler: patternHandler)
    }
}

/// JS事件处理
protocol MailMessageEventHandleComponent {
    var delegate: MailMessageEventHandleComponentDelegate? { get }
    // MARK: handler
    func handleInvoke(webView: WKWebView, method: MailMessageListJSMessageType, args: [String: Any]) -> Bool
}

protocol MailMessageEventHandleComponentDelegate: AnyObject {
    /// 所属的vc
    func componentViewController() -> UIViewController

    /// 获取数据源
    var currentMailItem: MailItem { get }
}
