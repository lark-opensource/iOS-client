//
//  LarkByteViewAssembly.swift
//  LarkByteView
//
//  Created by chentao on 2019/4/18.
//

import Foundation
import Swinject
import LarkMessageBase
import LarkMessengerInterface
import EENavigator
import LarkFeatureSwitch
import LarkAssembler
import LarkOpenFeed
import LarkNavigator
import LarkOpenChat
import LarkForward
import LarkOpenSetting
import ByteViewInterface

public final class ByteViewMessengerAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(ShareMeetingBody.self).factory(cache: true, ShareMeetingHandler.init(resolver:))
        Navigator.shared.registerRoute.type(WhiteBoardShareBody.self).factory(cache: true, WhiteBoardShareHandler.init(resolver:))
    }

    @_silgen_name("Lark.ChatCellFactory.ByteView.ChatVC")
    public static func chatCellFactoryRegister() {
        MessageEngineSubFactoryRegistery.register(VChatMeetingCardFactory.self)
        MessageEngineSubFactoryRegistery.register(VChatRoomCardFactory.self)
        MessageEngineSubFactoryRegistery.register(VChatContentFactory.self)

        ChatPinMessageEngineSubFactoryRegistery.register(VChatMeetingCardFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(VChatRoomCardFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(VChatContentFactory.self)

        // Chat Cell
        ChatMessageSubFactoryRegistery.register(VChatContentFactory.self)
        ChatMessageSubFactoryRegistery.register(VChatMeetingCardFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(VChatContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(VChatMeetingCardFactory.self)
        // MergeForward Cell
        MergeForwardMessageSubFactoryRegistery.register(VChatContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(VChatMeetingCardFactory.self)
        // MessageDetail Cell
        MessageDetailMessageSubFactoryRegistery.register(DetailVChatMeetingCardFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(DetailVChatMeetingCardFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DetailVChatMeetingCardFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DetailVChatMeetingCardFactory.self)
        ThreadChatSubFactoryRegistery.register(DetailVChatMeetingCardFactory.self)
        ThreadDetailSubFactoryRegistery.register(DetailVChatMeetingCardFactory.self)

        Feature.on(.voipMessage).apply(on: {
            MessageEngineSubFactoryRegistery.register(VoIPChatContentFactory.self)
            ChatPinMessageEngineSubFactoryRegistery.register(VoIPChatContentFactory.self)
            // Chat Cell
            ChatMessageSubFactoryRegistery.register(VoIPChatContentFactory.self)
            CryptoChatMessageSubFactoryRegistery.register(VoIPChatContentFactory.self)
            // MergeForward Cell
            MergeForwardMessageSubFactoryRegistery.register(VoIPChatContentFactory.self)
        }, downgraded: {})

        ChatMessageSubFactoryRegistery.register(VChatRoomCardFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(VChatRoomCardFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(VChatRoomCardFactory.self)
        CryptoMessageDetailMessageSubFactoryRegistery.register(VChatRoomCardFactory.self)
        ReplyInThreadSubFactoryRegistery.register(VChatRoomCardFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(VChatRoomCardFactory.self)
    }

    @_silgen_name("Lark.Feed.Event.VC")
    public static func eventFactoryRegister() {
        EventFactory.register(providerBuilder: { context, dataCommand -> EventProvider in
            return VCFeedOngoingMeetingEventProvider(userResolver: context, dataCommand: dataCommand)
        })
    }

    @_silgen_name("Lark.Feed.FloatMenu.VC")
    public static func feedFloatMenuRegister() {
        FeedFloatMenuModule.register(VCNewMeetingMenuSubModule.self)
        FeedFloatMenuModule.register(VCJoinMeetingMenuSubModule.self)
        FeedFloatMenuModule.register(VCShareScreenMenuSubModule.self)
    }

    @_silgen_name("Lark.OpenSetting.NotificationSettingVCAssembly")
    public static func pageFactoryNotificationRegister() {
        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.useSystemCall.moduleKey,
                                    provider: NotificationSettingModule.init(userResolver:))
    }

    @_silgen_name("Lark.OpenSetting.CustomizeRingtoneAssembly")
    public static func pageFactoryRingtoneRegister() {
        PageFactory.shared.register(page: .notification,
                                    moduleKey: ModulePair.Notification.customizeRingtone.moduleKey,
                                    provider: CustomRingtoneSettingModule.init(userResolver:))
    }

    @_silgen_name("Lark.OpenSetting.VideoConferenceEntryAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.videoConferenceEntry.moduleKey, provider: { userResolver in
            return GeneralBlockModule(
                userResolver: userResolver,
                title: I18n.View_G_CallsAndMeetings,
                onClickBlock: { (userResolver, vc) in
                    userResolver.navigator.push(body: ByteViewSettingsBody(source: "settings"), from: vc)
                })
        })
    }

    /// 用来注册AlertProvider的类型
    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.VCMessengerAssembly")
    public static func providerRegister() {
        ForwardAlertFactory.register(type: ShareMeetingAlertProvider.self)
        ForwardAlertFactory.register(type: WhiteBoardShareAlertProvider.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: WhiteBoardShareAlertConfig.self)
    }
}
