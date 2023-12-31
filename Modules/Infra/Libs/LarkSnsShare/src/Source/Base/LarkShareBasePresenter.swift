//
//  LarkShareWrapper.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/3/13.
//

import UIKit
import Foundation
import AppContainer
import LKCommonsLogging
import EENavigator
import LarkUIKit
#if LarkSnsShare_InternalSnsShareDependency
import BDUGShare
#endif
import LarkSecurityAudit
import ServerPB

#if LarkSnsShare_InternalSnsShareDependency
protocol LarkSnsShareDelegate: class,
                               BDUGWechatShareDelegate,
                               TTWeiboShareDelegate,
                               BDUGQQShareDelegate {}
#else
protocol LarkSnsShareDelegate: AnyObject {}
#endif

/// 分享组件Base
// swiftlint:disable type_body_length
public final class LarkShareBasePresenter: NSObject, LarkShareBaseService, LarkSnsShareDelegate {

    private typealias _Self = LarkShareBasePresenter
    private static let logger = Logger.log(LarkShareBasePresenter.self, category: "lark.sns.share.base.presenter")
    static let loggerKey = "SnsShare.BasePresenter: "
    public static let shared = LarkShareBasePresenter()
    private override init() {}
    // Bundle > LarkSaas
    public var snsConfiguration: SnsConfiguration = BundleSnsConfiguration()
    public weak var delegate: SnsShareDelegate? {
        didSet {
            #if LarkSnsShare_InternalSnsShareDependency
            if self.delegate != nil {
                BDUGWeChatShare.shared().delegate = self
                BDUGWeiboShare.shared().delegate = self
                BDUGQQShare.shared().delegate = self
            } else {
                BDUGWeChatShare.shared().delegate = nil
                BDUGWeiboShare.shared().delegate = nil
                BDUGQQShare.shared().delegate = nil
            }
            #endif
        }
    }

    private func checkAuthority(id: String) -> AuthResult {
        let securityAudit = SecurityAudit()
        var object = ServerPB_Authorization_CustomizedEntity()
        object.id = id
        object.entityType = "SDK"
        let result = securityAudit.checkAuth(permType: .sdkSwitch, object: object)
        return result
    }

    public func checkShareSDKAuthority(snsType: SnsType) -> Bool {
        /// server idl定义如此，逻辑比较奇怪
        var id = "-1"
        switch snsType {
        case .wechat:
            id = String(ServerPB_Authorization_ThridPartySDKAuthEffectType.weChatSdk.rawValue)
        case .qq:
            id = String(ServerPB_Authorization_ThridPartySDKAuthEffectType.qqsdk.rawValue)
        case .weibo:
            id = String(ServerPB_Authorization_ThridPartySDKAuthEffectType.weiBoSdk.rawValue)
        }
        return self.checkAuthority(id: id) != .deny
    }

    public func getShareSdkDenyTipText(snsType: SnsType) -> String {
        var text = ""
        switch snsType {
        case .wechat:
            text = BundleI18n.LarkSnsShare.Lark_Core_UnableShareToWechat_Toast
        case .qq:
            text = BundleI18n.LarkSnsShare.Lark_Core_UnableShareToQQ_Toast
        case .weibo:
            text =  BundleI18n.LarkSnsShare.Lark_Core_UnableShareToWeibo_Toast
        }
        return text
    }

