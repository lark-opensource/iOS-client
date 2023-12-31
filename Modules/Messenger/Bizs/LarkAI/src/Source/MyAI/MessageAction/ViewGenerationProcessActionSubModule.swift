//
//  ViewGenerationProcessActionSubModule.swift
//  LarkAI
//
//  Created by tuwenbo on 2023/9/18.
//

import Foundation
import LarkOpenChat
import LarkMessageBase
import LarkModel
import UniverseDesignIcon
import LarkAccountInterface
import LarkUIKit
import LarkSetting
import EENavigator
import LKCommonsLogging
import LarkCore

public final class ViewGenerationProcessActionSubModule: MessageActionSubModule {

    private let logger = Logger.log(ViewGenerationProcessActionSubModule.self, category: "Module.LarkAI")

    public override class var name: String {
        "ViewGenerationProcessActionSubModule"
    }

    public override var type: MessageActionType {
        .viewGenerationProcess
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        let fg = context.userResolver.fg
        return fg.dynamicFeatureGatingValue(with: "lark.my_ai.qa_white_box")
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let canShow = model.message.canShowAIProgress
        logger.info("canShowAIProgress: \(canShow)")
        return canShow
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkAI.MyAI_IM_ViewGenerationProcess_MenuItem,
                                 icon: UDIcon.getIconByKey(.wikiSubpageOutlined),
                                 trackExtraParams: ["click": "answer_generating_prosess", "target": "none"]) { [weak self] in
            self?.handle(message: model.message,
                         chat: model.chat,
                         selectedType: model.selected())
        }
    }

    private func handle(message: Message, chat: Chat, selectedType: CopyMessageSelectedType) {
        let fullDomain = (try? userResolver.resolve(assert: PassportUserService.self))?.userTenant.tenantFullDomain ?? ""
        guard !fullDomain.isEmpty else {
            logger.warn("domain is empty: \(fullDomain)")
            return
        }
        let addr = "https://\(fullDomain)/myai/answer-process?messageId=\(message.id)&chatId=\(chat.id)"
        if let url = URL(string: addr), let vc = context.targetVC {
            userResolver.navigator.present(url, wrap: LkNavigationController.self, from: vc)
        }
    }

}
