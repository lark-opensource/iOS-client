//
//  MutePlayMessageActionSubModule.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/16.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import LarkUIKit
import EENavigator
import LarkAssetsBrowser
import LarkContainer
import LarkOpenChat
import LarkAccountInterface

public class MutePlayMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?

    public override var type: MessageActionType {
        return .mutePlay
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard let content = model.message.content as? MediaContent else { return false }
        if content.isPCOriginVideo {
            return false
        } else {
            return true
        }
    }

    public func getMessages(message: Message) -> [Message] {
        guard let chatMessagesService = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self) else { return [] }
        return chatMessagesService.getUIMessages()
    }

    private func handle(message: Message, chat: Chat) {
        guard let chatMessagesService = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self),
              let targetVC = chatMessagesService.pageAPI else { return }

        if let permissionPreview = self.chatSecurityControlService?.checkPermissionPreview(anonymousId: chat.anonymousId, message: message),
           !permissionPreview.0 {
            self.chatSecurityControlService?.authorityErrorHandler(event: .localVideoPreview, authResult: permissionPreview.1, from: targetVC, errorMessage: nil, forceToAlert: true)
            return
        }
        let messages = self.getMessages(message: message)
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: messages,
            selected: message.id,
            cid: message.cid,
            isMeSend: { [weak self] in self?.context.userID ?? "" == $0 }
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }
        result.assets[index].isVideoMuted = true
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .chat(
                chatId: message.channel.id, chatType: chat.type,
                assetPositionMap: result.assetPositionMap
            ),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: !chat.enableRestricted(.download),
            canTranslate: false,
            translateEntityContext: (nil, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward)
        )
        self.context.nav.present(body: body, from: targetVC)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_MessageMenu_PlayOnMute_Button,
                                     icon: BundleResources.Menu.menu_mute_play,
                                     trackExtraParams: ["click": "mute_play_video",
                                                        "target": "none"]) { [weak self] in
                self?.handle(message: model.message, chat: model.chat)
            }
    }
}

public final class MutePlayMessageActionSubModuleInThreadChat: MutePlayMessageActionSubModule {
    // 话题群主界面的静音播放数据源只有当前消息
    public override func getMessages(message: Message) -> [Message] {
        return [message]
    }
}
