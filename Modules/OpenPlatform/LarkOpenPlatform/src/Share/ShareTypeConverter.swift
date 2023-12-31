//
//  ShareTypeConverter.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2021/1/10.
//

import Foundation
import LarkShareContainer
import LarkFeatureGating
import LarkContainer
import LarkSnsShare
import LarkModel
import LarkLocalizations
import LarkSetting
import LKCommonsLogging
import LarkOPInterface
import OPSDK

/// share 相关 AppLink 创建。长期需要 AppLink 业务域提供标准化生成接口，并推进支持 applink 域名下发。
struct ShareAppLinkBuilder {
    static let logger = Logger.log(ShareAppLinkBuilder.self, category: "ShareAppLinkBuilder")

    enum AppLinkPath: String {
        case appShare = "/client/app_share/open"
        case microApp = "/client/mini_program/open"
        case webApp = "/client/web_app/open"
    }

    static private var domain: String {
        guard let applinkDomain = DomainSettingManager.shared.currentSetting["applink"]?.first else {
            // 理论上不会出现这个情况，这里是纯语法上的兜底写法，留下日志即可 https://bytedance.feishu.cn/docx/doxcnDtWgIn1eKcstzoRv21xXAg
            logger.error("invalid applink domain settings")
            assertionFailure("invalid applink domain settings")
            return ""
        }
        logger.info("share applink domain is \(applinkDomain)")
        return applinkDomain
    }

    public static func buildAppShareLink(with appId: String, opTracking: String) -> String {
        return "https://\(domain)\(AppLinkPath.appShare.rawValue)?appId=\(appId)&op_tracking=\(opTracking)"
    }

    public static func buildMicroAppLink(with appId: String, opTracking: String) -> String {
        return "https://\(domain)\(AppLinkPath.microApp.rawValue)?appId=\(appId)&op_tracking=\(opTracking)"
    }

    public static func buildWebAppLink(with appId: String, opTracking: String) -> String {
        return "https://\(domain)\(AppLinkPath.webApp.rawValue)?appId=\(appId)&op_tracking=\(opTracking)"
    }
}

extension ShareTabType {
    /// 是否不用处理 content，可以直接跳过
    var skipContent: Bool {
        switch self {
        case .viaChat:
            return true
        case .viaLink, .viaQRCode:
            return false
        }
    }

    var channelName: String {
        switch self {
        case .viaChat:
            return "chat"
        case .viaLink:
            return "link"
        case .viaQRCode:
            return "qrcode"
        }
    }

    func tabName(for shareType: ShareType) -> String {
        switch (self, shareType) {
        case (.viaChat, .app):
            return BundleI18n.OpenPlatformShare.OpenPlatform_Share_AppCardTab
        case (.viaChat, .appPage):
            return BundleI18n.OpenPlatformShare.OpenPlatform_Share_AppPageCardTtl
        case (.viaChat, .h5):
            return BundleI18n.OpenPlatformShare.OpenPlatform_ShareWebApp_SelChatTab
        case (.viaLink, .app):
            return BundleI18n.OpenPlatformShare.OpenPlatform_Share_AppLinkTab
        case (.viaLink, .appPage):
            return BundleI18n.OpenPlatformShare.OpenPlatform_Share_AppPageLinkTtl
        case (.viaLink, .h5):
            return BundleI18n.OpenPlatformShare.OpenPlatform_ShareWebApp_PreviewLink
        case (.viaQRCode, .app):
            return BundleI18n.OpenPlatformShare.OpenPlatform_Share_QrCodeTab
        case (.viaQRCode, .appPage):
            return BundleI18n.OpenPlatformShare.OpenPlatform_Share_AppPageQrTtl
        case (.viaQRCode, .h5):
            return BundleI18n.OpenPlatformShare.OpenPlatform_ShareWebApp_PreviewQrCode
        }
    }
}

extension ViaChatChooseConfig {
    /// 默认的 chat 列表配置
    static var shareConfig: ViaChatChooseConfig {
        return ViaChatChooseConfig(
            allowCreateGroup: true,
            multiSelect: false,
            ignoreSelf: false,
            ignoreBot: false,
            needSearchOuterTenant: false,
            selectType: .all,
            showInputView: true
        )
    }
}

extension GetShareAppInfoResponse {
    var commonInfo: CommonInfo {
        let languageId = LanguageManager.currentLanguage.rawValue.lowercased()
        return CommonInfo(
            name: i18nNames[languageId] ?? name ?? "",
            description: i18nDescs[languageId] ?? desc ?? "",
            iconResource: .key(avatarKey ?? "")
        )
    }
}

extension OPShareBody {
    /// 分享的 appId
    var appId: String {
        switch shareType {
        case let .app(appShare):
            return appShare.appId
        case let .appPage(appPageShare):
            return appPageShare.appId
        default:
            return ""
        }
    }
    
