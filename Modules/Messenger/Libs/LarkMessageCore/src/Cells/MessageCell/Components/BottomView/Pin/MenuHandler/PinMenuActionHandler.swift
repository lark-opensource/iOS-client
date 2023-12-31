//
//  PinMenuActionHandler.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/5.
//

import Foundation
import UIKit
import LarkModel
import LarkMessageBase
import EENavigator
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface
import LarkCore
import LarkOpenKeyboard

public final class PinMenuActionHandler {
    private var pinAPI: PinAPI?
    private let currentChatterId: String
    private let disposeBag = DisposeBag()

    init(pinAPI: PinAPI?, currentChatterId: String) {
        self.pinAPI = pinAPI
        self.currentChatterId = currentChatterId
    }

    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        let isGroupOwner = self.currentChatterId == chat.ownerId
        self.pinAPI?.createPin(messageId: message.id)
            .subscribe(onNext: { (_) in
                LarkMessageCoreTracker.trackAddPin(message: message,
                                                   chat: chat,
                                                   isGroupOwner: isGroupOwner,
                                                   isSuccess: true)
            }, onError: { (_) in
                LarkMessageCoreTracker.trackAddPin(message: message,
                                                   chat: chat,
                                                   isGroupOwner: isGroupOwner,
                                                   isSuccess: false)
            })
            .disposed(by: self.disposeBag)
    }
}

public final class UnPinMenuActionHandler {
    private let from: PinAlertFrom
    private weak var targetVC: UIViewController?
    private let nav: Navigatable

    public init(targetVC: UIViewController, from: PinAlertFrom, nav: Navigatable) {
        self.targetVC = targetVC
        self.from = from
        self.nav = nav
    }

    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        var body = DeletePinAlertBody(chat: chat,
                                      message: message,
                                      targetVC: targetVC,
                                      from: from,
                                      chatFromWhere: ChatFromWhere(fromValue: params[MessageMenuInfoKey.chatFromWhere] as? String) ?? .ignored)
        body.shareChat = (message.content as? ShareGroupChatContent)?.chat

        if let targetVC = self.targetVC {
            self.nav.push(body: body, from: targetVC)
        }
    }
}