    public func isAvaliable(snsType: SnsType) -> Bool {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat:
            guard self.checkShareSDKAuthority(snsType: .wechat) else { return false }
            registerSnsSDKIfNeeded(snsType: .wechat)
            return BDUGWeChatShare.shared().isAvailable()
        case .qq:
            guard self.checkShareSDKAuthority(snsType: .qq) else { return false }
            registerSnsSDKIfNeeded(snsType: .qq)
            return BDUGQQShare.shared().isAvailable()
        case .weibo:
            guard self.checkShareSDKAuthority(snsType: .weibo) else { return false }
            registerSnsSDKIfNeeded(snsType: .weibo)
            return BDUGWeiboShare.shared().isAvailable()
        }
        #else
        return false
        #endif
    }

    public func wakeup(snsType: SnsType) -> SnsWakeUpResult {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat: return wakeUpWechat()
        case .qq: return wakeUpQQ()
        default: return (false, .notSupported)
        }
        #else
        return (false, .notSupported)
        #endif
    }

    public func sendText(navigatable: EENavigator.Navigatable,
                         snsType: SnsType,
                         snsScenes: SnsScenes?,
                         text: String,
                         customCallbackUserInfo: [AnyHashable: Any] = [:]) {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat where snsScenes == .wechatSpecifiedSession ||
            snsScenes == .wechatSession ||
            snsScenes == .wechatTimeline ||
            snsScenes == .wechatFavorite:
            guard self.checkShareSDKAuthority(snsType: .wechat) else { return }
            registerSnsSDKIfNeeded(snsType: .wechat)
            BDUGWeChatShare.shared().sendText(to: transformWechatScenes(snsScenes!) ?? .session,
                                               withText: text,
                                               customCallbackUserInfo: customCallbackUserInfo)
        case .qq where snsScenes == .qqSpecifiedSession || snsScenes == .qqZone:
            guard self.checkShareSDKAuthority(snsType: .qq) else { return }
            registerSnsSDKIfNeeded(snsType: .qq)
            switch snsScenes {
            case .qqSpecifiedSession:
                BDUGQQShare.shared().sendText(text, withCustomCallbackUserInfo: customCallbackUserInfo)
            case .qqZone:
                assertionFailure("qq空间暂不支持发送纯文本")
            default: break
            }
        case .weibo:
            guard self.checkShareSDKAuthority(snsType: .weibo) else { return }
            registerSnsSDKIfNeeded(snsType: .weibo)
            BDUGWeiboShare.shared().sendText(text, withCustomCallbackUserInfo: customCallbackUserInfo)
        default: assertionFailure("传入的snsType和snsScenes无法匹配，请检查")
        }
        #endif
        /// 海外因为不包含微信、qq、微博等sdk，暂时降级为系统分享
        #if LarkSnsShare_InternationalSnsShareDependency
        presentSystemShareController(navigatable: navigatable, activityItems: [text])
        #endif
    }

    public func sendImage(navigatable: Navigatable,
                          snsType: SnsType,
                          snsScenes: SnsScenes?,
                          image: UIImage,
                          title: String?,
                          description: String?,
                          customCallbackUserInfo: [AnyHashable: Any] = [:]) {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat where snsScenes == .wechatSpecifiedSession ||
            snsScenes == .wechatSession ||
            snsScenes == .wechatTimeline ||
            snsScenes == .wechatFavorite:
            guard self.checkShareSDKAuthority(snsType: .wechat) else { return }
            registerSnsSDKIfNeeded(snsType: .wechat)
            BDUGWeChatShare.shared().sendImage(to: transformWechatScenes(snsScenes!) ?? .session,
                                               with: image,
                                               customCallbackUserInfo: customCallbackUserInfo)
        case .qq where snsScenes == .qqSpecifiedSession || snsScenes == .qqZone:
            guard self.checkShareSDKAuthority(snsType: .qq) else { return }
            registerSnsSDKIfNeeded(snsType: .qq)
            switch snsScenes {
            case .qqSpecifiedSession:
                BDUGQQShare.shared().send(image,
                                          withTitle: title ?? "",
                                          description: description ?? "",
                                          customCallbackUserInfo: customCallbackUserInfo)
            case .qqZone:
                BDUGQQShare.shared().sendImageToQZone(with: image,
                                                      title: title ?? "",
                                                      customCallbackUserInfo: customCallbackUserInfo)
            default: break
            }
        case .weibo:
            guard self.checkShareSDKAuthority(snsType: .weibo) else { return }
            registerSnsSDKIfNeeded(snsType: .weibo)
            BDUGWeiboShare.shared().sendText(description ?? "", with: image, customCallbackUserInfo: customCallbackUserInfo)
        default: assertionFailure("传入的snsType和snsScenes无法匹配，请检查")
        }
        #endif
        /// 海外因为不包含微信、qq、微博等sdk，暂时降级为系统分享
        #if LarkSnsShare_InternationalSnsShareDependency
        presentSystemShareController(navigatable: navigatable, activityItems: [image])
        #endif
    }

    public func sendWebPageURL(navigatable: Navigatable,
                               snsType: SnsType,
                               snsScenes: SnsScenes?,
                               webpageURL: String,
                               thumbnailImage: UIImage,
                               imageURL: String?,
                               title: String,
                               description: String,
                               customCallbackUserInfo: [AnyHashable: Any] = [:]) {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat where snsScenes == .wechatSpecifiedSession ||
            snsScenes == .wechatSession ||
            snsScenes == .wechatTimeline ||
            snsScenes == .wechatFavorite:
            guard self.checkShareSDKAuthority(snsType: .wechat) else { return }
            registerSnsSDKIfNeeded(snsType: .wechat)
            BDUGWeChatShare.shared().sendWebpage(to: transformWechatScenes(snsScenes!) ?? .session,
                                                  withWebpageURL: webpageURL,
                                                  thumbnailImage: thumbnailImage,
                                                  imageURL: imageURL ?? "",
                                                  title: title,
                                                  description: description,
                                                  customCallbackUserInfo: customCallbackUserInfo)
        case .qq where snsScenes == .qqSpecifiedSession || snsScenes == .qqZone:
            guard self.checkShareSDKAuthority(snsType: .qq) else { return }
            registerSnsSDKIfNeeded(snsType: .qq)
            switch snsScenes {
            case .qqSpecifiedSession:
                BDUGQQShare.shared().sendNews(withURL: webpageURL,
                                               thumbnailImage: thumbnailImage,
                                               thumbnailImageURL: imageURL ?? "",
                                               title: title,
                                               description: description,
                                               customCallbackUserInfo: customCallbackUserInfo)
            case .qqZone:
                BDUGQQShare.shared().sendNewsToQZone(withURL: webpageURL,
                                                      thumbnailImage: thumbnailImage,
                                                      thumbnailImageURL: imageURL ?? "",
                                                      title: title,
                                                      description: description,
                                                      customCallbackUserInfo: customCallbackUserInfo)
            default: break
            }
        case .weibo:
            guard self.checkShareSDKAuthority(snsType: .weibo) else { return }
            registerSnsSDKIfNeeded(snsType: .weibo)
            BDUGWeiboShare.shared().sendWebpage(withTitle: title,
                                                 webpageURL: webpageURL,
                                                 thumbnailImage: thumbnailImage,
                                                 description: description,
                                                 customCallbackUserInfo: customCallbackUserInfo)
        default: assertionFailure("传入的snsType和snsScenes无法匹配，请检查")
        }
        #endif
        /// 海外因为不包含微信、qq、微博等sdk，暂时降级为系统分享
        #if LarkSnsShare_InternationalSnsShareDependency
        presentSystemShareController(navigatable: navigatable, activityItems: [webpageURL])
        #endif
    }

    public func sendMiniProgram(navigatable: Navigatable,
                                snsType: SnsType,
                                snsScenes: SnsScenes?,
                                title: String,
                                webPageURLString: String,
                                miniProgramUserName: String,
                                miniProgramPath: String,
                                launchMiniProgram: Bool,
                                thumbnailImage: UIImage,
                                description: String) {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat where snsScenes == .wechatSpecifiedSession || snsScenes == .wechatSession:
            guard self.checkShareSDKAuthority(snsType: .wechat) else { return }
            registerSnsSDKIfNeeded(snsType: .wechat)
            BDUGWeChatShare.shared().sendMiniProgram(
                to: transformWechatScenes(snsScenes!) ?? .session,
                thumbnailImage: thumbnailImage,
                title: title,
                description: description,
                miniProgramUserName: miniProgramUserName,
                miniProgramPath: miniProgramPath,
                webPageURLString: webPageURLString,
                launchMiniProgram: launchMiniProgram
            )
        default: assertionFailure("传入的snsType和snsScenes无法匹配，请检查")
        }
        #endif
        /// 海外因为不包含微信、qq、微博等sdk，暂时降级为系统分享
        #if LarkSnsShare_InternationalSnsShareDependency
        presentSystemShareController(navigatable: navigatable, activityItems: [webPageURLString])
        #endif
    }

    public func registerSnsSDKIfNeeded(snsType: SnsType) {
        #if LarkSnsShare_InternalSnsShareDependency
        switch snsType {
        case .wechat:
            guard let appID = snsConfiguration.snsAppIDMapping[.wechat] else {
                Self.logger.error("\(Self.loggerKey) failed to get wechat app ID")
                return
            }
            BDUGWeChatShare.register(withID: appID, universalLink: snsConfiguration.universalLink)
            Self.logger.error("\(Self.loggerKey) wechat share registered, appID: \(appID)")
        case .weibo:
            guard let appID = snsConfiguration.snsAppIDMapping[.weibo] else {
                Self.logger.error("\(Self.loggerKey) failed to get weibo app ID")
                return
            }
            BDUGWeiboShare.register(withID: appID, universalLink: snsConfiguration.universalLink)
            Self.logger.error("\(Self.loggerKey) weibo share registered, appID: \(appID)")
        case .qq:
            guard let appID = snsConfiguration.snsAppIDMapping[.qq] else {
                Self.logger.error("\(Self.loggerKey) failed to get qq app ID")
                return
            }
            BDUGQQShare.register(withID: appID, universalLink: snsConfiguration.universalLink)
            Self.logger.error("\(Self.loggerKey) qq share registered, appID: \(appID)")
        }
        #endif
    }

    @discardableResult
    public func handleOpenURL(_ url: URL) -> Bool {
        #if LarkSnsShare_InternalSnsShareDependency
        if self.checkShareSDKAuthority(snsType: .wechat),
           BDUGWeChatShare.handleOpen(url) {
            return true
        }
        if self.checkShareSDKAuthority(snsType: .qq),
           BDUGQQShare.handleOpen(url) {
            return true
        }
        if self.checkShareSDKAuthority(snsType: .weibo),
           BDUGWeiboShare.handleOpen(url) {
            return true
        }
        return false
        #elseif LarkSnsShare_InternationalSnsShareDependency
        return false
        #else
        return false
        #endif
    }

    @discardableResult
    public func handleOpenUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        #if LarkSnsShare_InternalSnsShareDependency
        if self.checkShareSDKAuthority(snsType: .wechat),
           BDUGWeChatShare.handleOpenUniversalLink(userActivity) {
            return true
        }
        if self.checkShareSDKAuthority(snsType: .weibo),
           BDUGWeiboShare.handleOpenUniversalLink(userActivity) {
            return true
        }
        if let universalLinkURL = userActivity.webpageURL,
           self.checkShareSDKAuthority(snsType: .qq),
           BDUGQQShare.handleOpenUniversallink(universalLinkURL) {
            return true

        }
        return false
        #elseif LarkSnsShare_InternationalSnsShareDependency
        return false
        #else
        return false
        #endif
    }

    public func presentSystemShareController(
        navigatable: Navigatable,
        activityItems: [Any],
        presentFrom: UIViewController? = nil,
        popoverMaterial: PopoverMaterial? = nil,
        completionHandler: UIActivityViewController.CompletionWithItemsHandler? = nil
    ) {
        guard let presentFrom = presentFrom ?? navigatable.mainSceneTopMost else {
            return
        }
        let systemShareController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        systemShareController.completionWithItemsHandler = completionHandler
        /// 系统bug，放大缩小图像页面“取消”后，导致联系人列表点“取消”无响应，暂时去掉该项, add by hujinzang, 2021-04-25
        systemShareController.excludedActivityTypes = [.assignToContact]
        if Display.pad {
            if let popover = systemShareController.popoverPresentationController {
                popover.sourceView = popoverMaterial?.sourceView ?? presentFrom.view
                popover.permittedArrowDirections = popoverMaterial?.direction ?? .down
                popover.sourceRect = popoverMaterial?.sourceRect ??
                    CGRect(x: presentFrom.view.frame.width / 2, y: presentFrom.view.frame.height - 10, width: 30, height: 30)
            }
        }
        presentFrom.present(systemShareController, animated: true, completion: nil)
    }

    // MARK: - App Share CallBack
    #if LarkSnsShare_InternalSnsShareDependency
    public func weChatShare(
        _ weChatShare: BDUGWeChatShare?,
        sharedWithError error: Error?,
        customCallbackUserInfo: [AnyHashable: Any]? = [:]
    ) {
        if let err = error {
            _Self.logger.error("[LarkSnsShare] wechat sdk share callback `failed`, error = \(err.localizedDescription)")
        } else {
            _Self.logger.error("[LarkSnsShare] wechat sdk share callback `success`")
        }
        delegate?.wechatWrapperCallback(wrapper: self, error: error, customCallbackUserInfo: customCallbackUserInfo)
    }

    public func weiboShare(
        _ weiboShare: BDUGWeiboShare?,
        sharedWithError error: Error?,
        customCallbackUserInfo: [AnyHashable: Any]? = [:]
    ) {
        if let err = error {
            _Self.logger.error("[LarkSnsShare] weibo sdk share callback `failed`, error = \(err.localizedDescription)")
        } else {
            _Self.logger.error("[LarkSnsShare] weibo sdk share callback `success`")
        }
        delegate?.weiboWrapperCallback(wrapper: self, error: error, customCallbackUserInfo: customCallbackUserInfo)
    }

    public func qqShare(
        _ qqShare: BDUGQQShare?,
        sharedWithError error: Error?,
        customCallbackUserInfo: [AnyHashable: Any]? = [:]
    ) {
        if let err = error {
            _Self.logger.error("[LarkSnsShare] qq sdk share callback `failed`, error = \(err.localizedDescription)")
        } else {
            _Self.logger.error("[LarkSnsShare] qq sdk share callback `success`")
        }
        delegate?.qqWrapperCallback(wrapper: self, error: error, customCallbackUserInfo: customCallbackUserInfo)
    }
    #endif
}
// swiftlint:enable type_body_length

