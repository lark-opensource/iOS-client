//
//  MailAssemble.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/15.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import LarkContainer
import LarkSDKInterface
import Swinject
import EENavigator
import LKCommonsLogging
import LarkFoundation
import LarkRustClient
import ByteWebImage
import RxSwift
import MailSDK
import SpaceInterface
import LarkAccountInterface
import LarkUIKit
import LarkAppLinkSDK
import LarkDebugExtensionPoint
import LarkNavigator
import LarkFeatureGating
import LarkNavigation
import AppContainer
import AnimatedTabBar
import LarkMailInterface
import WebBrowser
import BootManager
import LarkTab
import LarkSceneManager
import CookieManager
import LarkAssembler
import RustPB

public final class MailAssemble {
    static let log = Logger.log(MailAssemble.self, category: "MailAssemble")

    public init() {}

    /// 不依赖业务启动就要注入的
    /// - Parameter resolver: resolver description
//    static func baseProvider(resolver: UserResolver) {
//        /// TODO:  @gaoquanze  确认 bug 不复现
//        /// https://meego.feishu.cn/larksuite/issue/detail/6744438
////        if ProviderManager.default.hasRegister(type: DataServiceProxy.self) {
////            return
////        }
//        ProviderManager.default.register(DataServiceProxy.self) {
//            return DataServiceProvider(resolver: resolver)
//        }
//    }

    static func configProvider() {
        /// 用户无关的服务依旧注册到 ProviderManager 单例中
        ProviderManager.default.register(MailSDK.BadgeProxy.self) { () -> MailSDK.BadgeProxy in
            return BadgeProvider.default
        }
        ProviderManager.default.register(ImageProxy.self) { () -> ImageProxy in
            return ImageProvider()
        }
        ProviderManager.default.register(MailSDK.TrackProxy.self) { () -> MailSDK.TrackProxy in
            return TrackProvider()
        }
        ProviderManager.default.register(MailSDK.CommonSettingProxy.self) { () -> MailSDK.CommonSettingProxy? in
            return CommonSettingProvider.shared
        }
        ProviderManager.default.register(TimeFormatProxy.self) { () -> TimeFormatProvider? in
            return TimeFormatProvider()
        }
    }
}


// MARK: --------------------- NEW
extension MailAssemble: LarkAssemblyInterface {
    public func registContainer(container: Container) {
        let user = container.inObjectScope(MailUserScope.userScope)

        user.register(LarkMailService.self) { (resolver) in
//            MailAssemble.baseProvider(resolver: resolver)
            MailAssemble.configProvider()
            /// 尽早初始化 RustService
            _ = try? resolver.resolve(assert: DataServiceProxy.self)
            // use resolver(container.synchronize) instead of r
            return try LarkMailService(
                dependency: LarkMailServiceDependencyImp(resolver: resolver),
                resolver: resolver
            )
        }

        user.register(LarkMailInterface.self) { (resolver) -> LarkMailInterface in
            let _ = try? resolver.resolve(assert: LarkMailService.self) // 确保Mail服务初始化
            return LarkMailInterfaceImp(resolver: resolver)
        }

        user.register(MailUserContext.self) { resolver in
            return try MailUserContext(resolver: resolver)
        }

        /// 用户相关的服务，注册到用户容器中
        user.register(FeatureSwitchProxy.self) { resolver in
            return try FeatureSwitchProvider(resolver: resolver)
        }
        user.register(DataServiceProxy.self) { resolver in
            return DataServiceProvider(resolver: resolver)
        }
        user.register(LocalFileProxy.self) { resolver in
            return LocalFileProvider(resolver: resolver)
        }
        user.register(CalendarProxy.self) { resolver in
            return CalendarProvider(resolver: resolver)
        }
        user.register(ConfigurationProxy.self) { resolver in
            return ConfigurationProvider(resolver: resolver)
        }
        user.register(TranslateLanguageProxy.self) { resolver in
            return try TranslateLanguageProvider(resolver: resolver)
        }
        user.register(GuideServiceProxy.self) { resolver in
            return GuideServiceProvider(resolver: resolver)
        }
        user.register(MyAIServiceProxy.self) { resolver in
            return MyAIServiceProvider(resolver: resolver)
        }
        user.register(ContactPickerProxy.self) { resolver in
            return ContactPickerProvider(resolver: resolver)
        }
        user.register(RouterProxy.self) { resolver in
            return RouterProvider(resolver: resolver)
        }
        user.register(MailForwardProxy.self) { resolver in
            return MailForwardProvider(resolver: resolver)
        }
        user.register(QRCodeAnalysisProxy.self) { resolver in
            return QRCodeAnalysisProvider(resolver: resolver)
        }

        #if CCMMod
        user.register(AttachmentUploadProxy.self) { resolver in
            return CommonUploadProvider(resolver: resolver)
        }
        user.register(AttachmentPreviewProxy.self) { resolver in
            return AttachmentPreviewProvider(resolver: resolver)
        }
        user.register(DriveDownloadProxy.self) { resolver in
            return DriveDownloadProvider(resolver: resolver)
        }
        #endif

        // 注入Lark预加载框架
        user.register(PreloadManagerProxy.self) { _ in
            return PreloadManagerImpl()
        }

        // Mail AppSettings
        user.register(MailSDK.MailSettingConfigProxy.self) { _ in
            return MailSettingConfig()
        }
        
        // MailFeed
        user.register(MailSDK.FeedCardProxy.self) {_ in
            return FeedCardProvider()
        }
    }

