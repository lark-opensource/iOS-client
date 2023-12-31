//
//  MessageCardTranslateActionHandler.swift
//  LarkOpenPlatform
//
//  Created by zhangjie.alonso on 2023/3/1.
//

import Foundation
import LarkMessageBase
import LarkMessageCore
import LarkMessengerInterface
import UniverseDesignMenu
import UniverseDesignIcon
import LarkSearchCore
import LarkModel
import LarkSDKInterface
import LarkUIKit
import Homeric
import LKCommonsTracker
import LKCommonsLogging

enum ClickType: String {
    case viewOriginal = "view_original"
    case hideTranslation = "hide_translation"
}

fileprivate let logger = Logger.log(MessageCardTranslateActionHandler.self, category: "MessageCardTranslateActionHandler")
final class MessageCardTranslateActionHandler {
    var context: PageContext
    var chat: () -> Chat
    public var message: Message
    init(context: PageContext,
         chat: @escaping () -> Chat,
         message: Message) {
        self.context = context
        self.chat = chat
        self.message = message
    }

    public func update(context: PageContext,
                       chat: @escaping () -> Chat,
                       message: Message) {
        DispatchQueue.main.async {
            self.context = context
            self.chat = chat
            self.message = message
        }
    }
    /// 翻译反馈函数
    func translateFeedBackTapHandler() {
        if let translateFeedBackService = self.context.resolver.resolve(TranslateFeedbackService.self),
           let targetVC = self.context.pageAPI {
            translateFeedBackService.showTranslateFeedbackView(message: self.message, fromVC: targetVC)
            return
        }
    }
    // 翻译更多
    func translateMoreTapHandler(_ view: UIView) {
        if Display.pad {
            showTranslateActionPopOver(sourceView: view)
        } else {
            showTranslateActionDrawer()
        }
    }
    
    //查看原文与收起译文handler
     func showOriginOrWithOriginalHandler(_ clickType: ClickType) {
         translateActionDrawer?.dismiss(animated: true) { [weak self] in
             guard let self = self else {
                 logger.error("self is nil")
                 assertionFailure()
                 return }
             self.translateActionDrawer = nil
             guard let targetVC = self.context.pageAPI else {
                 logger.error("context.pageAPI is nil")
                 assertionFailure()
                 return
             }
             let translateParam = MessageTranslateParameter(message: self.message,
                                                            source: MessageSource.common(id: self.message.id),
                                                            chat: self.chat())
             self.trackTranslationActionClicked(clickType: clickType.rawValue)
             self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
         }
    }

    //iPad 查看原文或收起译文
     func showOriginOrWithOriginalHandlerForIpad(_ clickType: ClickType) {
            guard let targetVC = self.context.pageAPI else {
                logger.error("context.pageAPI is nil")
                assertionFailure()
                return
            }
            let translateParam = MessageTranslateParameter(message: self.message,
                                                           source: MessageSource.common(id: self.message.id),
                                                           chat: self.chat())
            self.trackTranslationActionClicked(clickType: clickType.rawValue)
            self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
    }

    func getTranslateMoreActionDrawer() -> TranslateMoreActionDrawer {
        var actions: [TranslateMoreActionModel] = []
        switch message.displayRule {
        case .onlyTranslation:
            let showOrigin = TranslateMoreActionModel(icon: UDIcon.translateOutlined.ud.withTintColor(.ud.textTitle),
                                                      title:BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslatedText_MoreOptions_ShowOriginal) { [weak self] in
                guard let self = self else {
                    logger.error("translateActions showOrigin: self is nil")
                    assertionFailure()
                    return
                }
                self.showOriginOrWithOriginalHandler(.viewOriginal)
            }
            actions.append(showOrigin)
        case .withOriginal:
            let hideTranslate = TranslateMoreActionModel(icon: UDIcon.visibleLockOutlined.ud.withTintColor(.ud.textTitle),
                                                         title: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslatedText_MoreOptions_HideTranslation) { [weak self] in
                guard let self = self else {
                    logger.error("translateActions hideTranslate: self is nil")
                    assertionFailure()
                    return
                }
                self.showOriginOrWithOriginalHandler(.hideTranslation)
            }
            actions.append(hideTranslate)
        @unknown default: break
        }
        if AIFeatureGating.translationOptimizationSwitchLanguage.isEnabled {
            let switchLanguage = TranslateMoreActionModel(icon: UDIcon.transSwitchOutlined.ud.withTintColor(.ud.textTitle),
                                                          title: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslatedText_MoreOptions_SwitchLanguages) { [weak self] in
                guard let self = self,
                      let targetVC = self.context.pageAPI else {
                    logger.error("translateActions switchLanguage: self is nil: \(String(self == nil)), context.pageAPI is nil: \(String(self?.context.pageAPI == nil))")
                    assertionFailure()
                    return
                }
                self.translateActionDrawer?.dismiss(animated: true) {
                    self.translateActionDrawer = nil
                    self.context.translateService?.showSelectLanguage(messageId: self.message.id,
                                                                      source: MessageSource.common(id: self.message.id),
                                                                      chatId: self.message.chatID,
                                                                      from: targetVC) {
                        self.showTranslateActionDrawer()
                    }
                }
            }
            actions.append(switchLanguage)
        }
        return TranslateMoreActionDrawer(translateActions: actions)
    }

