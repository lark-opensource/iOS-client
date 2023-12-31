//
//  MessageQuickSearchHandler.swift
//  LarkSearch
//
//  Created by ZhangHongyun on 2021/4/11.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import RustPB
import LarkCore
import LarkContainer
import LarkOpenChat
public final class SearchMessageActionSubModule: MessageActionSubModule {
    private static let logger = Logger.log(SearchMessageActionSubModule.self, category: "LarkSearch.MessageQuickSearchHandler")

    public override var type: MessageActionType {
        return .search
    }

    @ScopedInjectedLazy private var modelService: ModelService?

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    private func handle(message: Message, chat: Chat, copyType: CopyMessageType, selectedType: CopyMessageSelectedType) {
        guard let targetVC = context.targetVC else { return }
        let resultAttr: NSAttributedString
        if case .richView(let callback) = selectedType, let (attr, _) = callback() {
            resultAttr = attr
        } else {
            resultAttr = modelService?.copyMessageSummerizeAttr(
                message,
                selectType: selectedType,
                copyType: copyType
            ) ?? NSAttributedString(string: "")
        }
        let body = SearchMainBody(searchText: resultAttr.string,
                                  topPriorityScene: nil,
                                  sourceOfSearch: .messageMenu)
        navigator.push(body: body, from: targetVC)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        switch model.message.type {
        case .text, .post:
            return true
        @unknown default:
            return false
        }
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkSearch.Lark_Legacy_Search,
                                 icon: BundleResources.LarkSearch.menu_search,
                                 trackExtraParams: ["click": "search",
                                                    "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat, copyType: model.copyType, selectedType: model.selected())
        }
    }
}
