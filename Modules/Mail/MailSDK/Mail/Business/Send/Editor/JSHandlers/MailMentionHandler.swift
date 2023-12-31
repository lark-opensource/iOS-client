//
//  MailMentionHandler.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/6/2.
//

import Foundation

// swiftlint:disable operator_usage_whitespace
extension EditorJSService {
    static let mailEditorMentionActive   = EditorJSService(rawValue: "biz.core.atUser.active")
    static let mailEditorMentionDeactive = EditorJSService(rawValue: "biz.core.atUser.deactive")
    static let mailEditorMentionSearch   = EditorJSService(rawValue: "biz.core.atUser.search")
    static let mailEditorMentionClick    = EditorJSService(rawValue: "biz.core.atUser.click")
    static let mailEditorMentionRemove   = EditorJSService(rawValue: "biz.core.atUser.remove")
    static let mailEditorMentionAdd      = EditorJSService(rawValue: "biz.core.atUser.add")
}
// swiftlint:enable operator_usage_whitespace

protocol MailSendEditorMentionDelegate: AnyObject {
    func didMention(keyword: String)
    func deactiveContactlist()
    func didClickContact(name: String,
                         emailAddress: String,
                         userId: String,
                         key: String,
                         rect: CGRect)
    func removeContact(address: String)
    func adjustMentionPostsition(top: CGFloat)
}

class MailMentionHandler: EditorJSServiceHandler {
    weak var mentionDelegate: MailSendEditorMentionDelegate?
    weak var imageHandler: MailImageHandler?

    var handleServices: [EditorJSService] = [.mailEditorMentionActive, .mailEditorMentionDeactive, .mailEditorMentionSearch,
                                             .mailEditorMentionClick, .mailEditorMentionRemove, .mailEditorMentionAdd]

    // js callToNative
    func handle(params: [String: Any], serviceName: String) {
        switch EditorJSService(rawValue: serviceName) {
        case .mailEditorMentionActive:
            mentionDelegate?.didMention(keyword: " ")
            if let top = params["top"] as? CGFloat {
                mentionDelegate?.adjustMentionPostsition(top: top)
            }
        case .mailEditorMentionDeactive:
            mentionDelegate?.deactiveContactlist()
        case .mailEditorMentionSearch:
            let str: String = params["text"] as? String ?? ""
            mentionDelegate?.didMention(keyword: str)
        case .mailEditorMentionClick:
            guard let userDic = params["user"] as? [String: Any] else {
                MailLogger.info("mailEditorMentionClick no user")
                return
            }
            guard let address = userDic["address"] as? String else {
                mailAssertionFailure("must have address")
                return
            }
            let keyStr = params["key"] as? String ?? ""
            var rect = CGRectZero
            if let rectDic = params["rect"] as? [String: CGFloat] {
                rect = CGRect(x: rectDic["x"] ?? 0.0,
                              y: rectDic["y"] ?? 0.0,
                              width: rectDic["width"] ?? 0.0,
                              height: rectDic["height"] ?? 0.0)
            }
            
            mentionDelegate?.didClickContact(name: userDic["username"] as? String ?? "",
                                             emailAddress: address,
                                             userId: userDic["userId"] as? String ?? "",
                                             key: keyStr,
                                             rect: rect)
        case .mailEditorMentionRemove:
            let address = params["address"] as? String ?? ""
            mentionDelegate?.removeContact(address: address)
//        case .mailEditorMentionAdd:
            // 这个应该是用来，多端同步的
            // mentionDelegate?.didMention("long")
        default:
            return
        }
    }
}
