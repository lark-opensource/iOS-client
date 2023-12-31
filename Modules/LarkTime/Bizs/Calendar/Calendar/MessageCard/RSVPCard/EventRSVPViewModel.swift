//
//  EventRSVPViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/1/12.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import LarkContainer

protocol EventRSVPViewModelContext: ViewModelContext {
    func getEventRSVPBinder(model: EventRSVPModelImpl) -> EventRSVPBinder?
    var scene: LarkMessageBase.ContextScene { get }
    var userResolver: UserResolver { get }
}

final class EventRSVPViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: EventRSVPViewModelContext>: MessageSubViewModel<M, D, C> {
    var eventRSVPComponentProps: RSVPCardComponentProps {
        let cardDataModel = EventRSVPModelImpl(content: content, message: message, primaryCalendarID: primaryCalendarID)
        calendarBinder?.updateModel(cardDataModel)
        let props = calendarBinder?.componentProps ?? RSVPCardComponentProps()
        if let propsPatch = propsPatch {
            return propsPatch(props, self.message)
        }
        return props
    }

    private var propsPatch: ((_ props: RSVPCardComponentProps, _ message: Message) -> RSVPCardComponentProps)?

    private var primaryCalendarID: String? {
        if let calendarManager = try? context.userResolver.resolve(assert: CalendarManager.self) {
            return calendarManager.primaryCalendarID
        }
        return nil
    }

    private lazy var calendarBinder: EventRSVPBinder? = {
        let cardDataModel = EventRSVPModelImpl(content: content, message: message, primaryCalendarID: primaryCalendarID)
        return context.getEventRSVPBinder(model: cardDataModel)
    }()
    private var disposeBag = DisposeBag()
    private var hasTracedView = false
    override var identifier: String {
        return "EventRSVP"
    }

    override var contentConfig: ContentConfig? {
        var config = ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        config.isCard = true
        return config
    }

    var messageId: String {
        return message.id
    }
    var content: GeneralCalendarEventRSVPContent {
        return (message.content as? GeneralCalendarEventRSVPContent)!
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    required init(metaModel: M,
                  metaModelDependency: D,
                  context: C, binder: ComponentBinder<C>,
                  propsPatch: ((_ props: RSVPCardComponentProps, _ message: Message) -> RSVPCardComponentProps)? = nil) {
        self.propsPatch = propsPatch
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
        self.subscribePublish()
    }

    override func willDisplay() {
        super.willDisplay()
        calendarBinder?.maxWidth = contentWidth
        trackCardDisplay()
    }

    private func subscribePublish() {
        calendarBinder?.reloadViewPublish
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                self.syncToBinder()
                self.update(component: self.binder.component, animation: .none)
            }).disposed(by: disposeBag)
    }

    private func trackCardDisplay() {
        if self.hasTracedView { return }
        CalendarTracerV2.EventCard.traceView {
            $0.is_invited = (self.calendarBinder?.componentProps.rsvpStatus != .removed).description
            $0.is_updated = (self.calendarBinder?.componentProps.isUpdated ?? false || self.calendarBinder?.componentProps.isTimeUpdate ?? false || self.calendarBinder?.componentProps.isRruleUpdate ?? false).description
            $0.chat_id = self.content.chatID.description
            $0.event_type = self.content.isWebinar ? "webinar" : "normal"
            $0.is_new_card_type = "true"
            $0.is_support_reaction = "true"
            $0.is_bot = "false"
            $0.is_invited = self.calendarBinder?.componentProps.isJoined.description ?? "false"
            $0.is_share = "false"
            $0.calendar_id = self.content.currentUserMainCalendarId
            $0.is_reply_card = self.calendarBinder?.componentProps.isJoined.description ?? "false"
            $0.mergeEventCommonParams(commonParam: CommonParamData(eventStartTime: self.content.startTime.description,
                                                                   isRecurrence: !self.content.rrepeat.isEmpty,
                                                                   originalTime: self.content.originalTime.description,
                                                                   uid: self.content.key))
        }
    }
    
    override func didEndDisplay() {
        super.didEndDisplay()
        self.disposeBag = DisposeBag()
    }
}