    /// 路由注册 Navigator.shared.registerMiddleware Navigator.shared.registerRoute
    public func registRouter(container: Container) {
        // mail Tab
        Navigator.shared.registerRoute
            .plain(Tab.mail.urlString)
            .priority(.high)
            .factory(TabMailViewControllerHandler.init(resolver:))

        // mail send
        Navigator.shared.registerRoute
            .type(MailSendBody.self)
            .factory(MailSendHandler.init(resolver:))

        Navigator.shared.registerRoute
            .regex("^(mailto:|)[+a-zA-Z0-9_.!#$%&'*\\/=^`{|}~-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z0-9]{2,63}$")
            .tester({ _ in return true })
            .handle { (req, res) in
            res.redirect(
                body: MailSendBody(emailAddress: req.url.absoluteString),
                context: req.context
            )
        }

        Navigator.shared.registerRoute
            .regex("^(mailto:).*$")
            .tester({ _ in return true })
            .handle {(req, res) in
                do {
                    let str = req.url.absoluteString


                    let address_pattern = "^(mailto:)[+a-zA-Z0-9_.!#$%&'*\\/=^`{|}~-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z0-9]{2,63}"
                    let address_regex = try NSRegularExpression(pattern: address_pattern)
                    let address_res = address_regex.matches(in: str, range: NSMakeRange(0, str.count))
                    var pure_address = ""
                    var pure_cc = ""
                    var pure_subject = ""
                    var pure_body = ""
                    var pure_bcc = ""
                    if address_res.count > 0 {
                        pure_address = (str as NSString).substring(with: address_res[0].range)
                        if pure_address.hasPrefix("mailto:") {
                            let index = pure_address.index(pure_address.startIndex, offsetBy: 7)
                            pure_address = String(pure_address[index...])
                        }
                    }
                    if let comps = URLComponents(string: req.url.absoluteString), let items = comps.queryItems {
                        if let cc = items.first(where: {$0.name == "cc"})?.value {
                            pure_cc = cc
                        }
                        if let bcc = items.first(where: {$0.name == "bcc"})?.value {
                            pure_bcc = bcc
                        }
                        if let subject = items.first(where: {$0.name == "subject"})?.value {
                            pure_subject = subject
                        }
                        if let body = items.first(where: {$0.name == "body"})?.value {
                            pure_body = body
                        }
                    }
                    res.redirect(
                        body: MailSendBody(emailAddress: pure_address,
                                           subject: pure_subject,
                                           body: pure_body,
                                           originUrl: str,
                                           cc: pure_cc,
                                           bcc: pure_bcc),
                        context: req.context
                    )
                } catch {
                    MailAssemble.log.info("NSRegularExpression err")
                }
            }

        // mail read
        Navigator.shared.registerRoute
            .type(MailMessageListBody.self)
            .factory(MailMessageListHandler.init(resolver:))
        
        // mail setting
        Navigator.shared.registerRoute
            .type(EmailSettingBody.self)
            .factory(MailSettingHandler.init(resolver:))


        Navigator.shared.registerRoute
            .type(MailRecallMessageBody.self)
            .factory(MailRecallHandler.init(resolver:))
        
        // mail feed
        Navigator.shared.registerRoute
            .type(MailFeedReadBody.self)
            .factory(MailFeedReadHandler.init(resolver:))
    }

