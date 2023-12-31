//
//  KAMessageActionSubModule.swift
//  LKMessageExternalAssembly
//
//  Created by Ping on 2023/11/21.
//

import LarkModel
import LarkOpenChat
import LarkMessageBase
import LKMessageExternal
import UniverseDesignToast

public class KAMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .ka
    }

    private let factory = OpenMessageMenuItemFactory()

    public override class func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if model.chat.isCrypto || model.chat.isPrivateMode {
            return false
        }
        return !factory.handlers.isEmpty
    }

    public override func createActionItems(model: MessageActionMetaModel) -> [MessageActionItem]? {
        let chat = model.chat
        let context = OpenMessageMenuContext(chat: chat, menuType: .single, messageInfos: [MessageInfo.transform(from: model.message)])
        let items = factory.getMenuItems(context: context)
        return items.filter({ $0.canInitialize(context) }).map({ item in
            return MessageActionItem(text: item.text, icon: item.icon, trackExtraParams: [:]) { [weak self] in
                guard let self = self else { return }
                guard !chat.enableRestricted(.copy), !chat.enableRestricted(.download), !chat.enableRestricted(.forward) else {
                    if let targetVC = self.context.pageAPI {
                        UDToast.showTips(with: BundleI18n.LKMessageExternalAssembly.Lark_IM_RestrictedMode_DownloadImagesVideosFilesNotAllow_Toast, on: targetVC.view)
                    }
                    return
                }
                return item.tapAction(context)
            }
        })
    }
}
