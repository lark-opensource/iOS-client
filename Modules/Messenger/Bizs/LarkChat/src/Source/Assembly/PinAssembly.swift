//
//  PinAssembly.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/22.
//

import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkMessageBase
import LarkMessageCore
import LarkMessengerInterface
import AnimatedTabBar
import LarkNavigation
import LarkTab
import LarkAssembler

public final class PinAssembly: LarkAssemblyInterface {
    public init() { }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(PinListBody.self)
        .factory(PinListHandler.init)
    }

    @_silgen_name("Lark.ChatCellFactory.Messenger.Pin")
    static public func cellFactoryRegister() {
        PinMessageSubFactoryRegistery.register(TextPostContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinAudioContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinLocationContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinFileContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinFolderContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinMergeForwardContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinImageContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinStickerContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinVideoContentFactory.self)
        PinMessageSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        PinMessageSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        PinMessageSubFactoryRegistery.register(PinVoteContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinNewVoteContentFactory.self)
        PinMessageSubFactoryRegistery.register(PinEventShareComponentFactory.self)
        PinMessageSubFactoryRegistery.register(PinEventRSVPComponentFactory.self)
        PinMessageSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        PinMessageSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        PinMessageSubFactoryRegistery.register(FileNotSafeComponentFactory.self)
        PinMessageSubFactoryRegistery.register(PinRoundRobinComponentFactory.self)
        PinMessageSubFactoryRegistery.register(PinAppointmentComponentFactory.self)
    }
}
