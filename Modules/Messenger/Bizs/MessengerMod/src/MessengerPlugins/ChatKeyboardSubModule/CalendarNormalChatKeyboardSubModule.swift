//
//  CalendarNormalChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/13.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkModel
import LarkCore
import LarkChat
import Calendar
import LarkAccountInterface
import LarkMessengerInterface
import LarkUIKit
import EENavigator

public final class CalendarNormalChatKeyboardSubModule: NormalChatKeyboardSubModule {
    /// 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return [calendarEvent].compactMap { $0 }
    }

    private var metaModel: ChatKeyboardMetaModel?

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        self.metaModel = model
    }

    public override func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
    }

    private lazy var calendarEvent: ChatKeyboardMoreItem? = {
        guard let chatModel = self.metaModel?.chat else { return nil }
        if !chatModel.isCrossWithKa,
           !chatModel.isSuper,
           !chatModel.isP2PAi,
           !chatModel.isPrivateMode {
            let item = ChatKeyboardMoreItemConfig(
                text: BundleI18n.Calendar.Lark_Legacy_SideEvent,
                icon: Resources.calendar_event,
                type: .calendarEvent,
                tapped: { [weak self] in
                    self?.clickCalendarEvent()
                })
            return item
        }
        return nil
    }()

    private func clickCalendarEvent() {
        guard let chatModel = self.metaModel?.chat else { return }
        let from = self.context.baseViewController()
        createEvent(from: from, with: chatModel)
        IMTracker.Chat.InputPlus.Click.Event(chatModel)
    }

    @ScopedProvider private var passportService: PassportService?

    func createEvent(from: UIViewController, with chat: Chat) {
        let currentUserId = self.context.userID

        var attendees = [Attendee]()
        switch chat.type {
        case .p2P:
            if let chatter = chat.chatter,
               chatter.type != .bot,
               chatter.id != currentUserId {
                attendees.append(.p2p(chatId: chat.id, chatterId: chatter.id))
            }
        case .group:
            if chat.isMeeting {
                attendees.append(.partialMeetingGroupMembers(chatId: chat.id, memberChatterIds: [currentUserId]))
            } else {
                attendees.append(.partialGroupMembers(chatId: chat.id, memberChatterIds: [currentUserId]))
            }
        @unknown default:
            break
        }
        let presentParam = PresentParam(
            wrap: LkNavigationController.self,
            from: from,
            prepare: {
                $0.modalPresentationStyle = .formSheet
            }
        )
        createEvent(from: from, with: chat, attendees: attendees, startDate: Date().nextHalfHour, presentParam: presentParam)
    }
    public func createEvent(from: UIViewController, with chat: Chat, attendees: [Attendee], startDate: Date, presentParam: PresentParam) {
        let attendees: [CalendarCreateEventBody.Attendee] = attendees.map {
            switch $0 {
            case .p2p(chatId: let chatID, chatterId: let chatterID):
                return .p2p(chatId: chatID, chatterId: chatterID)
            case .partialGroupMembers(chatId: let chatID, memberChatterIds: let memberChatterIds):
                return .partialGroupMembers(chatId: chatID, memberChatterIds: memberChatterIds)
            case .partialMeetingGroupMembers(chatId: let chatID, memberChatterIds: let memberChatterIds):
                return .partialMeetingGroupMembers(chatId: chatID, memberChatterIds: memberChatterIds)
            }
        }
        self.context.nav.present(body: CalendarCreateEventBody(startDate: startDate, attendees: attendees, perferredScene: .edit), presentParam: presentParam)
    }
}
