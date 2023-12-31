//
//  PinConfirmAlertFactory.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import UIKit
import Foundation
import LarkModel
import LarkFeatureGating
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer

public protocol PinAlertProvider {
    var checkIsMe: (String) -> Bool { get }
    var getSenderName: (Chatter) -> String { get }
    var eventTimeDescription: (_ start: Int64, _ end: Int64, _ isAllDay: Bool) -> String { get }
    var hasJoinedChat: Bool { get }
    var abbreviationEnable: Bool { get }
    var permissionPreview: (Bool, ValidateResult?) { get }
    var dynamicAuthorityEnum: DynamicAuthorityEnum { get }
    var settingGifLoadConfig: GIFLoadConfig? { get }
}

public final class PinAlertViewModelProvider: PinAlertProvider {
    public var getSenderName: (Chatter) -> String
    public var checkIsMe: (String) -> Bool
    public var eventTimeDescription: (_ start: Int64, _ end: Int64, _ isAllDay: Bool) -> String
    public var hasJoinedChat: Bool
    public var abbreviationEnable: Bool
    public var permissionPreview: (Bool, ValidateResult?)
    public var dynamicAuthorityEnum: DynamicAuthorityEnum
    public var settingGifLoadConfig: GIFLoadConfig?

    public init(checkIsMe: @escaping (String) -> Bool,
                hasJoinedChat: Bool,
                abbreviationEnable: Bool,
                getSenderName: @escaping (Chatter) -> String,
                eventTimeDescription: @escaping (_ start: Int64, _ end: Int64, _ isAllDay: Bool) -> String,
                permissionPreview: (Bool, ValidateResult?),
                dynamicAuthorityEnum: DynamicAuthorityEnum,
                settingGifLoadConfig: GIFLoadConfig?
                ) {
        self.checkIsMe = checkIsMe
        self.getSenderName = getSenderName
        self.eventTimeDescription = eventTimeDescription
        self.hasJoinedChat = hasJoinedChat
        self.abbreviationEnable = abbreviationEnable
        self.permissionPreview = permissionPreview
        self.dynamicAuthorityEnum = dynamicAuthorityEnum
        self.settingGifLoadConfig = settingGifLoadConfig
    }
}

