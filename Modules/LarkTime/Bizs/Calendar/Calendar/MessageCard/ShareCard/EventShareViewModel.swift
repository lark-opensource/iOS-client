//
//  EventShareViewMOdel.swift
//  LarkCalendar
//
//  Created by zoujiayi on 2019/6/26.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import RustPB

protocol EventShareViewModelContext: ViewModelContext {
    func getEventShareBinder(model: EventShareModelImpl) -> EventShareBinder?
    var scene: LarkMessageBase.ContextScene { get }
}

final class EventShareViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: EventShareViewModelContext>: MessageSubViewModel<M, D, C> {
    var eventShareComponentProps: ShareCardComponentProps {
        let cardDataModel = EventShareModelImpl(content: content, message: message, chatId: metaModel.getChat().id)
        calendarBinder?.updateModel(cardDataModel)
        let props = calendarBinder?.componentProps ?? ShareCardComponentProps()

        if let propsPatch = propsPatch {
            return propsPatch(props, self.message)
        }
        return props
    }

    private var propsPatch: ((_ props: ShareCardComponentProps, _ message: Message) -> ShareCardComponentProps)?

    private lazy var calendarBinder: EventShareBinder? = {
        let cardDataModel = EventShareModelImpl(content: content, message: message, chatId: metaModel.getChat().id)
        return context.getEventShareBinder(model: cardDataModel)
    }()
    private var disposeBag = DisposeBag()
    private var hasTracedView = false
    public override var identifier: String {
        return "EventShare"
    }

    public override var contentConfig: ContentConfig? {
        var config = ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        config.isCard = true
        return config
    }

    public var messageId: String {
        return message.id
    }
    public var content: EventShareContent {
        return (message.content as? EventShareContent)!
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    required init(metaModel: M,
                  metaModelDependency: D,
                  context: C, binder: ComponentBinder<C>,
                  propsPatch: ((_ props: ShareCardComponentProps, _ message: Message) -> ShareCardComponentProps)? = nil) {
        self.propsPatch = propsPatch
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override func willDisplay() {
        super.willDisplay()
        self.disposeBag = DisposeBag()
        calendarBinder?.reloadViewPublish.subscribe(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.binder.update(with: self)
            self.update(component: self.binder.component)
        }).disposed(by: disposeBag)
        if !hasTracedView {
            CalendarTracerV2.EventCard.traceView {
                $0.is_invited = self.content.isJoined.description
                $0.is_updated = "false"
                $0.is_share = "true"
                $0.chat_id = self.metaModel.getChat().id
                $0.event_type = self.content.isWebinar ? "webinar" : "normal"
                $0.is_new_card_type = "false"
                $0.is_support_reaction = "false"
                $0.is_bot = "false"
                $0.is_reply_card = self.content.isJoined.description
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.content.eventID,
                                                                       eventStartTime: self.content.startTime.description,
                                                                       isRecurrence: !self.content.rrepeat.isEmpty,
                                                                       originalTime: self.content.originalTime.description,
                                                                       uid: self.content.key))
            }
            hasTracedView = true
        }
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.disposeBag = DisposeBag()
    }

}
