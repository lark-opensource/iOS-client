//
//  TranslateMoreActionHandler.swift
//  LarkMessageCore
//
//  Created by Patrick on 17/11/2022.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkMessengerInterface
import UniverseDesignMenu
import UniverseDesignIcon
import LarkSearchCore
import LarkModel
import LarkSDKInterface
import LarkUIKit
import Homeric
import LKCommonsTracker

final class TranslateMoreActionHandler {
    let context: TextPostContentContext
    let metaModel: CellMetaModel

    var message: Message {
        return metaModel.message
    }

    init(context: TextPostContentContext,
         metaModel: CellMetaModel) {
        self.context = context
        self.metaModel = metaModel
    }

    /// 翻译反馈函数
    func translateFeedBackTapHandler() {
        let translateFeedBackService = context.feedbackService
        guard let targetVC = self.context.pageAPI else {
            assertionFailure("translateFeedBackTapHandler pageAPI is nil")
            return
        }
        translateFeedBackService?.showTranslateFeedbackView(message: message, fromVC: targetVC)
    }

    // 翻译更多 action
    private lazy var translateActions: [TranslateMoreActionModel] = {
        var actions: [TranslateMoreActionModel] = []
        switch message.displayRule {
        case .onlyTranslation:
            // 语音消息需要特殊的逻辑，语音消息的 onlyTranslation 和 withOriginal 都需要展示原文，所以两个情况都是展示 hideTranslate
            if TranslateControl.isTranslatableAudioMessage(message) {
                let hideTranslatePost = TranslateMoreActionModel(icon: UDIcon.visibleLockOutlined.ud.withTintColor(.ud.textTitle),
                                                                 title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_HideTranslation) { [weak self] in
                    guard let self = self else { return }
                    self.translateActionDrawer?.dismiss(animated: true) {
                        self.translateActionDrawer = nil
                        guard let targetVC = self.context.pageAPI else {
                            assertionFailure("hideTranslatePost pageAPI is nil")
                            return
                        }
                        let chat = self.metaModel.getChat()
                        let translateParam = MessageTranslateParameter(message: self.message,
                                                                       source: MessageSource.common(id: self.message.id),
                                                                       chat: chat)
                        self.trackTranslationActionClicked(clickType: "hide_translation")
                        self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
                    }
                }
                actions.append(hideTranslatePost)
            } else {
                let showOriginPost = TranslateMoreActionModel(icon: UDIcon.translateOutlined.ud.withTintColor(.ud.textTitle),
                                                              title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_ShowOriginal) { [weak self] in
                    guard let self = self else { return }
                    self.translateActionDrawer?.dismiss(animated: true) {
                        self.translateActionDrawer = nil
                        guard let targetVC = self.context.pageAPI else {
                            assertionFailure("showOriginPost pageAPI is nil")
                            return
                        }
                        let chat = self.metaModel.getChat()
                        let translateParam = MessageTranslateParameter(message: self.message,
                                                                       source: MessageSource.common(id: self.message.id),
                                                                       chat: chat)
                        self.trackTranslationActionClicked(clickType: "view_original")
                        self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
                    }
                }
                actions.append(showOriginPost)
            }
        case .withOriginal:
            let hideTranslatePost = TranslateMoreActionModel(icon: UDIcon.visibleLockOutlined.ud.withTintColor(.ud.textTitle),
                                                             title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_HideTranslation) { [weak self] in
                guard let self = self else { return }
                self.translateActionDrawer?.dismiss(animated: true) {
                    self.translateActionDrawer = nil
                    guard let targetVC = self.context.pageAPI else {
                        assertionFailure("hideTranslatePost pageAPI is nil")
                        return
                    }
                    let chat = self.metaModel.getChat()
                    let translateParam = MessageTranslateParameter(message: self.message,
                                                                   source: MessageSource.common(id: self.message.id),
                                                                   chat: chat)
                    self.trackTranslationActionClicked(clickType: "hide_translation")
                    self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
                }
            }
            actions.append(hideTranslatePost)
        @unknown default: break
        }
        if AIFeatureGating.translationOptimizationSwitchLanguage.isUserEnabled(userResolver: context.userResolver) {
            let switchLanguage = TranslateMoreActionModel(icon: UDIcon.transSwitchOutlined.ud.withTintColor(.ud.textTitle),
                                                          title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_SwitchLanguages) { [weak self] in
                guard let self = self else { return }
                guard let targetVC = self.context.pageAPI else {
                    assertionFailure("switchLanguage pageAPI is nil")
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
        return actions
    }()

    // 翻译更多 action
    private lazy var translateUDActions: [UDMenuAction] = {
        var actions: [UDMenuAction] = []
        switch message.displayRule {
        case .onlyTranslation:
            // 语音消息需要特殊的逻辑，语音消息的 onlyTranslation 和 withOriginal 都需要展示原文，所以两个情况都是展示 hideTranslate
            if TranslateControl.isTranslatableAudioMessage(message) {
                let hideTranslatePost = UDMenuAction(
                    title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_HideTranslation,
                    icon: UDIcon.visibleLockOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                        guard let self = self else { return }
                        guard let targetVC = self.context.pageAPI else {
                            assertionFailure("hideTranslatePost pageAPI is nil")
                            return
                        }
                        let chat = self.metaModel.getChat()
                        let translateParam = MessageTranslateParameter(message: self.message,
                                                                       source: MessageSource.common(id: self.message.id),
                                                                       chat: chat)
                        self.trackTranslationActionClicked(clickType: "hide_translation")
                        self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
                }
                actions.append(hideTranslatePost)
            } else {
                let showOriginPost = UDMenuAction(
                    title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_ShowOriginal,
                    icon: UDIcon.translateOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                        guard let self = self,
                              let targetVC = self.context.pageAPI else {
                            assertionFailure("showOriginPost pageAPI is nil")
                            return
                        }
                        let chat = self.metaModel.getChat()
                        let translateParam = MessageTranslateParameter(message: self.message,
                                                                       source: MessageSource.common(id: self.message.id),
                                                                       chat: chat)
                        self.trackTranslationActionClicked(clickType: "view_original")
                        self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
                }
                actions.append(showOriginPost)
            }
        case .withOriginal:
            let hideTranslatePost = UDMenuAction(
                title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_HideTranslation,
                icon: UDIcon.visibleLockOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                    guard let self = self else { return }
                    guard let targetVC = self.context.pageAPI else {
                        assertionFailure("hideTranslatePost pageAPI is nil")
                        return
                    }
                    let chat = self.metaModel.getChat()
                    let translateParam = MessageTranslateParameter(message: self.message,
                                                                   source: MessageSource.common(id: self.message.id),
                                                                   chat: chat)
                    self.trackTranslationActionClicked(clickType: "hide_translation")
                    self.context.translateService?.translateMessage(translateParam: translateParam, from: targetVC)
            }
            actions.append(hideTranslatePost)
        @unknown default: break
        }
        if AIFeatureGating.translationOptimizationSwitchLanguage.isUserEnabled(userResolver: context.userResolver) {
            let switchLanguage = UDMenuAction(
                title: BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_SwitchLanguages,
                icon: UDIcon.transSwitchOutlined.ud.withTintColor(.ud.textTitle)) { [weak self] in
                    guard let self = self else { return }
                    guard let targetVC = self.context.pageAPI else {
                        assertionFailure("switchLanguage pageAPI is nil")
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
    }()

    private lazy var translateMoreActionDrawer: TranslateMoreActionDrawer = {
        return TranslateMoreActionDrawer(translateActions: translateActions)
    }()

    func translateMoreTapHandler(_ view: UIView) {
        if Display.pad {
            showTranslateActionPopOver(sourceView: view)
        } else {
            showTranslateActionDrawer()
        }
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
        let menu = UDMenu(actions: translateUDActions, config: config, style: style)
        menu.showMenu(sourceView: sourceView, sourceVC: targetVC)
    }

    private var translateActionDrawer: SelectiveDrawerController?

    private func showTranslateActionDrawer() {
        let headerView = TranslateMoreActionHeaderView()
        let footerView = UIView()
        footerView.backgroundColor = .ud.bgFloatBase
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
            self?.translateActionDrawer = nil
        })
        headerView.didTapCloseButton = { [weak drawer, weak self] in
            drawer?.dismiss(animated: true)
            self?.translateActionDrawer = nil
        }
        self.translateActionDrawer = drawer
        context.navigator(type: .present,
                          controller: drawer,
                          params: nil)
    }

    /// translate Tracking
    var chatTypeForTracking: String {
        if metaModel.getChat().chatMode == .threadV2 {
            return "topic"
        } else if metaModel.getChat().type == .group {
            return "group"
        } else {
            return "single"
        }
    }

    private func trackTranslationActionClicked(clickType: String) {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = metaModel.getChat().id
        trackInfo["chat_type"] = chatTypeForTracking
        trackInfo["msg_id"] = message.id
        trackInfo["message_language"] = message.messageLanguage
        trackInfo["target_language"] = message.translateLanguage
        trackInfo["click"] = clickType
        Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_SUB_CLICK, params: trackInfo))
    }
}
