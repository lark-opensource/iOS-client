//
//  AppLinkHandler.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2019/8/25.
//

import Foundation
import Swinject
import EENavigator
import RxSwift
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import LarkNavigator
import LarkContainer

class AppLinkBodyHandler: UserTypedRouterHandler {
    static let logger = Logger.oplog(AppLinkBodyHandler.self, category: "AppLink")

    func handle(_ body: AppLinkBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        handleAppLinkUrl(url: AppLinkBodyHandler.fixedURLForRust(req.url), req: req, res: res)
    }

    func handleAppLinkUrl(url: URL, req: EENavigator.Request, res: EENavigator.Response) {
        Self.logger.info("applink handler start handle applink,path:\(url.path)")
        let fromScene = FromScene.build(context: req.context)
        var appLinkFrom = AppLinkBodyHandler.appLinkFrom(from: fromScene)
        if appLinkFrom == AppLinkFrom.unknown, let from = req.context[FromSceneKey.key] as? String, let fromUrl = URL(string: from), (fromUrl.scheme == "http" || fromUrl.scheme == "https") {
            // from 是 http(s) 地址时，来源于 webview 跳转
            Self.logger.info("applink handler set appLinkFrom webview")
            appLinkFrom = .webview
        }

        var url = url
        // 移除 applink_ex 保留参数
        if url.queryParameters.keys.contains(AppLinkImpl.applink_ex) {
            Self.logger.info("applink handler remove applink_ex")
            url = url.remove(name: AppLinkImpl.applink_ex)
        }
        var appLink = AppLink(url: url, from: appLinkFrom, fromControler: nil, openType: fromScene.appLinkOpenType)
        appLink.context = req.context

        guard let appLinkService = try? userResolver.resolve(assert: AppLinkService.self) else {
            Self.logger.error("AppLink handler have not appLinkService")
            res.end(error: RouterError.notHandled)
            return
        }
        res.wait()
        appLinkService.open(appLink: appLink) { (canOpen) in
            Self.logger.info("AppLink canopen result:\(canOpen)")
            if canOpen {
                res.end(resource: EmptyResource())
            } else {
                res.end(error: RouterError.notHandled)
            }
        }
    }

    static func appLinkFrom(from: FromScene?) -> AppLinkFrom {
        guard let from = from else {
            return .unknown
        }
        if let appLinkFrom = AppLinkFrom(rawValue: from.rawValue) {
            return appLinkFrom
        } else {
            switch from {
            case .micro_app:
                // AppLinkFrom 对外展示的名字统一为 mini_program，需要兼容处理
                return .mini_program
            case .camera_qrcode:
                return .scan
            case .press_image_qrcode, .album_qrcode:
                return .qrcode
            case .single_cardlink, .multi_cardlink, .single_innerlink, .multi_innerlink, .topic_cardlink, .topic_innerlink:
                return .card
            case .message, .p2p_message, .group_message, .thread_topic:
                return .message
            case .multi_task:
                return .multi_task
            default:
                return .unknown
            }
        }
    }

    /// 来自路由系统的 lark 协议被自动移除了 scheme 部分，虽然iOS中能正常解析，
    /// 但是 Rsut 环境下没有 scheme 的URL会解析失败。并且为了保持 AppLink 多端的逻辑一致性，这里对 scheme 进行一次补全。
    static func fixedURLForRust(_ url: URL) -> URL {
        if url.scheme == nil,
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            urlComponents.scheme = Navigator.shared.defaultSchemesBlock().first
            if let url = urlComponents.url {
                return url
            }
        }
        return url
    }
}

fileprivate extension FromScene {
    var appLinkOpenType: OpenType {
        switch self {
        case .appcenter, .appcenter_search:
            return UIDevice.current.userInterfaceIdiom == .pad ? .showDetail : .push
        default:
            return .push
        }
    }
}