private extension LarkShareBasePresenter {
    #if LarkSnsShare_InternalSnsShareDependency
    func wakeUpWechat() -> SnsWakeUpResult {
        guard self.checkShareSDKAuthority(snsType: .wechat) else { return (false, .sdkWakeupFailed) }
        registerSnsSDKIfNeeded(snsType: .wechat)
        guard BDUGWeChatShare.shared().isAvailable() else { return (false, .notInstalled) }
        let wakeupSuccess = BDUGWeChatShare.openWechat()
        return (wakeupSuccess, wakeupSuccess ? nil : .sdkWakeupFailed)
    }

    func wakeUpQQ() -> SnsWakeUpResult {
        guard self.checkShareSDKAuthority(snsType: .qq) else { return (false, .sdkWakeupFailed) }
        registerSnsSDKIfNeeded(snsType: .qq)
        guard BDUGQQShare.shared().isAvailable() else { return (false, .notInstalled) }
        let wakeupSuccess = BDUGQQShare.openQQ()
        return (wakeupSuccess, wakeupSuccess ? nil : .sdkWakeupFailed)
    }

    func transformWechatScenes(_ snsScenes: SnsScenes) -> BDUGWechatShareScene? {
        switch snsScenes {
        case .wechatSession: return .session
        case .wechatSpecifiedSession: return .specifiedSession
        case .wechatTimeline: return .timeline
        case .wechatFavorite: return .favorite
        default: return nil
        }
    }
    #endif
}
