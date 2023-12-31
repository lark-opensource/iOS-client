//
//  PinListViewModelDependency.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/17.
//

import Foundation
import RxSwift
import LarkModel
import LarkSDKInterface
import RxCocoa
import LarkCore
import LarkMessengerInterface
import LarkSearchCore

struct PinListViewModelDependency {
    let deletePinPush: Observable<String>
    let messagePush: Observable<Message>
    let is24HourTime: BehaviorRelay<Bool>
    let pinAPI: PinAPI
    let pinReadStatus: Observable<PushChatPinReadStatus>
    let searchCache: SearchCache
    let pinBadgeEnable: Bool
    let searchAPI: SearchAPI
    let currentChatterId: String
    let urlPreviewService: MessageURLPreviewService
    let inlinePreviewVM: MessageInlineViewModel
    init(deletePinPush: Observable<String>,
         messagePush: Observable<Message>,
         is24HourTime: BehaviorRelay<Bool>,
         pinReadStatus: Observable<PushChatPinReadStatus>,
         pinAPI: PinAPI,
         searchCache: SearchCache,
         pinBadgeEnable: Bool,
         searchAPI: SearchAPI,
         currentChatterId: String,
         urlPreviewService: MessageURLPreviewService,
         inlinePreviewVM: MessageInlineViewModel) {
        self.deletePinPush = deletePinPush
        self.messagePush = messagePush
        self.is24HourTime = is24HourTime
        self.pinAPI = pinAPI
        self.pinReadStatus = pinReadStatus
        self.searchCache = searchCache
        self.pinBadgeEnable = pinBadgeEnable
        self.searchAPI = searchAPI
        self.currentChatterId = currentChatterId
        self.urlPreviewService = urlPreviewService
        self.inlinePreviewVM = inlinePreviewVM
    }
}
