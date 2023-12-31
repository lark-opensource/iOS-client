//
//  DocsManager.swift
//  Docs
//
//  Created by weidong fu on 4/2/2018.
//

import Foundation
import Kingfisher
import LarkRustClient
import LarkRustHTTP
import RxSwift
import LarkAppConfig

public enum LarkOpenEvent {
    /// 路由跳转
    case openURL(_ url: URL, _ controller: UIViewController?)
    case routeChat(chatID: String)
    case none
}

public enum MailUserLifeTimeError: Error {
    /// 改造成用户容器后，原先注册到全局容器的服务为 nil 时都抛这个错误
    case serviceDisposed
}

/// 由Lark提供的能力
/// 目前传递路径Lark<-MailManager<-EditorManager<-DocsBrowserView<-[Service]
public protocol LarkOpenAgent: AnyObject {
    func sendLarkOpenEvent(_ event: LarkOpenEvent)
}

public protocol MailCurrentUserInfoDelegate: AnyObject {
    var userId: String? { get }
    var avatarURL: String? { get }
    var name: String? { get }
    var nameEn: String? { get }
    var mailAddress: String? { get }
    var departmentName: String? { get }
    var tenantId: String? { get }
}

public protocol MailManagerDelegate: MailCurrentUserInfoDelegate, NetworkAuthDelegate, LarkOpenAgent {
    var userDomain: String? { get }
    var token: String? { get }
    var globalWaterMarkIsOn: Bool { get }
    var hasMailTab: Bool { get }
    var isInMailTab: Bool { get }

    func requiredNewBearSession(completion: @escaping(_ session: String?, _ error: Error?) -> Void)

    func mailRequiredToShowUserProfile(_ userId: String, from controller: UIViewController?)
}

extension MailManagerDelegate {
    var globalWaterMarkIsOn: Bool { return true }
    func mailRequiredToShowUserProfile(_ userId: String, from controller: UIViewController?) {}
    func sendLarkOpenEvent(_ event: LarkOpenEvent) {}
}

// MARK: -
class MailManager: NSObject {
    let mailConfig: MailConfig
    weak var delegate: MailManagerDelegate?

    private let userContex: MailUserContext

    // 不建议用init
    init(_ mailConfig: MailConfig, userContext: MailUserContext) {
        self.mailConfig = mailConfig
        self.userContex = userContext
        super.init()
    }

    func refreshUserProfile() {
        guard let dependancy = delegate, let token = dependancy.token else { return }
        injectKingfisherCookie(token: token)
        userContex.editorLoader.preloadEditor()
    }

    func injectKingfisherCookie(token: String) {
        guard let domain = delegate?.userDomain else { mailAssertionFailure("something wrong in domain \(delegate?.userDomain ?? "")"); return }
        var baseURLComponents = domain.split(separator: ".")
        guard !baseURLComponents.isEmpty else {
            mailAssertionFailure("invalid domain \(domain)")
            return
        }
        baseURLComponents.removeFirst()
        // Must have a '.' at the start of the domain to enable cookie login
        let cookieDomain = "https://.\(baseURLComponents.joined(separator: "."))"
        guard let url = URL(string: cookieDomain) else { mailAssertionFailure("fail to get docs domain"); return }
        let properties = [url.cookiePreperties(value: token, forName: "session"),
                          url.cookiePreperties(value: token, forName: "osession"),
                          url.cookiePreperties(value: token, forName: "bear-session")]
        for prop in properties {
            guard let cookie = HTTPCookie(properties: prop) else { mailAssertionFailure("something wrong about the cookie"); return }
            ImageDownloader.default.sessionConfiguration.httpCookieStorage?.setCookie(cookie)
        }
    }
}
