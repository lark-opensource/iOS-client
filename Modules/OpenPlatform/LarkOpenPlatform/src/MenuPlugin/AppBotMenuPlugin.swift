//
//  AppBotMenuPlugin.swift
//  LarkOpenPlatform
//
//  Created by 刘洋 on 2021/3/10.
//

import UIKit
import LarkUIKit
import LarkSDKInterface
import Swinject
import RxSwift
import LarkTab
import LarkMessengerInterface
import LarkOPInterface
import EENavigator
import LKCommonsLogging
import OPSDK
import OPFoundation
import TTMicroApp
import EEMicroAppSDK
import UniverseDesignIcon
import LarkContainer

/// 日志
private let logger = Logger.log(AppBotMenuPlugin.self, category: "LarkOpenPlatform")

/// 小程序机器人菜单插件
/// 核心代码code form：houzhiyou
final class AppBotMenuPlugin: MenuPlugin {

    /// Swinject的对象
    private let resolver: UserResolver

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 从上下文中获取Resolver的key
    static let providerContextResloveKey = "resolver"

    /// Rx所需要的DisposeBag
    private static let disposeBag = DisposeBag()

    /// 机器人插件的优先级
    private let botItemPriority: Float = 70

    /// botNoRespond机器人的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let botItemIdentifier = "bot"

    init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let resolver = pluginContext.parameters[AppBotMenuPlugin.providerContextResloveKey] as? UserResolver else {
            logger.error("bot plugin init failure because there is no resolver")
            return nil
        }
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("bot plugin init failure because there is no AppMenuContext")
            return nil
        }
        self.resolver = resolver
        self.menuContext = appMenuContext
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.fetchMenuItemModel(updater: {
            item in
            handler.updateItemModels(for: [item])
        })
    }

    static var pluginID: String {
        "AppBotMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let title = BundleI18n.Bot.Lark_AppCenter_EnterBot
        let image = UDIcon.getIconByKey(UDIconType.robotOutlined)
        let badgeNumber = context.badgeNumber
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let botMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.botItemIdentifier, badgeNumber: badgeNumber, itemPriority: self.botItemPriority) { [weak self] _ in
            self?.openBot()
        }
        botMenuItem.menuItemCode = .botButton
        updater(botMenuItem)
    }

    /// 打开机器人
    private func openBot() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let uniqueID = self.menuContext.uniqueID
        let monitor = OPMonitor(ShellMonitorEvent.mp_enter_bot).setUniqueID(uniqueID).timing()
        guard !context.botID.isEmpty else {
            monitor.addCategoryValue("result_type", "fail")
                .addCategoryValue("fail_type", "botId_empty")
                .setMonitorCode(ShellMonitorCode.mp_open_bot_error)
                .flush()
            logger.error("openBot can not push because botID is empty")
            return
        }
        guard let chatService = try? resolver.resolve(assert: ChatService.self) else {
            logger.error("openBot can not push because no ChatService")
            return
        }
        guard let window = uniqueID.window, let from = OPNavigatorHelper.topmostNav(window: window) else {
            logger.error("openBot can not push vc because no fromViewController")
            return
        }
        chatService.createP2PChat(userId: context.botID, isCrypto: false, chatSource: nil).observeOn(MainScheduler.instance).subscribe(onNext: { (chat) in
            let body = ChatControllerByChatBody(chat: chat)
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
            ]
            logger.info("openBot page is pushed")
            self.resolver.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url, body: body, context: context, wrap: LkNavigationController.self, from: from)
            monitor.addCategoryValue("result_type", "success")
                .setMonitorCode(ShellMonitorCode.mp_open_bot_success)
                .timing()
                .flush()
        }).disposed(by: AppBotMenuPlugin.disposeBag)

        // 产品埋点
        self.itemActionReport(applicationID: uniqueID.appID, menuItemCode: .botButton)
    }

    /// 检查环境是否正确，是否显示分享
    /// - Returns: 分享所需要的必要信息
    private func checkEnvironmentIsReady() -> (badgeNumber: UInt, botID: String)? {
        let uniqueID = self.menuContext.uniqueID
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("bot can't show because there is no common")
            return nil
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("there is no model")
            return nil
        }
        var botID: String
        let botIDKey = "botid"
        if let string = model.extraDict[botIDKey] as? String {
            botID = string
        } else if let number = model.extraDict[botIDKey] as? NSNumber {
            botID = number.stringValue
        } else {
            logger.error("there is no botID for model")
            return nil
        }
        guard !botID.isEmpty else {
            logger.error("bot can't show because because botID is empty")
            return nil
        }
        return (common.moreBtnBadgeNum, botID)
    }
}
