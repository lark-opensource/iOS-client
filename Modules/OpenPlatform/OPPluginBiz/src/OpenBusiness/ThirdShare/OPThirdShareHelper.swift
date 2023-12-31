//
//  OPThirdShareHelper.swift
//  EEMicroAppSDK
//
//  Created by yi on 2021/3/27.
//
// 分享UI处理类，跟随share API的生命周期

import Foundation
import OPFoundation
import LarkUIKit
import LarkBadge
import LKCommonsLogging
import LarkReleaseConfig
import UniverseDesignIcon
import UniverseDesignColor

final public class OPThirdShareHelper: NSObject {
    static let logger = Logger.log(OPThirdShareHelper.self, category: "EEMicroApp")
    public static let shareChannelWX = "wx"
    public static let shareChannelWXTimeLine = "wx_timeline"
    public static let shareChannelInApp = "in_app"
    public static let shareChannelMore = "system"

    //  菜单功能使用对象
    //  菜单对接同学：liuyang.apple
    /// 菜单的操作句柄
    var menuHandler: MenuPanelOperationHandler?

    public class func isLark() -> Bool {
        return ReleaseConfig.isLark
    }

    // 微信好友分享 trace id
    public class func wxTraceID() -> String {
        return "lark.op.wx"
    }

    // 微信朋友圈分享的trace id
    public class func wxTimeLineTraceID() -> String {
        return "lark.op.wx_timeline"
    }

    // 更多系统分享
    public class func shareMoreTraceID() -> String {
        return "lark.op.system"
    }


