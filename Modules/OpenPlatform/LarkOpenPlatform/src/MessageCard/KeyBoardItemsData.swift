//
//  KeyBoardItemsData.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/5.
//

import UIKit
import Swinject
import RxSwift
import LarkFeatureGating
import RustPB
import LarkRustClient
import SwiftyJSON
import LarkExtensions
import LKCommonsTracker
import LarkAccountInterface
import LarkLocalizations
import LKCommonsLogging
import LarkModel
import EENavigator
import LarkAppLinkSDK
import LarkOPInterface
import EEMicroAppSDK
import LarkGuide
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme
import LarkContainer

enum KeyBoardItemUpdateEvent {
    case loadFromInit
    case reloadFromCache
    case reloadWhenImage
    case reloadWhenOtherUpdate
}
let launchAbilityKey = "required_launch_ability"
///这个类提供+号菜单面板的小程序入口数据源，目前在私聊和群聊（排除外部群）入口提供小程序入口
class KeyBoardItemsData {
    private var resolver: UserResolver
    private var locale: String
    private var dataProvider: MoreAppListDataProvider
    private var cacheKeyboardAvailableItems: [KeyboardApp]?
    private var chatCache: [String: Chat] = [:]
    private let disposeBag = DisposeBag()
    private lazy var guideService = {
        try? resolver.resolve(assert: GuideService.self)
    }()

    private static let logger = Logger.log(KeyBoardItemsData.self, category: "KeyBoardItemsData")
    ///这个信号是为了在+号数据更新后，主动push+号面板内部的数据刷新
    public var itemsUpdateSub = PublishSubject<KeyBoardItemUpdateEvent>()
    private var reporter: MessageCardReport?

    init(resolver: UserResolver) {
        self.resolver = resolver
        ///小程序的信息跟语言相关，切换语言需要重新拉取
        self.locale = OpenPlatformAPI.curLanguage()
        self.dataProvider = MoreAppListDataProvider(
            resolver: resolver,
            locale: self.locale,
            scene: .addMenu
        )
        // app启动时，通过单例来监听push消息，请求后端接口来更新本地缓存
        self.dataProvider.observeGadgetPush { [weak self] (error, _) in
            if error == nil {
                self?.itemsUpdateSub.onNext(.reloadFromCache)
            }
        }
    }

    /// availableItem
    private func keyboardAvailableItems(type: Basic_V1_Chat.TypeEnum, hasReloadImage: Bool) -> [KeyboardApp] {
        return self.dataProvider.keyBoardDisplayApps(type: type, dataUpdateBlock: { [weak self] in
            // 如果之前已经加载过图片，刷新加号面板上展示数据时，会引起重新加载图片
            // 为避免循环调用，这时不再需要重新触发刷新加号面板上展示数据的流程
            if hasReloadImage {
                return
            }
            self?.itemsUpdateSub.onNext(.reloadWhenImage)
        })
    }
    /// 更多入口
    private func makeNativeMoreItem(chat: Chat, chatViewController: UIViewController?) -> KeyBoardItem {
        let icon = BundleResources.LarkOpenPlatform.more_chat_action
        //文案按照产品要求改为“更多” https://bytedance.feishu.cn/docs/doccnVNthkJKElFhcY9CGPtvDBe# 上面的icon更换资源
        let title = BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_MoreBttn
        let isShowDot = self.guideService?.needShowGuide(key: "chat_keyboard_moreItem_dot") ?? false
        let moreItem = KeyBoardItem(app: AuthorizedApp(json: [:]), customViewBlock: nil, icon: icon, isShowDot: isShowDot, selectIcon: nil, tapped: { [weak self, weak chatViewController] in
            guard let self = self else {
                return
            }
            OPMonitor(EPMJsOpenPlatformGadgetAppShortCutCode.keyboard_items_event)
                .addCategoryValue("more_item_click", true)
                .flush()
            KeyBoardItemsData.logger.info("keyboard more item click")
            TeaReporter(eventKey: TeaReporter.key_appplus_click_more)
                .withUserInfo(resolver: self.resolver)
                .withDeviceType()
                .report()
            MoreAppTeaReport.imChatInputPlusClick(resolver: self.resolver, chat: chat, isMoreOrElseApp: true)
            let fromScene = chat.type == .p2P ? FromScene.single_appplus : FromScene.multi_appplus
            let userID = self.resolver.userID
            /// 记录下入口的上下文，后续小程序调用发卡片的API的时候，可以使用这个上下文
            let context = ChatActionContextItem(
                chat: chat,
                i: nil,
                user: userID,
                ttCode: ""
            )
            let pageVC = MoreAppListViewController(
                resolver: self.resolver,
                bizScene: .addMenu,
                fromScene: fromScene,
                chatId: chat.id,
                actionContext: context,
                chatActionListUpdateCallback: { [weak self] in
                    Self.logger.info("chatActionListUpdateCallback reloadWhenOtherUpdate")
                    self?.dataProvider.updateLocalExternalItemList(updateCallback: { [weak self] (_) in
                        self?.itemsUpdateSub.onNext(.reloadFromCache)
                    })
                },
                openAvailableApp: { (appModel, sourceViewController) -> Bool in
                    return self.simulateOpenApp(appModel: appModel,
                                                chat: chat,
                                                sourceViewController: sourceViewController)
                }
            )
            if let fromVC = chatViewController ?? Navigator.shared.mainSceneWindow?.fromViewController {
                self.resolver.navigator.push(pageVC, from: fromVC)
            } else {
                KeyBoardItemsData.logger.error("makeNativeMoreItem can not push vc because no fromViewController")
            }
            if isShowDot {
                self.guideService?.didShowGuide(key: "chat_keyboard_moreItem_dot")
            }
        }, text: title, priority: 0, badge: nil)
        return moreItem
    }

