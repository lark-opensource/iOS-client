//
//  NavigatorAssembly.swift
//  ByteView
//
//  Created by panzaofeng on 2020/4/10.
//

import Foundation
import Swinject
import EENavigator
import LarkFoundation
import LarkUIKit
import LarkLocalizations
import LarkReleaseConfig
import LarkAccountInterface
import LarkRustClient
import LarkTab
import LarkAppConfig
import LKCommonsLogging
import LarkGuide
import LarkSceneManager
import MinutesInterface
import Minutes
import MinutesFoundation
import MinutesNetwork
import MinutesNavigator
import MinutesDependency
import LarkSetting
import LarkAssembler


public final class MinutesCoreAssembly: LarkAssemblyInterface {

    static let logger = Logger.log(MinutesCoreAssembly.self, category: "Minutes")

    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        
        user.register(MinutesDependency.self) { r in
            return try MinutesDependencyImpl(resolver: r)
        }
        
        user.register(MinutesAudioRecordService.self) { r in
            _ = try r.resolve(assert: MinutesService.self)
            return MinutesAudioRecordServiceImp()
        }
        user.register(MinutesService.self) { r in
            let service = MinutesServiceImp(resolver: r)
            service.resolver = container
            service.setupMinutes()
            return service
        }
        
        user.register(MinutesAudioRecordService.self) { r in
            _ = try r.resolve(assert: MinutesService.self)
            return MinutesAudioRecordServiceImp()
        }

        user.register(MinutesPodcastService.self) { r in
            _ = try r.resolve(assert: MinutesService.self)
            return MinutesPodcastServiceImp()
        }
        
        container.register(MinutesConfig.self) { r in
            let deviceService = try r.resolve(assert: LarkAccountInterface.DeviceService.self)
            let passportUserService = try r.resolve(assert: LarkAccountInterface.PassportUserService.self)

            let config = MinutesConfig(appID: ReleaseConfig.appIdForAligned,
                                       deviceID: deviceService.deviceId,
                                       session: passportUserService.user.sessionKey ?? "",
                                       locale: LanguageManager.currentLanguage.localeIdentifier,
                                       userAgent: Utils.userAgent,
                                       larkVersion: Utils.appVersion)

            return config
        }

