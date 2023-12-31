//
//  EventFeedCardSubModule.swift
//  CalendarFoundation
//
//  Created by chaishenghua on 2023/8/1.
//

import LarkContainer
import RxSwift

public protocol EventFeedCardSubModule {
    init(userResolver: UserResolver, trace: EventFeedCardTrace)

    static var identifier: EventFeedCardType { get }

    var cards: [EventFeedCardView] { get }

    /// cards改变后updateObservable要发送信号
    var updateObservable: Observable<EventFeedCardType> { get }

    /// 侧滑删除
    func removeCard(cardID: String)

    /// 注销时机
    func destroy()
}