    var monitorData: [String: String] {
        return [
            "app_id": appId,
            "op_tracking": opTracking
        ]
    }

    /// 分享原始链接
    var originLink: String {
        switch shareType {
        case let .app(appShare):
            if let overrideLink = appShare.link {
                return overrideLink
            } else {
                return ShareAppLinkBuilder.buildAppShareLink(with: appShare.appId, opTracking: opTracking)
            }
        case let .appPage(appPageShare):
            return appPageShare.url
        case let .h5(shareH5Content):
            return shareH5Content.link
        }
    }

    var shareAppCardType: ShareAppCardType {
        switch shareType {
        case .app:
            return .app(appID: appId, url: originLink)
        case let .appPage(appPageShare):
            return .appPage(
                appID: appId,
                title: appPageShare.title,
                iconToken: appPageShare.iconKey,
                url: appPageShare.url,
                appLinkHref: appPageShare.applinkHref,
                options: appPageShare.options
            )
        default:
            return .unknown
        }
    }

    private var thirdShareLinkBizId: String {
        switch shareType {
        case .app:
            return "lark.container.app.share.link"
        case .appPage:
            return "lark.container.app_page.share.link"
        case .h5:
            return "lark.container.web.share.link"
        }
    }

    private var thirdShareQRCodeBizId: String {
        switch shareType {
        case .app:
            return "lark.container.app.share.qrcode"
        case .appPage:
            return "lark.container.app_page.share.qrcode"
        case .h5:
            return "lark.container.web.share.qrcode"
        }
    }

    func makeTabContentMaterial(
        tabType: ShareTabType,
        shortLink: String?,
        copyCompletion: (() -> Void)? = nil,
        saveCompletion: ((Bool) -> Void)? = nil
    ) -> TabContentMeterial {
        guard let shortLink = shortLink else { return .none }
        switch tabType {
        case .viaChat:
            assertionFailure()
            return .none
        case .viaLink:
            let viaLink = linkContent(with: shortLink, copyCompletion: copyCompletion)
            return .success(.viaLink(viaLink))
        case .viaQRCode:
            let viaQRCode = qrCodeContent(with: shortLink, saveCompletion: saveCompletion)
            return .success(.viaQRCode(viaQRCode))
        }
    }

    private func linkContent(
        with shortLink: String,
        copyCompletion: (() -> Void)?,
        shareCompletion: ((ShareResult, LarkShareItemType) -> Void)? = nil
    ) -> SuccessStatusMaterial.ViaLink {
        var content: String
        switch shareType {
        case .h5:
            content = BundleI18n.OpenPlatformShare.OpenPlatform_ShareWebApp_PreviewLinkContent(url: shortLink)
        default:
            content =
            BundleI18n.OpenPlatformShare.OpenPlatform_Share_SharePlaceholder(link: shortLink)
        }
        return SuccessStatusMaterial.ViaLink(
            thirdShareBizId: thirdShareLinkBizId,
            thirdShareTitle: BundleI18n.OpenPlatformShare.OpenPlatform_Share_ShareExternalDesc(),
            link: shortLink,
            content: content,
            expiredTip: nil,
            tip: nil,
            copyCompletion: copyCompletion,
            shareCompletion: shareCompletion
        )
    }

    private func qrCodeContent(
        with shortLink: String,
        saveCompletion: ((Bool) -> Void)?,
        shareCompletion: ((ShareResult, LarkShareItemType) -> Void)? = nil
    ) -> SuccessStatusMaterial.ViaQRCode {
        return SuccessStatusMaterial.ViaQRCode(
            thirdShareBizId: thirdShareQRCodeBizId,
            thirdShareTitle: BundleI18n.OpenPlatformShare.OpenPlatform_Share_ShareExternalDesc(),
            link: shortLink,
            expiredTip: nil,
            tip: BundleI18n.OpenPlatformShare.OpenPlatform_Share_QrCodeDesc(),
            saveCompletion: saveCompletion,
            shareCompletion: shareCompletion
        )
    }
}

extension LifeCycleEvent {
    var eventLogInfo: String {
        switch self {
        case .initial:
            return "initial"
        case .willAppear:
            return "willAppear"
        case .didAppear:
            return "didAppear"
        case .willDisappear:
            return "willDisappear"
        case .didDisappear:
            return "didDisappear"
        case .switchTab(target: let target):
            return "switchTab: \(target.rawValue)"
        case .clickClose:
            return "clickClose"
        case .clickCopyForLink:
            return "clickCopyForLink"
        case .clickSaveForQRCode:
            return "clickSaveForQRCode"
        case .clickShare:
            return "clickShare"
        case .shareSuccess:
            return "shareSuccess"
        case .shareFailure:
            return "shareFailure"
        }
    }
}