    /// 展示菜单面板
    public func share(
        container: UIViewController,
        appID: String,
        channelType: NSArray,
        contentType: String,
        url: String,
        title: String,
        content: String,
        imageData: NSData,
        successHandler: (() -> Void)?,
        failedHandler: ((Error?) -> Void)?
    ) {
        Self.logger.info("OPThirdShareHelper share info,channelType: \(channelType.map{$0}),contentType: \(contentType),appId: \(appID)")
        if channelType.count > 1 {
            let path = !appID.isEmpty ? Path().raw("app_id.\(appID)") : Path().raw("js_api_share")
            let sourceView = UIView(frame: CGRect.zero)
            menuHandler = MenuPanelHelper.getMenuPanelHandler(in: container, for: .traditionalPanel)
            let menuItemModels = collectionMenuItemModels(
                controller: container,
                appID: appID,
                channelType: channelType,
                contentType: contentType,
                url: url,
                title: title,
                content: content,
                imageData: imageData,
                successHandler: successHandler,
                failedHandler: failedHandler
            ) // 设置菜单数据模型
            if menuItemModels.count < 1 {
                Self.logger.error("OPThirdShareHelper share menuItemModels invalid")
                let error = NSError(
                    domain: "OPThirdShareHelper",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey : "menuItemModels invalid"]
                )
                failedHandler?(error)
                return
            }
            menuHandler?.resetItemModels(with: menuItemModels)
            Self.logger.info("OPThirdShareHelper show more panel")
            menuHandler?.show(
                from: .init(sourceView: sourceView),
                parentPath: MenuBadgePath(path: path),
                animation: true,
                complete: nil
            )
        } else {
            guard let channel = channelType.firstObject as? String else {
                Self.logger.error("OPThirdShareHelper share channel invalid")
                let error = NSError(
                    domain: "OPThirdShareHelper",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey : "channel invalid"]
                )
                failedHandler?(error)
                return
            }
            var traceId = ""
            if channel == Self.shareChannelWX {
                traceId = Self.wxTraceID()
            } else if channel == Self.shareChannelWXTimeLine {
                traceId = Self.wxTimeLineTraceID()
            } else if channel == Self.shareChannelMore {
                traceId = Self.shareMoreTraceID()
            }
            Self.snsShare(
                controller: container,
                appID: appID,
                channel: channel,
                traceId: traceId,
                contentType: contentType,
                url: url,
                title: title,
                content: content,
                imageData: imageData,
                successHandler: nil,
                failedHandler: nil
            )
            successHandler?()
        }
    }

    // 分享菜单数据源
    private func collectionMenuItemModels(
        controller: UIViewController,
        appID: String,
        channelType: NSArray ,
        contentType: String,
        url: String,
        title: String,
        content: String,
        imageData: NSData,
        successHandler: (() -> Void)?,
        failedHandler: ((Error?) -> Void)?
    ) -> [MenuItemModelProtocol] {
        guard let webShareTitle = BDPI18n.openPlatform_Share_Chat,
                let wxTitle = BDPI18n.openPlatform_Share_WeChat,
                let momentTitle = BDPI18n.openPlatform_Share_WeChat_Moments,
                let moreTitle = BDPI18n.openPlatform_AppCenter_MoreCategory else {
            Self.logger.error("OPThirdShareHelper collectionMenuItemModels BDPI18n invalid")
            let error = NSError(
                domain: "OPThirdShareHelper",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey : "BDPI18n invalid"]
            )
            failedHandler?(error)
            return []
        }

        let webShareImage = UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN1)
        let wxImage = UDIcon.wechatColorful
        let momentImage = UDIcon.wechatFriendColorful
        let moreImage = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1)

        // 分享到会话
        let webShareImageModel = MenuItemImageModel(
            normalForIPhonePanel: webShareImage,
            normalForIPadPopover: webShareImage,
            renderMode: .alwaysOriginal
        )
        let webShareAction: MenuItemModel.MenuItemAction = { (_) in
            Self.logger.info("OPThirdShareHelper share in app click")
            Self.snsShare(
                controller: controller,
                appID: appID,
                channel: Self.shareChannelInApp,
                traceId: "",
                contentType: contentType,
                url: url,
                title: title,
                content: content,
                imageData:imageData,
                successHandler: successHandler,
                failedHandler: failedHandler
            )
        }
        let webShareMenuItem = MenuItemModel(
            title: webShareTitle,
            imageModel: webShareImageModel,
            itemIdentifier: "share",
            badgeNumber: 0,
            autoClosePanelWhenClick: true,
            disable: false,
            itemPriority: 999,
            badgeType: .initWithDotSmallStyle(),
            action: webShareAction
        )

        // wx
        let wxImageModel = MenuItemImageModel(
            normalForIPhonePanel: wxImage,
            normalForIPadPopover: wxImage,
            renderMode: .alwaysOriginal
        )
        let action: MenuItemModel.MenuItemAction = { (_) in
            Self.logger.info("OPThirdShareHelper share to wechat click")
            Self.snsShare(
                controller: controller,
                appID: appID,
                channel: Self.shareChannelWX,
                traceId: Self.wxTraceID(),
                contentType: contentType,
                url: url,
                title: title,
                content: content,
                imageData:imageData,
                successHandler: successHandler,
                failedHandler: failedHandler
            )
        }
        let wxShareMenuItem = MenuItemModel(
            title: wxTitle,
            imageModel: wxImageModel,
            itemIdentifier: "shareToWeChat",
            badgeNumber: 0,
            autoClosePanelWhenClick: true,
            disable: false,
            itemPriority: 500,
            badgeType: .initWithDotSmallStyle(),
            action: action
        )

        // wx朋友圈
        let momentImageModel = MenuItemImageModel(
            normalForIPhonePanel: momentImage,
            normalForIPadPopover: momentImage,
            renderMode: .alwaysOriginal
        )
        let momentAction: MenuItemModel.MenuItemAction = { (_) in
            Self.logger.info("OPThirdShareHelper share to moment click")
            Self.snsShare(
                controller: controller,
                appID: appID,
                channel: Self.shareChannelWXTimeLine,
                traceId: Self.wxTimeLineTraceID(),
                contentType: contentType,
                url: url,
                title: title,
                content: content,
                imageData:imageData,
                successHandler: successHandler,
                failedHandler: failedHandler
            )
        }
        let momentShareMenuItem = MenuItemModel(
            title: momentTitle,
            imageModel: momentImageModel,
            itemIdentifier: "shareToWeChatMoments",
            badgeNumber: 0,
            autoClosePanelWhenClick: true,
            disable: false,
            itemPriority: 400,
            badgeType: .initWithDotSmallStyle(),
            action: momentAction
        )

        // more
        let moreImageModel = MenuItemImageModel(
            normalForIPhonePanel: moreImage,
            normalForIPadPopover: moreImage,
            renderMode: .alwaysOriginal
        )
        let moreAction: MenuItemModel.MenuItemAction = { (_) in
            Self.logger.info("OPThirdShareHelper share more click")
            Self.snsShare(
                controller: controller,
                appID: appID,
                channel: Self.shareChannelMore,
                traceId: Self.shareMoreTraceID(),
                contentType: contentType,
                url: url,
                title: title,
                content: content,
                imageData:imageData,
                successHandler: successHandler,
                failedHandler: failedHandler
            )
        }
        let moreShareMenuItem = MenuItemModel(
            title: moreTitle,
            imageModel: moreImageModel,
            itemIdentifier: "shareToMore",
            badgeNumber: 0,
            autoClosePanelWhenClick: true,
            disable: false,
            itemPriority: 300,
            badgeType: .initWithDotSmallStyle(),
            action: moreAction
        )
        var menuItems = [MenuItemModel]()
        if channelType.contains(Self.shareChannelInApp) {
            Self.logger.info("OPThirdShareHelper share add inApp item")
            menuItems.append(webShareMenuItem)
        }
        if channelType.contains(Self.shareChannelWX) {
            Self.logger.info("OPThirdShareHelper share add wechat item")
            menuItems.append(wxShareMenuItem)
        }
        if channelType.contains(Self.shareChannelWXTimeLine) {
            Self.logger.info("OPThirdShareHelper share add moment item")
            menuItems.append(momentShareMenuItem)
        }
        if channelType.contains(Self.shareChannelMore) {
            Self.logger.info("OPThirdShareHelper share add more item")
            menuItems.append(moreShareMenuItem)
        }
        successHandler?()
        return menuItems
    }

    // 社交分享处理
    private class func snsShare(
        controller: UIViewController,
        appID: String,
        channel: String,
        traceId: String,
        contentType: String,
        url: String,
        title: String,
        content: String,
        imageData: NSData,
        successHandler: (() -> Void)?,
        failedHandler: ((Error?) -> Void)?
    ) {
        if let delegate = EMAProtocolProvider.getEMADelegate() {
        delegate.snsShare(
            controller,
            appID: appID,
            channel: channel,
            contentType: contentType,
            traceId: traceId,
            title: title,
            url: url,
            desc: content,
            imageData: imageData as Data
        ) {
            // Do nothing
        } failedHandler: { (error) in
            Self.logger.error("OPThirdShareHelper snsShare error \(String(describing: error))")
        }
        } else {
            Self.logger.error("OPThirdShareHelper snsShare error: cannot getEMADelegate")
        }
    }
}
