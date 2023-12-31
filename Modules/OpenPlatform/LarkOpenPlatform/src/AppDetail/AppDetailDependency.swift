//
//  AppDetailDependency.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2022/6/8.
//

import Foundation
import RxSwift
import SwiftyJSON
import LarkAccountInterface
import LarkContainer
import LarkFeatureGating
import LarkSetting
import Photos
import EENavigator
import LarkSDKInterface
import LKCommonsTracker
import LKCommonsLogging
import LarkMessengerInterface
import LarkRustClient
import LarkTab
import LarkUIKit
import RustPB
import UIKit
import LarkOPInterface
import LarkStorage

typealias OpenApp = RustPB.Basic_V1_OpenApp
typealias GetAppDetailRequest = RustPB.Openplatform_V1_GetAppDetailRequest
typealias GetAppDetailResponse = RustPB.Openplatform_V1_GetAppDetailResponse

final class AppDetailUtils: NSObject, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    @ScopedProvider
    var internalDependency: AppDetailInternalDependency?

}

/// 内部依赖封装
final class AppDetailInternalDependency {
    static let logger = Logger.log(AppDetailInternalDependency.self)
    
    private var resolver: UserResolver
    
    private let userService: PassportUserService
    
    private let chatService: ChatService
    
    init(resolver: UserResolver) throws {
        self.resolver = resolver
        
        userService = try resolver.resolve(assert: PassportUserService.self)
        chatService = try resolver.resolve(assert: ChatService.self)
    }
    
    var isFeishuBrand: Bool {
        return userService.isFeishuBrand
    }

    func post(eventName: String, params: [AnyHashable: Any]?) {
        Tracker.post(TeaEvent(eventName, params: params ?? [:]))
    }

    func showDetailOrPush(_ url: URL, from: UIViewController) {
        self.resolver.navigator.showDetailOrPush(
            url,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: from
        )
    }
    
    func buildFileCache(for userId: String) -> LarkOPFileCacheManager {
        var fileCacheManager: LarkOPFileCacheManager
        let path: String = "\(AbsPath.cache.absoluteString)/LarkOpenPlatform/LarkOpenPlatform_\(userId)"
        fileCacheManager = LarkOPFileCacheManager(filePath: path.replacingOccurrences(of: "file://", with: ""))
        fileCacheManager.createDirectoryIfNeeded()
        return fileCacheManager
    }

    func host(for alias: DomainKey) -> String {
        guard let host = DomainSettingManager.shared.currentSetting[alias]?.first, !host.isEmpty else {
            let msg = "host has not been set for alias: \(alias)"
            assertionFailure(msg)
            Self.logger.error(msg)
            return "error.unknown.host"
        }
        return host
    }

    func toChat(_ info: AppDetailChatInfo, completion: ((Bool) -> Void)?) {
        chatService.createP2PChat(
            userId: info.userId,
            isCrypto: false,
            chatSource: nil
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let body = ChatControllerByChatBody(chat: chat)
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
                ]
                var from: NavigatorFrom
                if let f = info.from {
                    from = f
                } else if let f = Navigator.shared.mainSceneWindow?.fromViewController {
                    from = f
                } else {
                    completion?(false)
                    return
                }
                self.resolver.navigator.showAfterSwitchIfNeeded(
                    tab: Tab.feed.url,
                    body: body,
                    context: context,
                    wrap: LkNavigationController.self,
                    from: from
                )
                completion?(true)
            }).disposed(by: info.disposeBag)
    }

    func toChat(_ chatID: String, from: UIViewController) {
        let body = ChatControllerByIdBody(chatId: chatID)
        self.resolver.navigator.showAfterSwitchIfNeeded(
            tab: Tab.feed.url,
            body: body,
            wrap: LkNavigationController.self,
            from: from
        )
    }

    func shareApp(with appId: String, entry: AppDetailShareEntry, from: UIViewController) {
        let appShare = ShareApp(appId: appId, link: entry.applink(with: appId))
        let body = OPShareBody(shareType: .app(appShare), fromType: entry.shareFromType)
        self.resolver.navigator.open(body: body, from: from)
    }
}

enum AppDetailShareEntry {
    case profile
    case gadgetAbout
    case webAppAbout

    var shareFromType: ShareFromType {
        switch self {
        case .profile:
            return .profile
        case .gadgetAbout:
            return .gadgetAbout
        case .webAppAbout:
            return .webAppAbout
        }
    }

    func applink(with appId: String) -> String {
        switch self {
        case .profile:
            return ShareAppLinkBuilder.buildAppShareLink(with: appId, opTracking: shareFromType.opTracking)
        case .gadgetAbout:
            return ShareAppLinkBuilder.buildMicroAppLink(with: appId, opTracking: shareFromType.opTracking)
        case .webAppAbout:
            return ShareAppLinkBuilder.buildWebAppLink(with: appId, opTracking: shareFromType.opTracking)
        }
    }
}

/// AppDetail 相关埋点平移过来。
struct AppDetailMonitorName {
    /// 关于页面埋点
    static let gadget_about_enter = "gadget_about_enter"
    static let gadget_about_show_restart = "gadget_about_show_restart"
    static let gadget_about_tap_restart = "gadget_about_tap_restart"
    static let gadget_about_show_download_failed = "gadget_about_show_download_failed"
    static let gadget_about_tap_download_failed = "gadget_about_tap_download_failed"
}

//// AppDetail 键鼠特效参数值平移过来。
enum AppDetailLayout {
    /// hignlight-corner 高亮圆角值
    static let highLightCorner: CGFloat = 8.0
    /// highLight-common-Height-Icon 高亮图标的通用高度
    static let highLightIconCommonHeight: CGFloat = 44.0
    /// highLight-common-width-Icon 高亮图标的通用宽度
    static let highLightIconCommonWidth: CGFloat = 36.0
}

struct AppDetailChatInfo {
    let userId: String
    var from: UIViewController?
    let disposeBag: DisposeBag
}

extension UIViewController {
    func isWPWindowRegularSize() -> Bool {
        return view.isWPWindowRegularSize()
    }
}

extension UIView {
    func isWPWindowRegularSize() -> Bool {
        return isWPWindowUISizeClass(.regular)
    }
    func isWPWindowUISizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> Bool {
        let lkTraitCollection = window?.lkTraitCollection
        return lkTraitCollection?.horizontalSizeClass == sizeClass
    }
}
