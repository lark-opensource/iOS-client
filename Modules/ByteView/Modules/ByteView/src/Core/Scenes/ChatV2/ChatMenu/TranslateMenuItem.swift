//
//  TranslateMenuItem.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import ByteViewNetwork

class TranslateMenuItem: VCMenuItem {
    enum Action {
        // 翻译
        case translate
        // 查看原文
        case showOriginal
        // 收起译文
        case hideTranslation

        var name: String {
            switch self {
            case .translate: return I18n.View_G_Translate_HoverOption
            case .showOriginal: return I18n.View_G_ViewOriginalText_Option
            case .hideTranslation: return I18n.View_G_HideTranslation_Option
            }
        }

        static func fromRule(_ rule: TranslateDisplayRule) -> Action {
            switch rule {
            case .noTranslation: return .translate
            case .onlyTranslation: return .showOriginal
            case .withOriginal: return .hideTranslation
            default: return .translate
            }
        }
    }

    var name: String { action.name }
    let image = UDIcon.translateOutlined
    var action: Action = .translate
    let model: ChatMessageCellModel

    init(model: ChatMessageCellModel) {
        self.model = model
        self.resetAction()
    }

    var clickHandler: ((TranslateMenuItem) -> Void)?

    func changeToTranslationAction() {
        // 因为部分选中消息固定是划词翻译，所以 action 可能在部分选中时变成 .translation
        action = .translate
    }

    func resetAction() {
        // 根据 model 自身的状态（已翻译、未翻译）来决定 action，适合翻译业务全选一个消息时使用
        action = Action.fromRule(model.translation?.rule ?? .noTranslation)
    }

    func menuItemDidClick() {
        clickHandler?(self)
    }
}
