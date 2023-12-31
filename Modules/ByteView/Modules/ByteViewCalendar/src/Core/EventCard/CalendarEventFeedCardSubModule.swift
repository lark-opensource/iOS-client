//
//  CalendarEventFeedCardSubModule.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/2.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import CalendarFoundation
import ByteViewNetwork
import ByteViewCommon

final class CalendarEventFeedCardSubModule: EventFeedCardSubModule {
    static var identifier: EventFeedCardType = .vc

    private let userResolver: UserResolver
    private let viewModel: MeetingEventFeedCardModel
    private let cardChangeRelay: PublishRelay<EventFeedCardType>
    let trace: EventFeedCardTrace
    var cards: [EventFeedCardView] = []

    /// cards改变后updateObservable要发送信号
    var updateObservable: Observable<EventFeedCardType> { cardChangeRelay.asObservable() }

    init(userResolver: UserResolver, trace: EventFeedCardTrace) {
        self.userResolver = userResolver
        self.cardChangeRelay = PublishRelay<EventFeedCardType>()
        self.trace = trace
        self.viewModel = MeetingEventFeedCardModel(userResolver: userResolver)
        viewModel.addListener(self)
    }

    /// 侧滑删除
    func removeCard(cardID: String) {
        viewModel.removeMeeting(cardID)
    }

    /// 注销时机
    func destroy() {
        cards = []
    }

    private func updateCards(by infos: [IMNoticeInfo]) {
        Util.runInMainThread {
            self.cards = infos.map { info in
                let cardModel = MeetingEventFeedCardViewModel(userResolver: self.userResolver, vcInfo: info, trace: self.trace)
                let cardView = MeetingEventFeedCardView(model: cardModel)
                cardView.refreshView = { [weak self] in
                    self?.cardChangeRelay.accept(.vc)
                }
                return cardView
            }
            self.cardChangeRelay.accept(.vc)
        }
    }
}

extension CalendarEventFeedCardSubModule: MeetingEventFeedCardModelDelegate {
    func didChangeMeetingInfo(_ infos: [IMNoticeInfo]) {
        updateCards(by: infos)
    }
}