    public func getDynamicItems(chat: Chat, chatViewController: UIViewController?, onlyUseCache: Bool = false, hasReloadImage: Bool = false, onComplete: @escaping (([KeyBoardItemProtocol & KeyBoardItemSourceApp]) -> Void)) {
        /// 保存在缓存中
        chatCache[chat.id] = chat
        var result: [KeyBoardItemProtocol & KeyBoardItemSourceApp] = []
        ///如果是密聊
        if chat.isCrypto {
            KeyBoardItemsData.logger.info("isCrypto and p2P not DisplayCrossTenantEntry")
            onComplete(result)
            return
        }
        ///如果是外部群，不显示小程序入口
        if chat.isCrossTenant {
            KeyBoardItemsData.logger.info("CrossTenant and should not DisplayCrossTenantEntry")
            onComplete(result)
            return
        }
        guard let op = try? resolver.resolve(assert: OpenPlatformService.self) else {
            onComplete(result)
            return
        }
        let userID = resolver.userID
        var itemValidCount = 0
        self.cacheKeyboardAvailableItems = keyboardAvailableItems(type: chat.type, hasReloadImage: hasReloadImage)
        op.getTriggerCode { [weak self, weak chatViewController] (triggerCode) in
            guard let self = self else {
                return
            }
            for item in self.cacheKeyboardAvailableItems ?? [] {
                guard item.isAppCanDisplay(), var sourceUrl = item.sourceTargetUrl() else {
                    continue
                }
                /// 添加某个能力
                if let launchAbilityParametr = item.appModel.requiredLaunchAbility {
                    /// 如果指定了某个能力
                    sourceUrl = sourceUrl.urlStringAddParameter(parameters: [launchAbilityKey: launchAbilityParametr])
                }
                itemValidCount += 1
                let triggerCodeWithIndex = triggerCode + "\(itemValidCount)"
                if let targetUrl = op.urlAppendTriggerCode(sourceUrl, triggerCodeWithIndex, appendOnlyForMiniProgram: false),
                   let target = targetUrl.possibleURL() {
                    result.append(item.toDynamicItem(tap: { [weak self, weak chatViewController] in
                        guard let self = self else {
                            KeyBoardItemsData.logger.error("getTriggerCode KeyBoardItemsData is nil")
                            return
                        }
                        /// 记录下入口的上下文，后续小程序调用发卡片的API的时候，可以使用这个上下文
                        let context = ChatActionContextItem(chat: chat,
                                                               i: item,
                                                               user: userID,
                                                               ttCode: triggerCodeWithIndex)
                        MessageCardSession.shared().recordOpenChatAction(context: context)
                        let fromScene = chat.type == .p2P ? FromScene.single_appplus.rawValue : FromScene.multi_appplus.rawValue
                        if let fromVC = chatViewController ?? Navigator.shared.mainSceneWindow?.fromViewController {
                            self.resolver.navigator.push(target, context: ["from": fromScene], from: fromVC, animated: true, completion: nil)
                        } else {
                            KeyBoardItemsData.logger.error("getTriggerCode can not push vc because no fromViewController")
                        }
                        self.reporter?.report(eventKey: MessageCardReport.key_appplus_keyboard_click_app,
                                               paraDic: ["appid": item.appModel.appId ?? ""])
                        let params = [ParamKey.appId: item.appModel.appId, ParamKey.from: "appplus_menu"]
                        TeaReporter(eventKey: TeaReporter.key_appplus_click_app)
                            .withUserInfo(resolver: self.resolver)
                            .withDeviceType()
                            .withInfo(params: params)
                            .report()
                        MoreAppTeaReport.imChatInputPlusClick(resolver: self.resolver, chat: chat, isMoreOrElseApp: false, appID: item.appModel.appId)

                        KeyBoardItemsData.logger.info("Message Action click \(target)")
                        OPMonitor(EPMJsOpenPlatformGadgetAppShortCutCode.keyboard_items_event)
                            .addCategoryValue("appid", item.appModel.appId)
                            .addCategoryValue("applink", sourceUrl)
                            .flush()
                    }))
                } else {
                    KeyBoardItemsData.logger.error("open \(item.appModel.name ?? "") \(sourceUrl) failed")
                }
            }
            result.append(self.makeNativeMoreItem(chat: chat, chatViewController: chatViewController))
            KeyBoardItemsData.logger.info("getDynamicItems complete \(result.count) origin items count \(self.cacheKeyboardAvailableItems?.count ?? 0)")
            onComplete(result)
        }
        let eventKey = MessageCardReport.key_appplus_keyboard_click
        let eventParameter = ["apps_count": "\(result.count)"]
        self.reporter?.report(eventKey: eventKey, paraDic: eventParameter)
        TeaReporter(eventKey: TeaReporter.key_appplus_click_menu).withUserInfo(resolver: resolver).report()
        if !onlyUseCache {
        self.dataProvider.updateRemoteExternalItemListIfNeed(
            forceUpdate: false,
            updateCallback:  { [weak self] (_, _) in
                // 点击加号按钮，使用当前缓存展示应用列表，后台强制刷新加号数据但本次不启用
                self?.itemsUpdateSub.onNext(.loadFromInit)
            }
        )
        }
    }
    func simulateOpenApp(appModel: MoreAppItemModel, chat: Chat, sourceViewController: UIViewController) -> Bool {
        guard var sourceUrl = appModel.mobileApplinkUrl, let op = try? resolver.resolve(assert: OpenPlatformService.self) else {
            KeyBoardItemsData.logger.error("simulateOpenApp: OpenPlatformService is nil")
            return false
        }
        /// 添加某个能力
        if let launchAbilityParametr = appModel.requiredLaunchAbility {
            /// 如果指定了某个能力
            sourceUrl = sourceUrl.urlStringAddParameter(parameters: [launchAbilityKey: launchAbilityParametr])
        }
        let userID = resolver.userID
        op.getTriggerCode { [weak sourceViewController](triggerCode) in
            if let targetUrl = op.urlAppendTriggerCode(sourceUrl, triggerCode, appendOnlyForMiniProgram: false),
               let target = targetUrl.possibleURL() {
                /// 记录下入口的上下文，后续小程序调用发卡片的API的时候，可以使用这个上下文
                let context = ChatActionContextItem(chat: chat,
                                                       i: KeyboardApp(appModel: appModel, dataUpdateBlock: {
                                                       }),
                                                       user: userID,
                                                       ttCode: triggerCode)
                MessageCardSession.shared().recordOpenChatAction(context: context)
                let fromScene = chat.type == .p2P ? FromScene.single_appplus.rawValue : FromScene.multi_appplus.rawValue
                if let fromVC = sourceViewController ?? Navigator.shared.mainSceneWindow?.fromViewController {
                    self.resolver.navigator.push(target, context: ["from": fromScene], from: fromVC, animated: true, completion: nil)
                } else {
                    KeyBoardItemsData.logger.error("simulateOpenApp getTriggerCode can not push vc because no fromViewController")
                }
                KeyBoardItemsData.logger.info("Simulate Action click \(target)")
                OPMonitor(EPMJsOpenPlatformGadgetAppShortCutCode.keyboard_items_event)
                    .addCategoryValue("appid", appModel.appId)
                    .addCategoryValue("applink", sourceUrl)
                    .addCategoryValue("simulate", true)
                    .flush()
                let params = [ParamKey.appId: appModel.appId, ParamKey.from: "appplus_menu"]
                TeaReporter(eventKey: TeaReporter.key_appplus_click_app)
                    .withUserInfo(resolver: self.resolver)
                    .withDeviceType()
                    .withInfo(params: params)
                    .report()
            }
        }
        return true
    }

    func reportSendCardSendEvent(appid: String,
                                 scene: String,
                                 result: Bool) {
        self.reporter?.report(eventKey: MessageCardReport.gadget_sendMessageCard_send,
                              paraDic: ["appid": appid, "scene": scene, "result": result ? "1" : "0"])
    }

    func reportSendCardCallEvent(appid: String,
                                 scene: String) {
        self.reporter?.report(eventKey: MessageCardReport.gadget_sendMessageCard_call,
                              paraDic: ["appid": appid, "scene": scene])
    }

    func reportSendCardPreviewClickEvent(appid: String,
                                         scene: String,
                                         action: Bool) {
        self.reporter?.report(eventKey: MessageCardReport.gadget_sendMessageCard_preview_click,
                              paraDic: ["appid": appid, "scene": scene, "action": action ? "1" : "0"])
    }
}
