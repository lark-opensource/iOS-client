//
//  PostMenuItemGenerator.swift
//  Moment
//
//  Created by zc09v on 2021/1/11.
//

import UIKit
import Foundation
import LarkMenuController
import LarkMessageBase
import LarkContainer
import LarkSDKInterface
import LarkMessageCore
import LarkEmotion
import LarkCore
import UniverseDesignToast
import LarkModel
import LarkFoundation
import LarkExtensions
import LarkMessengerInterface
import EENavigator
import LarkFeatureGating
import LarkEmotionKeyboard
import LarkRichTextCore
import LarkEMM
import UniverseDesignIcon

protocol MenuItemGeneratorDelegate: AnyObject {
    func richTextForCopy() -> RawData.RichText?
    func doReaction(type: String)
    func doReply()
    func delete()
    func report()
    func didCopyContent() //复制内容后需要执行的事，例如上报审计行为
    func translate()
    func hideTranslation()
    func changeTranslationLanguage()
}

extension MenuItemGeneratorDelegate {
    func richTextForCopy() -> RawData.RichText? {
        return nil
    }

    func doReaction(type: String) {
    }

    func doReply() {
    }

    func delete() {
    }

    func report() {
    }

    func didCopyContent() {
    }

    func translate() {
    }

    func hideTranslation() {
    }

    func changeTranslationLanguage() {
    }

}

final class MenuItemGenerator: UserResolverWrapper {
    enum MenuType {
        case reply(enable: Bool)
        case reaction
        case copy
        case delete
        case report
        case translate
        /// 隐藏翻译
        case hideTranslation
        /// 显示原文（点击效果和隐藏翻译一样，icon和title不一样）
        case showSourceText
        case changeTranslationLanguage
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private let copyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy")

    final class MenueItemResult {
        // 最近使用的表情菜单项
        var recentReactionMenuItems: [MenuReactionItem]
        // 所有的表情菜单项
        var allReactionMenuItems: [MenuReactionItem]
        // 所有的表情分类
        var allReactionGroups: [ReactionGroup]
        // 操作菜单项
        var actionItems: [MenuActionItem]
        init(recentReactionMenuItems: [MenuReactionItem], allReactionMenuItems: [MenuReactionItem], allReactionGroups: [ReactionGroup], actionItems: [MenuActionItem]) {
            self.recentReactionMenuItems = recentReactionMenuItems
            self.allReactionMenuItems = allReactionMenuItems
            self.allReactionGroups = allReactionGroups
            self.actionItems = actionItems
        }

        var isEmpty: Bool {
            return self.recentReactionMenuItems.isEmpty && self.allReactionMenuItems.isEmpty && self.allReactionGroups.isEmpty && self.actionItems.isEmpty
        }
    }

    @ScopedInjectedLazy private var reactionService: ReactionService?
    @ScopedInjectedLazy private var modelService: ModelService?

    weak var delegate: MenuItemGeneratorDelegate?

