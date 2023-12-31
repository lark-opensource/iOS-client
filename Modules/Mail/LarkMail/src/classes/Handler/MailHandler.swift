//
//  MailHandler.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/19.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkContainer
import LarkModel
import Swinject
import RxSwift
import LarkUIKit
import LarkRustClient
import EENavigator
import MailSDK
import LKCommonsLogging
import LarkFeatureGating
import LarkNavigation
import AnimatedTabBar
import LarkTab
import WebBrowser
import LarkNavigator

// 邮件Tab
final class TabMailViewControllerHandler: UserRouterHandler {

    static func compatibleMode() -> Bool { MailUserScope.userScopeCompatibleMode }

    func handle(req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: LarkMailService.self)
        let controller = service.factory.createMailTabController()
        res.end(resource: controller)
    }
}

// 邮件发送
final class MailSendHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { MailUserScope.userScopeCompatibleMode }

    func handle(_ body: MailSendBody, req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: LarkMailService.self)
        
        if service.hasMailTab {
            service.mail.showSendMail(emailAddress: body.emailAddress,
                                      subject: body.subject,
                                      body: body.body,
                                      cc: body.cc,
                                      bcc: body.bcc,
                                      originUrl: body.originUrl,
                                      from: req.from)
            res.end(resource: EmptyResource())
        } else {
            if let scheme = req.url.lf.base.scheme, scheme == "mailto" {
                // 兼容未开fg而在toHttpUrl里面转换过mailto的case
                UIApplication.shared.open(req.url)
                res.end(resource: EmptyResource())
            } else if !body.emailAddress.isEmpty {
                var urlStr = body.emailAddress
                if !body.subject.isEmpty || !body.body.isEmpty {
                    urlStr = body.originUrl
                }
                if !urlStr.lowercased().hasPrefix("mailto") {
                    urlStr = "mailto:\(urlStr)"
                }
                if let url = URL(string: urlStr) {
                    UIApplication.shared.open(url)
                }
                res.end(resource: EmptyResource())
            } else {
                let mailToScheme = "mailto:"
                var redirectURL: URL?
                let urlStr = req.url.absoluteString
                if urlStr.hasPrefix(mailToScheme),
                   let index = urlStr.index(urlStr.startIndex, offsetBy: mailToScheme.count, limitedBy: urlStr.endIndex) {
                    let subURL = String(urlStr[index...])
                    // 保持原有逻辑 没有显式mailto协议头的用web打开地址
                    redirectURL = URL(string: subURL.hasPrefix(mailToScheme) ? "" : "http://" + subURL)
                    res.redirect(
                        body: WebBody(url: redirectURL ?? req.url),
                        context: req.context
                    )
                } else {
                    res.end(resource: EmptyResource())
                }
            }
        }
    }
}

// 邮件阅读
final class MailMessageListHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { MailUserScope.userScopeCompatibleMode }

    func handle(_ body: MailMessageListBody, req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: LarkMailService.self)
        let statFrom = body.statFrom.isEmpty ? "notification" : body.statFrom
        // SendToChat 需要走不同的通道
        if let cardId = body.cardId, let ownerId = body.ownerId {
            service.mail.jumpToMailMessageListViewController(threadId: body.threadId,
                                                             cardId: cardId,
                                                             ownerId: ownerId,
                                                             from: req.from)
        } else if let feedCardId = body.feedCardId, !feedCardId.isEmpty {
            service.mail.jumpToFeedMailReadViewController(
                feedCardId: feedCardId,
                from: req.from,
                avatar: body.feedCardAvatar ?? "",
                fromScene: body.fromScene
            )
        } else {
            let routerInfo = MailDetailRouterInfo(threadId: body.threadId,
                                                  messageId: body.messageId,
                                                  sendMessageId: nil,
                                                  sendThreadId: nil,
                                                  labelId: body.labelId,
                                                  accountId: body.accountId,
                                                  cardId: body.cardId,
                                                  ownerId: body.ownerId,
                                                  tab: Tab.mail.url,
                                                  from: req.from,
                                                  multiScene: body.fromScene,
                                                  statFrom: statFrom)
            service.mail.showMailDetail(routerInfo: routerInfo)
        }
        MailRiskEvent.enterMail(channel: .notification)
        res.end(resource: EmptyResource())
    }
}

// 邮件设置
final class MailSettingHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { MailUserScope.userScopeCompatibleMode }

    func handle(_ body: EmailSettingBody, req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: LarkMailService.self)
        service.mail.goSettingPage(from: req.from)
        res.end(resource: EmptyResource())
    }
}

final class MailRecallHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { MailUserScope.userScopeCompatibleMode }

    func handle(_ body: MailRecallMessageBody, req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: LarkMailService.self)
        service.mail.showRecallAlert(tab: Tab.mail.url, from: req.from)
        res.end(resource: EmptyResource())
    }
}

// 邮件进Feed
final class MailFeedReadHandler: UserTypedRouterHandler {
    
    static func compatibleMode() -> Bool { MailUserScope.userScopeCompatibleMode }
    
    func handle(_ body: MailFeedReadBody, req: EENavigator.Request, res: Response) throws {
        let service = try userResolver.resolve(assert: LarkMailService.self)
        service.mail.jumpToFeedMailReadViewController(feedCardId:body.feedCardId, name:body.name, address: body.mail, from:req.from, avatar: body.avatar, fromNotice: body.fromNotice)
    }
}
