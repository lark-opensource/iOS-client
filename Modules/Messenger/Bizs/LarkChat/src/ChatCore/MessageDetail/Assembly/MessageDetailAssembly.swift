//
//  MessageDetailAssembly.swift
//  Action
//
//  Created by 赵冬 on 2019/7/25.
//

import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import LarkRustClient
import LarkCore
import Swinject
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkAssembler
import LarkAI

public final class MessageDetailAssembly: LarkAssemblyInterface {
    public init() { }

    @_silgen_name("Lark.ChatCellFactory.Messenger.MessageDetail")
    static public func cellFactoryRegister() {
        // content
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailTextPostContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailRecalledContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MultiEditComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailImageContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailStickerContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailVideoContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailAudioContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(SelectTranslateFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailFileContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailFolderContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailMergeForwardContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailVoteContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailNewVoteContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailLocationContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DeletedContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)

        // subVM
        MessageDetailMessageSubFactoryRegistery.register(ReplyStatusComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(UrgentTipsComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailUrgentComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(ReactionComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(FlagComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(CountDownStatusComponentFactory.self)
        // 暂时去掉转发提示
//        MessageDetailMessageSubFactoryRegistery.register(ForwardComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(PinComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(ChatPinComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(DlpTipComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(FileNotSafeComponentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailRedPacketContentFactory.self)

        // content
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoMessageDetailTextPostContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(MessageDetailRecalledContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(DecryptedFailedContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoMessageDetailImageContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(MessageDetailStickerContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoMessageDetailAudioContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoMessageDetailFileContentFactory.self)

        CryptoMessageDetailMessageSubFactoryRegistery.register(MessageDetailLocationContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(DeletedContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(BurnedContentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)

        // subVM
        CryptoMessageDetailMessageSubFactoryRegistery.register(ReplyStatusComponentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoUrgentTipsComponentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(MessageDetailUrgentComponentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoReactionComponentFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(CryptoCountDownStatusComponentFactory.self)
    }
}