    func generate(menuTypes: [MenuItemGenerator.MenuType]) -> MenueItemResult {
        let types = menuTypes
        // 操作菜单项
        var actionItems: [MenuActionItem] = []
        // 最近使用的表情菜单项
        var recentReactionMenuItems: [MenuReactionItem] = []
        // 所有的表情菜单项
        var allReactionMenuItems: [MenuReactionItem] = []
        // 所有的表情分类
        var allReactionGroups: [ReactionGroup] = []
        if types.contains(where: { type in
            switch type {
            case .reaction:
                return true
            default:
                return false
            }
        }) {
            // 处理用户的表情：最常使用fg打开返回最常使用，反之返回最近使用
            var userReactions = reactionService?.getRecentReactions().map { $0.key } ?? []
            userReactions = Array(userReactions.prefix(6))
            recentReactionMenuItems = userReactions.map { (reactionType) -> MenuReactionItem in
                let entity = ReactionEntity(key: reactionType,
                                            selectSkinKey: reactionType,
                                            skinKeys: [],
                                            size: EmotionResouce.shared.sizeBy(key: reactionType))
                return MenuReactionItem(reactionEntity: entity) { [weak self] (type) in
                    self?.delegate?.doReaction(type: type)
                }
            }
            // 处理所有分类表情
            allReactionGroups = reactionService?.getAllReactions() ?? []
            // 取出分类里面的所有表情（拍平数组）
            var allReactions = allReactionGroups.flatMap({ $0.entities })
            if allReactions.isEmpty {
                allReactions = EmotionResouce.reactions.map { reaction in
                    ReactionEntity(key: reaction,
                                   selectSkinKey: reaction,
                                   skinKeys: EmotionResouce.shared.skinKeysBy(key: reaction),
                                   size: EmotionResouce.shared.sizeBy(key: reaction))
                }
            }
            allReactionMenuItems = allReactions.map({ (reaction) -> MenuReactionItem in
                return MenuReactionItem(reactionEntity: reaction) { [weak self] (type) in
                    self?.delegate?.doReaction(type: type)
                }
            })
        }

        var replyEnable = false
        if types.contains(where: { type in
            switch type {
            case .reply(let enable):
                replyEnable = enable
                return true
            default:
                return false
            }
        }) {
            let replyItem = MenuActionItem(name: BundleI18n.Moment.Lark_Community_Reply,
                                          image: replyEnable ? Resources.menuReply : Resources.menuReplyDisabled,
                                          enable: replyEnable) { [weak self] (_) in
                self?.delegate?.doReply()
            }
            actionItems.append(replyItem)
        }

        if types.contains(where: { type in
            switch type {
            case .copy:
                return true
            default:
                return false
            }
        }), let richText = delegate?.richTextForCopy() {
            let copyItem = MenuActionItem(name: BundleI18n.Moment.Lark_Community_Copy,
                                          image: Resources.menuCopy,
                                          enable: true) { [weak self] (_) in
                guard let self = self, let modelService = self.modelService else { return }
                // 复制逻辑
                let resultAttr = modelService.copyStringAttr(richText: richText, docEntity: nil,
                                                             selectType: .all, urlPreviewProvider: nil,
                                                             hangPoint: [:], copyValueProvider: nil,
                                                             userResolver: self.userResolver)
                if CopyToPasteboardManager.copyToPasteboardFormAttribute(resultAttr,
                                                                         fileAuthority: .canCopy(false),
                                                                         pasteboardToken: "LARK-PSDA-moment-cell-menu-copy-permission",
                                                                         fgService: self.userResolver.fg) {
                    guard let window = self.userResolver.navigator.mainSceneWindow else {
                        assertionFailure("缺少 window")
                        return
                    }
                    UDToast.showSuccess(with: BundleI18n.Moment.Lark_Legacy_JssdkCopySuccess, on: window)
                } else {
                    guard let window = self.userResolver.navigator.mainSceneWindow else {
                        assertionFailure("缺少 window")
                        return
                    }
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
                }
                self.delegate?.didCopyContent()
            }
            actionItems.append(copyItem)
        }

        if types.contains(where: { type in
            switch type {
            case .translate:
                return true
            default:
                return false
            }
        }) {
            let translateItem = MenuActionItem(name: BundleI18n.Moment.Moments_Translate_Button_Mobile,
                                          image: UDIcon.translateOutlined,
                                          enable: true) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.translate()
            }
            actionItems.append(translateItem)
        }

        if types.contains(where: { type in
            switch type {
            case .hideTranslation:
                return true
            default:
                return false
            }
        }) {
            let hideTranslationItem = MenuActionItem(name: BundleI18n.Moment.Moments_HideTranslatedText_Button_Mobile,
                                          image: UDIcon.visibleLockOutlined,
                                          enable: true) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.hideTranslation()
            }
            actionItems.append(hideTranslationItem)
        }

        if types.contains(where: { type in
            switch type {
            case .showSourceText:
                return true
            default:
                return false
            }
        }) {
            let showSourceTextItem = MenuActionItem(name: BundleI18n.Moment.Moments_ShowSourceText_Button_Mobile,
                                          image: UDIcon.translateOutlined,
                                          enable: true) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.hideTranslation()
            }
            actionItems.append(showSourceTextItem)
        }

        if types.contains(where: { type in
            switch type {
            case .changeTranslationLanguage:
                return true
            default:
                return false
            }
        }) {
            let changeTranslationLanguageItem = MenuActionItem(name: BundleI18n.Moment.Moments_SwitchLanguages_Button_Mobile,
                                          image: UDIcon.transSwitchOutlined,
                                          enable: true) { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.changeTranslationLanguage()
            }
            actionItems.append(changeTranslationLanguageItem)
        }

        if types.contains(where: { type in
            switch type {
            case .delete:
                return true
            default:
                return false
            }
        }) {
            let deleteItem = MenuActionItem(name: BundleI18n.Moment.Lark_Community_Delete,
                                            image: Resources.menuDelete,
                                            enable: true) { [weak self] (_) in
                self?.delegate?.delete()
            }
            actionItems.append(deleteItem)
        }
        if types.contains(where: { type in
            switch type {
            case .report:
                return true
            default:
                return false
            }
        }) {
            let reportItem = MenuActionItem(name: BundleI18n.Moment.Lark_Community_Report,
                                            image: Resources.menuReport,
                                            enable: true) { [weak self] (_) in
                self?.delegate?.report()
            }
            actionItems.append(reportItem)
        }

        return MenueItemResult(recentReactionMenuItems: recentReactionMenuItems, allReactionMenuItems: allReactionMenuItems, allReactionGroups: allReactionGroups, actionItems: actionItems)
    }
}