    func getTranslateUDActions() -> [UDMenuAction] {
        var actions: [UDMenuAction] = []
        switch message.displayRule {
        case .onlyTranslation:
            let showOrigin = UDMenuAction(
                title: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslatedText_MoreOptions_ShowOriginal,
                icon: UDIcon.translateOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                    guard let self = self else {
                        logger.error("translateUDActions showOrigin: self is nil")
                        assertionFailure()
                        return
                    }
                    self.showOriginOrWithOriginalHandlerForIpad(.viewOriginal)
                }
            actions.append(showOrigin)
        case .withOriginal:
            let hideTranslate = UDMenuAction(
                title: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslatedText_MoreOptions_HideTranslation,
                icon: UDIcon.visibleLockOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                    guard let self = self else {
                        logger.error("translateUDActions hideTranslate: self is nil")
                        assertionFailure()
                        return
                    }
                    self.showOriginOrWithOriginalHandlerForIpad(.hideTranslation)
                }
            actions.append(hideTranslate)
        @unknown default: break
        }
        if AIFeatureGating.translationOptimizationSwitchLanguage.isEnabled {
            let switchLanguage = UDMenuAction(
                title: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslatedText_MoreOptions_SwitchLanguages,
                icon: UDIcon.transSwitchOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                    guard let self = self,
                          let targetVC = self.context.pageAPI else {
                        logger.error("translateUDActions switchLanguage: self is nil: \(String(self == nil)), context.pageAPI is \(String(self?.context.pageAPI == nil))")
                        assertionFailure()
                        return
                    }
                    self.context.translateService?.showSelectLanguage(messageId: self.message.id,
                                                                      source: MessageSource.common(id: self.message.id),
                                                                      chatId: self.message.chatID,
                                                                      from: targetVC) {}
                }
            actions.append(switchLanguage)
        }
        return actions
    }

    private func showTranslateActionPopOver(sourceView: UIView) {
        guard let targetVC = self.context.pageAPI else {
            assertionFailure("showTranslateActionPopOver pageAPI is nil")
            return
        }
        let config = UDMenuConfig(position: .bottomAuto)
        var style = UDMenuStyleConfig.defaultConfig()
        style.menuColor = UIColor.ud.bgFloat
        style.menuMaxWidth = CGFloat.greatestFiniteMagnitude
        style.menuItemTitleColor = UIColor.ud.textTitle
        style.menuItemSelectedBackgroundColor = UIColor.ud.fillHover
        style.menuItemSeperatorColor = UIColor.ud.lineDividerDefault
        let menu = UDMenu(actions: self.getTranslateUDActions(), config: config, style: style)
        menu.showMenu(sourceView: sourceView, sourceVC: targetVC)
    }
    
    private var translateActionDrawer: SelectiveDrawerController?
    
    private func showTranslateActionDrawer() {
        let headerView = TranslateMoreActionHeaderView()
        let footerView = UIView()
        footerView.backgroundColor = .ud.bgFloatBase
        let translateMoreActionDrawer = self.getTranslateMoreActionDrawer()
        let config = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                  cornerRadius: 12,
                                  thresholdOffset: TranslateMoreActionDrawer.UI.dismissThresholdOffset,
                                  maxContentHeight: CGFloat(TranslateMoreActionDrawer.UI.maxCellCountForExpend) * TranslateMoreActionDrawer.UI.cellHeight
                                  + TranslateMoreActionDrawer.UI.headerViewHeight + TranslateMoreActionDrawer.UI.footerHeight,
                                  cellType: TranslateMoreActionCell.self,
                                  tableViewDataSource: translateMoreActionDrawer,
                                  tableViewDelegate: translateMoreActionDrawer,
                                  headerView: headerView,
                                  footerView: footerView,
                                  headerViewHeight: TranslateMoreActionDrawer.UI.headerViewHeight,
                                  footerViewHeight: TranslateMoreActionDrawer.UI.footerHeight)
        let drawer = SelectiveDrawerController(config: config, cancelBlock: { [weak self] in
            guard let self = self else {
                logger.error("self is nil")
                return
            }
            self.translateActionDrawer = nil
        })
        headerView.didTapCloseButton = { [weak drawer, weak self] in
            guard let self = self,
                  let drawer = drawer else {
                logger.error("self is \(String(describing: self)), drawer is \(String(describing: drawer))")
                return
            }
            drawer.dismiss(animated: true)
            self.translateActionDrawer = nil
        }
        self.translateActionDrawer = drawer
        context.navigator(type: .present,
                          controller: drawer,
                          params: nil)
    }
    
    /// translate Tracking
    var chatTypeForTracking: String {
        if self.chat().chatMode == .threadV2 {
            return "topic"
        } else if self.chat().type == .group {
            return "group"
        } else {
            return "single"
        }
    }
    
    private func trackTranslationActionClicked(clickType: String) {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = self.chat().id
        trackInfo["chat_type"] = chatTypeForTracking
        trackInfo["msg_id"] = message.id
        trackInfo["message_language"] = message.messageLanguage
        trackInfo["target_language"] = message.translateLanguage
        trackInfo["msg_type"] = "card"
        trackInfo["click"] = clickType
        Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_SUB_CLICK, params: trackInfo))
    }
}