final class PinConfirmAlertFactory {
    class func createPinConfirmAlertView(userResolver: UserResolver, _ message: Message, dataProvider: PinAlertProvider) -> UIView? {
        switch message.type {
        case .text:
            guard let viewModel = TextPinConfirmViewModel(
                userResolver: userResolver,
                message: message,
                checkIsMe: dataProvider.checkIsMe,
                abbreviationEnable: dataProvider.abbreviationEnable,
                getSenderName: dataProvider.getSenderName
                ) else {
                    return nil
            }
            let textView = TextPinConfirmView()
            textView.alertViewModel = viewModel
            setBaseStyle(textView)
            return textView
        case .post:
            guard let viewModel = PostPinConfirmViewModel(
                userResolver: userResolver,
                message: message,
                checkIsMe: dataProvider.checkIsMe,
                abbreviationEnable: dataProvider.abbreviationEnable,
                getSenderName: dataProvider.getSenderName
                ) else {
                    return nil
            }
            let postView = PostPinConfirmView()
            postView.alertViewModel = viewModel
            setBaseStyle(postView)
            return postView
        case .audio:
            guard let viewModel = AudioPinConfirmViewModel(userResolver: userResolver, audioMessage: message, getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let audioView = AudioPinConfirmView()
            audioView.alertViewModel = viewModel
            setBaseStyle(audioView)
            return audioView
        case .media:
            guard let viewModel = VideoPinConfirmViewModel(mediaMessage: message,
                                                           permissionPreview: dataProvider.permissionPreview,
                                                           dynamicAuthorityEnum: dataProvider.dynamicAuthorityEnum,
                                                           getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let mediaView = VideoPinConfirmView()
            mediaView.alertViewModel = viewModel
            mediaView.cornerRadius = 8
            setBaseStyle(mediaView)
            return mediaView
        case .image:
            guard let viewModel = ImagePinConfirmViewModel(imageMessage: message,
                                                           permissionPreview: dataProvider.permissionPreview,
                                                           dynamicAuthorityEnum: dataProvider.dynamicAuthorityEnum,
                                                           getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let imagePinView = ImagePinConfirmView()
            imagePinView.alertViewModel = viewModel
            setBaseStyle(imagePinView)
            return imagePinView
        case .location:
            guard let viewModel = LocationPinConfirmViewModel(locationMessage: message,
                                                              getSenderName: dataProvider.getSenderName,
                                                              settingGifLoadConfig: dataProvider.settingGifLoadConfig) else {
                return nil
            }
            let locationPinView = LocationPinConfirmView()
            locationPinView.alertViewModel = viewModel
            setBaseStyle(locationPinView)
            return locationPinView
        case .sticker:
            guard let viewModel = StickerPinConfirmViewModel(stickerMessage: message, getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let stickerPinView = StickerPinConfirmView()
            stickerPinView.alertViewModel = viewModel
            setBaseStyle(stickerPinView)
            return stickerPinView
        case .shareCalendarEvent:
            guard let viewModel = CalendarSharePinConfirmViewModel(shareEventMessage: message,
                                                                      getSenderName: dataProvider.getSenderName,
                                                                      eventTimeDescription: dataProvider.eventTimeDescription) else {
                return nil
            }
            let shareEventView = CalendarSharePinConfirmView()
            shareEventView.alertViewModel = viewModel
            setBaseStyle(shareEventView)
            return shareEventView
        case .todo:
            guard let viewModel = TodoPinConfirmViewModel(
                    todoMessage: message,
                    getSenderName: dataProvider.getSenderName
            ) else { return nil }
            let view = TodoPinConfirmView()
            view.alertViewModel = viewModel
            setBaseStyle(view)
            return view
        case .file, .folder:
            guard let viewModel = FileAndFolderPinConfirmViewModel(userResolver: userResolver, fileMessage: message, getSenderName: dataProvider.getSenderName,
                                                                   hasPermissionPreview: dataProvider.permissionPreview.0,
                                                                   dynamicAuthorityEnum: dataProvider.dynamicAuthorityEnum) else {
                return nil
            }
            let fileView = FileAndFolderPinConfirmView(userResolver: userResolver, frame: .zero)
            fileView.alertViewModel = viewModel
            setBaseStyle(fileView)
            return fileView
        case .mergeForward:
            return mergeForwardViewForMessage(userResolver: userResolver, message, dataProvider: dataProvider)
        case .card:
            if let content = message.content as? CardContent, content.type == .vote {
                guard let viewModel = VotePinConfirmViewModel(cardMessage: message, getSenderName: dataProvider.getSenderName) else {
                    return nil
                }
                let voteView = VotePinConfirmView()
                voteView.alertViewModel = viewModel
                setBaseStyle(voteView)
                return voteView
            } else if let content = message.content as? CardContent,
                      userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messagecard.pin.support")),
                      content.type == .text || content.type == .openCard,
                      // 不支持临时消息和 v1 旧版卡片的 pin 功能(样式不符合预期)
                      !message.isEphemeral, content.version >= 2 {
                let viewModel = MessageCardPinConfirmViewModel(cardMessage: message, content: content, getSenderName: dataProvider.getSenderName)
                let view = MessageCardPinConfirmView(userResolver: userResolver, frame: .zero)
                view.alertViewModel = viewModel
                return view
            } else {
                return Self.generateUnknownPinConfirmView(message: message, getSenderName: dataProvider.getSenderName)
            }
        case .shareGroupChat:
            guard let viewModel = ShareGroupPinConfirmViewModel(ShareGroupMessage: message,
                                                                   getSenderName: dataProvider.getSenderName,
                                                                   hasJoinedChat: dataProvider.hasJoinedChat) else {
                return nil
            }
            let shareGroupView = ShareGroupPinConfirmView()
            shareGroupView.alertViewModel = viewModel
            setBaseStyle(shareGroupView)
            return shareGroupView
        case .shareUserCard:
            guard let viewModel = ShareUserCardPinConfirmViewModel(shareUserCardMessage: message, getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let shareUserCardView = ShareUserCardPinConfirmView()
            shareUserCardView.alertViewModel = viewModel
            setBaseStyle(shareUserCardView)
            return shareUserCardView
        case .vote:
            guard let viewModel = NewVotePinConfirmViewModel(voteMessage: message, getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let votePinConfirmView = NewVotePinConfirmView()
            votePinConfirmView.alertViewModel = viewModel
            setBaseStyle(votePinConfirmView)
            return votePinConfirmView
        case .generalCalendar:
            if message.content is GeneralCalendarEventRSVPContent {
                guard let viewModel = CalendarRSVPPinConfirmViewModel(rsvpEventMessage: message,
                                                                      getSenderName: dataProvider.getSenderName,
                                                                      eventTimeDescription: dataProvider.eventTimeDescription) else {
                    return nil
                }
                let rsvpEventView = CalendarRSVPPinConfirmView()
                rsvpEventView.alertViewModel = viewModel
                setBaseStyle(rsvpEventView)
                return rsvpEventView
            } else if  message.content is RoundRobinCardContent {
                guard let viewModel = SchedulerRoundRobinPinConfirmViewModel(message: message,
                                                                             getSenderName: dataProvider.getSenderName,
                                                                             eventTimeDescription: dataProvider.eventTimeDescription) else {
                    return nil
                }
                let roundRobinPinView = PinSchedulerRoundRobinPinConfirmView()
                roundRobinPinView.alertViewModel = viewModel
                setBaseStyle(roundRobinPinView)
                return roundRobinPinView
            } else if  message.content is SchedulerAppointmentCardContent {
                guard let viewModel = PinSchedulerAppointmentConfirmViewModel(message: message,
                                                                              getSenderName: dataProvider.getSenderName,
                                                                              eventTimeDescription: dataProvider.eventTimeDescription) else {
                    return nil
                }
                let appointmentPinView = PinSchedulerAppointmentConfirmView()
                appointmentPinView.alertViewModel = viewModel
                setBaseStyle(appointmentPinView)
                return appointmentPinView
            } else {
                return Self.generateUnknownPinConfirmView(message: message, getSenderName: dataProvider.getSenderName)
            }
        case .unknown, .calendar, .system, .email,
                .hongbao, .commercializedHongbao, .videoChat, .diagnose:
            return Self.generateUnknownPinConfirmView(message: message, getSenderName: dataProvider.getSenderName)
        @unknown default:
            return Self.generateUnknownPinConfirmView(message: message, getSenderName: dataProvider.getSenderName)
        }
    }

    private class func generateUnknownPinConfirmView(message: Message, getSenderName: @escaping (Chatter) -> String) -> UnknownPinConfirmView {
        let confirmView = UnknownPinConfirmView()
        confirmView.alertViewModel = UnknownPinConfirmViewModel(message: message, getSenderName: getSenderName)
        Self.setBaseStyle(confirmView)
        return confirmView
    }

    private class func setBaseStyle(_ view: UIView) {
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        view.layer.borderWidth = 1
        view.layer.ud.setBorderColor(UIColor.ud.N300)
    }

    private class func mergeForwardViewForMessage(userResolver: UserResolver, _ message: Message, dataProvider: PinAlertProvider) -> UIView? {
        if let content = message.content as? MergeForwardContent,
           content.isFromPrivateTopic {
            guard let viewModel = MergeForwardCardPinConfirmViewModel(userResolver: userResolver, mergeMessage: message,
                                                                      getSenderName: dataProvider.getSenderName) else {
                return nil
            }
            let cardView: MergeForwardCardPinConfirmView
            if let thread = content.thread, thread.isReplyInThread {
                cardView = ReplyInThreadMergeForwardCardPinConfirmView()
            } else {
                cardView = MergeForwardCardPinConfirmView()
            }
            cardView.alertViewModel = viewModel
            setBaseStyle(cardView)
            return cardView

        } else {
            guard let viewModel = MergeForwardPinConfirmViewModel(
                userResolver: userResolver,
                mergeMessage: message,
                getSenderName: dataProvider.getSenderName
            ) else {
                return nil
            }
            let mergeForwardView = MergeForwardPinConfirmView()
            mergeForwardView.alertViewModel = viewModel
            setBaseStyle(mergeForwardView)
            return mergeForwardView
        }
    }
}