    public func registBootLoader(container: Container) {
        (LarkMailApplicationDelegate.self, AppContainer.DelegateLevel.default)
    }

    /// 启动任务注册 NewBootManager.regist
    public func registLaunch(container: Container) {
        NewBootManager.register(SetupMailTask.self)
        NewBootManager.register(SetupMaiDelayableTask.self)
    }

    /// 注册launcherDelegate LauncherDelegateRegistery.register
    public func registLauncherDelegate(container: Container) {
        let resolver = container
        (LauncherDelegateFactory { MailLaunchDelegate(resolver: resolver) }, LauncherDelegateRegisteryPriority.middle)
        (LauncherDelegateFactory { CookieServiceDelegate(resolver: resolver) }, LauncherDelegateRegisteryPriority.low)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushNotification, MailNotificationPushHandler.init(resolver:))
        (Command.mailChangePush, MailChangePushHandler.init(resolver:))
        (Command.mailUnreadThreadCountChangePush, MailUnreadThreadCountChangePushHandler.init(resolver:))
        (Command.pushMailOauthStatus, MailAuthStatusPushHandler.init(resolver:))
        (Command.mailStatisticsAggregation, MailStatiticsAggregationHandler.init(resolver:))
        (Command.mailAccountPush, MailAccountPushResponseHandler.init(resolver:))
        (Command.mailSharedAccountChangePush, MailSharedAccountChangePushHandler.init(resolver:))
        (Command.mailChangeAsyncResult, MailBatchChangesEndPushHandler.init(resolver:))
        (Command.mailBatchChangesResultPush, MailBatchChangesResultPushHandler.init(resolver:))
        (Command.mailSyncEventPush, MailSyncEventPushHandler.init(resolver:))
        (Command.pushDynamicNetStatus, DynamicNetStatusHandler.init(resolver:))
        (Command.mailMetricPush, MailMetricsPushHandler.init(resolver:))
        (Command.mailDownloadPush, MailDownloadPushHandler.init(resolver:))
        (Command.mailUploadPush, MailUploadPushHandler.init(resolver:))
        (Command.mailMixedSearchPush, MailMixedSearchPushHandler.init(resolver:))
        (Command.mailSearchContactPush, MailSearchContactPushHandler.init(resolver:))
        (Command.suiteDrivePushDownloadProcess, MailPushDriveDownloadHandler.init(resolver:))
        (Command.mailAddressUpdateNamePush, MailAddressNamePushHandler.init(resolver:))
        (Command.mailPreloadProgressPush, MailPreloadProgressPushHandler.init(resolver:))
        (Command.mailAiTaskStatusPush, MailAITaskStatusPushHandler.init(resolver:))
        (Command.mailGroupMemberCountPush, MailGroupMemberCountPushHandler.init(resolver:))
        (Command.mailDownloadProcessPush, MailDownloadProressPushHandler.init(resolver:))
        (Command.mailClientCleanCachePush, MailCleanCachePushHandler.init(resolver:))
        (Command.mailImapMigrationStatePush, MailIMAPMigrationStatePushHandler.init(resolver:))
        (Command.mailPushFromChange, MailFeedChangePushHandler.init(resolver:))
        (Command.mailPushFollowStatusChange, MailFeedFollowStatusPushHandler.init(resolver:))
    }

    public func registLarkAppLink(container: Container) {
        let resolver = container
       
        // register applink for chat
        LarkAppLinkSDK.registerHandler(path: "/client/mail/feed", handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            MailAssemble.log.info("LoadMailInstance applinkurl \(applink.url)")
            let query = applink.url.queryParameters
            if let feedCardId = query["feedCardId"],
               let fromNotice = query["fromNotice"],
               let fromNoticeInt = Int(fromNotice),
                let service = try? resolver.resolve(assert: LarkMailService.self) {
                MailAssemble.log.info("feedCardId, feedCardId = \(feedCardId), fromNotice = \(fromNotice)")
                service.mail.jumpToFeedMailReadViewController(feedCardId: feedCardId, from: from, fromNotice: fromNoticeInt)
            }
        })
        // register applink for chat side bar
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.approvalMsg, handler: { (applink: AppLink) in
            MailAssemble.log.info("LoadMailInstance applinkurl \(applink.url)")
            guard let from = applink.context?.from() else { return }
            guard let service = try? resolver.resolve(assert: LarkMailService.self) else {
                return
            }
            guard let instanceCode = applink.url.queryParameters["instanceCode"] else {
                return
            }
            MailAssemble.log.info("LoadMailInstanceK applinkcode \(instanceCode)")
            service.mail.goToMailApprovalFromChat(instanceCode: instanceCode, from: from)
        })
        // register applink for chat
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.forwardCard, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let cardId = query["cardId"],
                let ownerId = query["ownerId"],
                let threadId = query["threadId"],
                let service = try? resolver.resolve(assert: LarkMailService.self) {
                MailAssemble.log.info("forward, cardId = \(cardId), ownerid = \(ownerId), threadid=\(threadId)")
                service.mail.jumpToMailMessageListViewController(threadId: threadId, cardId: cardId, ownerId: ownerId, from: from)
            }
        })
        // register applink for chat bot new mail
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.forwardInbox, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let accountId = query["account_id"],
                let messageId = query["message_id"],
                let threadId = query["thread_id"],
                let labelId = query["label_id"],
                let service = try? resolver.resolve(assert: LarkMailService.self) {
                MailAssemble.log.info("forward, account_id = \(accountId), messageId = \(messageId), threadid=\(threadId) labelId=\(labelId)")
                let routerInfo = MailDetailRouterInfo(threadId: threadId,
                                                      messageId: messageId,
                                                      sendMessageId: query["conversation_sent_msg_id"],
                                                      sendThreadId: query["conversation_thread_id"],
                                                      labelId: labelId,
                                                      accountId: accountId,
                                                      cardId: nil,
                                                      ownerId: nil,
                                                      tab: Tab.mail.url,
                                                      from: from,
                                                      statFrom: "bot",
                                                      fromChat: true)
                service.mail.showMailDetail(routerInfo: routerInfo)
            }
            MailRiskEvent.enterMail(channel: .bot)
        })
        // register applink for preview mail to delete
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.deleteMail, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let messageId = query["message_id"],
               let threadId = query["thread_id"],
               let accountId = query["account_id"],
               let service = try? resolver.resolve(assert: LarkMailService.self) {
                let routerInfo = MailDetailRouterInfo(threadId: threadId,
                                                      messageId: messageId,
                                                      sendMessageId: "",
                                                      sendThreadId: "",
                                                      labelId: "",
                                                      accountId: accountId,
                                                      cardId: nil,
                                                      ownerId: "",
                                                      tab: Tab.mail.url,
                                                      from: from,
                                                      statFrom: "deleteMail",
                                                      fromChat: true)
                service.mail.showMailDetail(routerInfo: routerInfo)
            }
            MailRiskEvent.enterMail(channel: .bot)
        })


        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.cardShare, handler: { [weak self] (applink: AppLink) in
            self?.handleMailBotCard(resolver: resolver, applink: applink, action: .shareCard)
        })

        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.cardDelete, handler: { [weak self] (applink: AppLink) in
            self?.handleMailBotCard(resolver: resolver, applink: applink, action: .trash)
        })

        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.cardSpam, handler: { [weak self] (applink: AppLink) in
            self?.handleMailBotCard(resolver: resolver, applink: applink, action: .spam)
        })

        // register applink for chat bot to Setting
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.setting, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let service = try? resolver.resolve(assert: LarkMailService.self) {
                let item = query["item"] ?? ""
                MailAssemble.log.info("forward, item = \(item)")
                service.mail.goSettingPage(from: from, item: item)
            }
        })

        // register applink for mail client token login
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.oauth, handler: { (applink: AppLink) in
            MailAssemble.log.info("[mail_client_token] receive applink")
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            MailAssemble.log.info("[mail_client_token] receive applink: \(applink.url.absoluteString)")
            if let state = query["state"],
                let service = try? resolver.resolve(assert: LarkMailService.self) {
                MailAssemble.log.info("[mail_client_token] receive applink state: \(state)")
                service.mail.handleTriClientOAuth(from: from, state: state, urlString: applink.url.absoluteString)
            }
        })

        // register applink for lark search
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.search, handler: { (applink: AppLink) in
            MailAssemble.log.info("[mail_search] receive applink")
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let accountId = query["accountId"],
                let messageId = query["messageId"],
                let threadId = query["threadId"],
                let service = try? resolver.resolve(assert: LarkMailService.self) {
                let keyword = query["keyword"]
                MailAssemble.log.info("[mail_search] account_id = \(accountId), messageId = \(messageId), threadid=\(threadId)")
                let routerInfo = MailDetailRouterInfo(threadId: threadId,
                                                      messageId: messageId,
                                                      sendMessageId: nil,
                                                      sendThreadId: nil,
                                                      labelId: "SEARCH",
                                                      accountId: accountId,
                                                      cardId: nil,
                                                      ownerId: nil,
                                                      tab: Tab.mail.url,
                                                      from: from,
                                                      statFrom: "search",
                                                      fromChat: false,
                                                      keyword: keyword ?? "")
                service.mail.showMailDetail(routerInfo: routerInfo)
            }
        })
        registerAIAppLink(container: container)
    }
    
    private func registerAIAppLink(container: Container) {
        let resolver = container
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.aiCreateTask, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let taskId = query["id"],
                let service = try? resolver.resolve(assert: LarkMailService.self)  {
                service.mail.aiCreateTask(id: taskId, from: from)
            }
        })
        
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.aiCreateDraft, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let draftId = query["id"],
               let service = try? resolver.resolve(assert: LarkMailService.self)  {
                service.mail.aiCreateDraft(id: draftId, from: from)
            }
            
        })
        LarkAppLinkSDK.registerHandler(path: LarkMailService.RoutePath.aiMarkAllRead, handler: { (applink: AppLink) in
            guard let from = applink.context?.from() else { return }
            let query = applink.url.queryParameters
            if let jsonStr = query["thread_msgs"],
                let jsondata = jsonStr.data(using: .utf8),
                let jsonObj = try? JSONSerialization.jsonObject(with: jsondata, options: []) as? [[String:Any]],
                let service = try? resolver.resolve(assert: LarkMailService.self) {
                service.mail.aiMarkAllRead(msgArray:jsonObj, from: from)
            } else {
                MailAssemble.log.info("[AiScene] all read \(query)")
            }
        })
        // register applink for mail home
        LarkAppLinkSDK.registerHandler(path: "/client/mail/home", handler: { (applink: AppLink) in
            MailAssemble.log.info("LoadMailInstance applinkurl \(applink.url)")
            guard let from = applink.context?.from() else { return }
            guard let service = try? resolver.resolve(assert: LarkMailService.self) else {
                return
            }
            let query = applink.url.queryParameters
            if query["source"] == "embeddedchat" {
                if service.mail.canSwitchToMailTab(from: from) {
                    Container.shared.getCurrentUserResolver().navigator.switchTab(Tab.mail.url, from: from, animated: false)
                }
            } else {
                Container.shared.getCurrentUserResolver().navigator.switchTab(Tab.mail.url, from: from, animated: false)
            }
        })
    }

    private func handleMailBotCard(resolver: Container, applink: AppLink, action: MailSDK.MailBotAction) {
        MailAssemble.log.info("[mail_bot_card] receive applink action: \(action)")
        guard let from = applink.context?.from() else { return }
        let query = applink.url.queryParameters
        if let accountId = query["account_id"],
            let messageId = query["message_id"],
            let threadId = query["thread_id"],
            let service = try? resolver.resolve(assert: LarkMailService.self) {
            MailAssemble.log.info("[mail_bot_card] share account_id = \(accountId), messageId = \(messageId), threadid=\(threadId)")
            let keyword = query["subject"]?.replacingOccurrences(of: "+", with: " ") ?? ""
            let routerInfo = MailDetailRouterInfo(threadId: threadId,
                                                  messageId: messageId,
                                                  sendMessageId: query["conversation_sent_msg_id"],
                                                  sendThreadId: query["conversation_thread_id"],
                                                  labelId: "",
                                                  accountId: accountId,
                                                  cardId: nil,
                                                  ownerId: nil,
                                                  tab: Tab.mail.url,
                                                  from: from,
                                                  statFrom: "bot",
                                                  fromChat: true,
                                                  keyword: keyword)
            service.mail.handleMailBotCard(routerInfo: routerInfo, action: action)
        }
        MailRiskEvent.enterMail(channel: .bot)
    }

    /// 注册URLInterceptor URLInterceptorManager.shared.register
    public func registURLInterceptor(container: Container) {
        // 邮件Tab首页
        (MailHomeBody.patternConfig.pattern, { (url: URL, from) in
            Container.shared.getCurrentUserResolver().navigator.switchTab(Tab.mail.url, from: from, animated: false)
        })


        // 邮件发送
        (MailSendBody.patternConfig.pattern, {(url: URL, from) in
            Container.shared.getCurrentUserResolver().navigator.present(url, from: from, prepare: { $0.modalPresentationStyle = .fullScreen })
        })

        // 邮件Message list
        (MailMessageListBody.patternConfig.pattern, {(url: URL, from) in
            Container.shared.getCurrentUserResolver().navigator.showDetailOrPush(url: url, tab: .mail, from: from)
        })

        // Mail Recall
        (MailRecallMessageBody.patternConfig.pattern, {(url: URL, from) in
            Container.shared.getCurrentUserResolver().navigator.present(url, from: from)
        })
        
        // Mail Feed
        (MailFeedReadBody.patternConfig.pattern, {(url: URL, from) in
            Container.shared.getCurrentUserResolver().navigator.present(url, from: from)
        })
    }

    /// 注册Tab容器 TabRegistry.regist
    public func registTabRegistry(container: Container) {
        (Tab.mail, { (_: (Optional<Array<URLQueryItem>>)) -> TabRepresentable in
            MailTab()
        })
    }

    @available(iOS 13.0, *)
    /// 多scene注册 LarkSceneManager.shared.regist
    public func registLarkScene(container: Container) {
        if #available(iOS 13.0, *) {
            /// 读信页面
            SceneManager.shared.register(config: MailSceneConfig.self)
        }
    }

    /// 注册debug item DebugItem.regist
    public func registDebugItem(container: Container) {
        ({ () in MailDebugItem(resolver: container) }, SectionType.debugTool)
    }
}

@available(iOS 13.0, *)
class MailSceneConfig: SceneConfig {
    static var key: String { "Mail" }
    static func icon() -> UIImage { LarkMailResources.mail_scene_icon }
    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        let body: MailMessageListBody
        let labelId = sceneInfo.userInfo["labelId"]
        let messageId = sceneInfo.userInfo["messageId"]
        let threadId = sceneInfo.userInfo["threadId"]
        let statFrom = "\(sceneInfo.userInfo["statInfo"] ?? "")Scene"
        let cardId = sceneInfo.userInfo["cardId"]
        let ownerId = sceneInfo.userInfo["ownerId"]
        let feedCardId = sceneInfo.userInfo["feedCardId"]
        let feedCardAvatar = sceneInfo.userInfo["feedCardAvatar"]
        body = MailMessageListBody(threadId: threadId ?? "", messageId: messageId ?? "", labelId: labelId ?? "",
                                   accountId: nil, fromScene: true, statFrom: statFrom, cardId: cardId, ownerId: ownerId, feedCardId: feedCardId, feedCardAvatar: feedCardAvatar)
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        Container.shared.getCurrentUserResolver().navigator.push(body: body, from: navi, animated: false)
        return navi
    }
}
