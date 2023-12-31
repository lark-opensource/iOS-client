//
//  MessengerMockDependency+Contact.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import Swinject
import LarkMessengerInterface
import LarkContact
import LKCommonsLogging
import LarkContainer
#if ByteViewMod
import ByteViewInterface
#endif
#if CalendarMod
import Calendar
#endif
#if GagetMod
import LarkOPInterface
#endif

public final class ContactDependencyImpl: ContactDependency {

    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func joinMeetingByNumber(meetingNumber: String, entrySource: ChatMeetingSource) {
        #if ByteViewMod
        let body = JoinMeetingBody(id: meetingNumber, idType: .number, entrySource: .meetingLinkJoin)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    public func redirectToAppDetailBody(response: EENavigator.Response, botID: String, fromWhere: PersonCardFromWhere, chatID: String, extraParams: [String: String]?) {
        #if GagetMod
        var scene: AppDetailOpenScene?
        if fromWhere == .groupBotToAdd {
            scene = .groupBotToAdd
        } else if fromWhere == .groupBotToRemove {
            scene = .groupBotToRemove
        }
        let body = AppDetailBody(botId: botID, params: extraParams ?? [:], scene: scene, chatID: chatID)
        response.redirect(body: body)
        #endif
    }

    // 控制是否有byteview集成并做入口控制
    public func hasByteView() -> Bool {
        #if ByteViewMod
        true
        #else
        false
        #endif
    }
    public func startByteViewFromRightUpCornerButton(userId: String) {
        #if ByteViewMod
        let body = StartMeetingBody(userId: userId, isVoiceCall: false, entrySource: .rightUpCornerButton)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    public func startByteViewFromAddressBookCard(userId: String) {
        #if ByteViewMod
        let body = StartMeetingBody(userId: userId, isVoiceCall: false, entrySource: .addressBookCard)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }
}
