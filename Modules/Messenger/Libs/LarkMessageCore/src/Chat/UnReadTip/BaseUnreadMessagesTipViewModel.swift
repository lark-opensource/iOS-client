//
//  BaseUnreadMessagesTipViewModel.swift
//  Lark
//
//  Created by zc09v on 2018/5/14.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LKCommonsLogging
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface

extension Message: MessageInfoForUnReadTip {
}

extension ThreadMessage: MessageInfoForUnReadTip {
    public var fromChatter: LarkModel.Chatter? {
        return self.rootMessage.fromChatter
    }

    public var isAtAll: Bool {
        return self.rootMessage.isAtAll
    }
}

public enum UnReadMessagesTipState: Equatable {
    case dismiss
    case showToLastMessage
    case showUnReadMessages(Int32, Int32)//标数，readPostion
    case showUnReadAt(MessageInfoForUnReadTip, Int32)//应显示未读at消息,readPostion

    public static func == (lhs: UnReadMessagesTipState, rhs: UnReadMessagesTipState) -> Bool {
        switch (lhs, rhs) {
        case (.dismiss, .dismiss), (.showToLastMessage, .showToLastMessage):
            return true
        case (.showUnReadMessages(let badgeL, let positionL), .showUnReadMessages(let badgeR, let positionR)):
            return badgeL == badgeR && positionL == positionR
        case (.showUnReadAt(let msgL, let positionL), .showUnReadAt(let msgR, let positionR)):
            return msgL.id == msgR.id && positionL == positionR
        default:
            return false
        }
    }

    public var rawValue: Int {
        switch self {
        case .dismiss: return 0
        case .showToLastMessage: return 1
        case .showUnReadMessages: return 2
        case .showUnReadAt: return 3
        }
    }
}

open class BaseUnreadMessagesTipViewModel: UserResolverWrapper {
    public static let logger = Logger.log(BaseUnreadMessagesTipViewModel.self, category: "UnReadMessagesTip")
    public var userResolver: UserResolver
    @ScopedInjectedLazy var myAIService: MyAIService?

    var stateDriver: Driver<UnReadMessagesTipState> {
        return state.asDriver()
    }

    public let state: BehaviorRelay<UnReadMessagesTipState> =
        BehaviorRelay<UnReadMessagesTipState>(value: .dismiss)
    public let disposeBag: DisposeBag = DisposeBag()
    public lazy var dataQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "UnReadMessagesTipViewModelQueue", qos: .userInitiated)
        return queue
    }()

    public lazy var dataScheduler: SerialDispatchQueueScheduler = {
        let scheduler = SerialDispatchQueueScheduler(queue: dataQueue, internalSerialQueueName: dataQueue.label)
        return scheduler
    }()

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    //第一次加载时做一些数据加载工作
    open func fetchDataWhenLoad() {
    }

    /// 有的需求外面要定制显示内容，开一个口子
    open func unReadTip(count: Int32) -> String {
        return count == 1 ? BundleI18n.LarkMessageCore.Lark_Legacy_HasSingleNewMessage : BundleI18n.LarkMessageCore.Lark_Legacy_HasNewMessages
    }
}