        user.register(MinutesAPI.self) { r in
            let config = try r.resolve(assert: MinutesConfig.self)
            return LarkMinutesAPI(nil, config: config, resolver: r)
        }
    }
    
    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerCommand.mmPushReactionInfo, MinutesOnlinePushHandler.init(resolver:))
        (ServerCommand.mmPushRealtimeSubtitleSentence, MinutesRealTimePushHandler.init(resolver:))
        (ServerCommand.mmPushSummaryStatus, MinutesSummaryPushHandler.init(resolver:))
        (ServerCommand.mmPushSummaryChange, MinutesSummaryPushHandler.init(resolver:))
        (ServerCommand.mmPushSummaryCheck, MinutesSummaryPushHandler.init(resolver:))
        (ServerCommand.mmPushReactionInfoV2, MinutesCCMCommentPushHandler.init(resolver:))
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(MinutesDetailBody.self).factory(MinutesDetailHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MinutesPodcastBody.self).factory(MinutesPodcastHandler.init(resolver:))
        
        Navigator.shared.registerRoute.type(MinutesAudioRecordingBody.self).factory(MinutesAudioRecordingHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MinutesAudioPreviewBody.self).factory(MinutesAudioPreviewHandler.init(resolver:))

        Navigator.shared.registerRoute.match { url in
            var isNative = true
            if let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "vc_mm_ipad_switch")) {
                isNative = settings["isNative"] as? Bool ?? true
            }
            let isMinutesURL = Minutes.isMinutesURL(url)
            Self.logger.info("url info: \(Display.phone), isMinutesURL: \(isMinutesURL)")
            if Display.pad {
                return isNative && isMinutesURL
            } else {
                return isMinutesURL
            }
        }.tester { req in
            req.context["_canOpenInMinutes"] = true
            return true
        }.handle { userResolver, request, response in
            let service = try userResolver.resolve(assert: MinutesService.self)
            let url = request.url
            let context = request.context

            if let minutes = service.openMinutes(url) as? Minutes {
                Self.logger.info("open minutes")
                let podcastTokenList = context[Minutes.podcastTokenListKey] as? [URL] ?? []
                minutes.podcastURLList = podcastTokenList

                var destination: MinutesDestination = .detail
                let queryItems = URLComponents(string: url.absoluteString)?.queryItems

                if let commentId = queryItems?.first(where: { $0.name == "c" })?.value as? String, let contentId = queryItems?.first(where: { $0.name == "cci" })?.value as? String {
                    destination = MinutesDestination.detailComment(commentId, contentId)
                } else if let contentId = queryItems?.first(where: { $0.name == "su" })?.value as? String {
                    destination = MinutesDestination.summaryMention(contentId)
                } else if let from = queryItems?.first(where: { $0.name == "from" })?.value, from == "comment_add" {
                    if let commentId = queryItems?.first(where: { $0.name == "comment_id" })?.value as? String {
                        if let replyId = queryItems?.first(where: { $0.name == "reply_id" })?.value as? String {
                            // reply
                            destination = MinutesDestination.ccmCommentAdd(commentId, replyId)
                        } else {
                            // comment or resolve
                            // resolve
                            destination = MinutesDestination.ccmCommentAdd(commentId, nil)
                        }
                    }
                } else if let from = queryItems?.first(where: { $0.name == "from" })?.value, from == "comment_replay" {
                    if let commentId = queryItems?.first(where: { $0.name == "comment_id" })?.value as? String {
                        if let replyId = queryItems?.first(where: { $0.name == "reply_id" })?.value as? String {
                            // reaction
                            destination = MinutesDestination.ccmCommentAdd(commentId, replyId)
                        }
                    }
                } else {
                    destination = MinutesDestination.detail
                }

                var fromSource: MinutesSource = context[Minutes.fromSourceKey] as? MinutesSource ?? .chatLink
                if let fromItem = queryItems?.first(where: { $0.name == "from_source" })?.value as? String,
                   let sourceItem = MinutesSource(rawValue: fromItem) {
                    fromSource = sourceItem
                }
                let body = MinutesDetailBody(minutes: minutes, source: fromSource, destination: destination)
                response.redirect(body: body)
            } else {
                MinutesCoreAssembly.logger.info("minutes is nil")
                response.end(error: nil)
            }
        }

        Navigator.shared.registerRoute.match { url in
            return isCheckedMinutesTab(url: url)
        }.factory(MinutesHomeHandler.init(resolver:))
        
        Navigator.shared.registerRoute.plain(MinutesHomeTab.minutesHomeTabString)
            .factory(MinutesHomeTabHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MinutesHomeMeBody.self).factory(MinutesHomeMeHandler.init(resolver:))
        
        Navigator.shared.registerRoute.type(MinutesHomeSharedBody.self).factory(MinutesHomeSharedHandler.init(resolver:))
        
        Navigator.shared.registerRoute.type(MinutesHomePageBody.self).factory(MinutesHomePageHandler.init(resolver:))
        
        Navigator.shared.registerRoute.type(MinutesHomeTrashBody.self).factory(MinutesHomeTrashHandler.init(resolver:))
        Navigator.shared.registerRoute.type(MinutesClipBody.self).factory(MinutesClipHandler.init(resolver:))
    }
    
    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            return MinutesLauncherDelegate()
        }, LauncherDelegateRegisteryPriority.middle)
    }

    @available(iOS 13.0, *)
    public func registLarkScene(container: Container) {
        SceneManager.shared.register(config: MinutesScene.self)
    }

    public func registTabRegistry(container: Container) {
        (Tab.minutes, { (urls: [URLQueryItem]?) -> TabRepresentable in
            MinutesTab()
        })
    }
}

private func isCheckedMinutesTab(url: URL) -> Bool {
    if isByteDanceURL(url: url) || isHostFromRemoteSettings(url: url) {
        if url.pathComponents.count == 3 {
            return url.path == "/minutes/me" || url.path == "/minutes/shared" || url.path == "/minutes/home" || url.path == "/minutes/trash"
        } else if url.pathComponents.count == 2 {
            return url.path == "/minutes"
        } else {
            return false
        }
    } else {
        return false
    }
}

private func isByteDanceURL(url: URL) -> Bool {
    guard let host = url.host, !host.isEmpty else { return false }

    let bytedanceHosts: [String] = [
        ".feishu.cn",
        ".feishu-pre.cn",
        ".feishu-staging.cn",
        ".larksuite.com",
        ".larksuite-pre.com",
        ".larksuite-staging.com"
    ]

    for bytedanceHost in bytedanceHosts {
        if host.hasSuffix(bytedanceHost) {
            return true
        } else {
            continue
        }
    }

    return false
}

private func isHostFromRemoteSettings(url: URL) -> Bool {
    guard let host = url.host, !host.isEmpty else { return false }
    return Minutes.isHomeURL(url) || Minutes.isMyURL(url)
}
