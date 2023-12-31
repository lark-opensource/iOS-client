//
//  EventFeedHeaderViewModel.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkTag
import LarkOpenFeed
import LarkContainer

struct EventHeaderViewData {
    let icon: UIImage
    let status: String
    let title: String
    let tags: [LarkTag.Tag]
    let moreMode: Bool
    let closeImage: UIImage
    let numberTitle: String
    let moreImage: UIImage
    let item: EventFeedHeaderViewItem
}

final class EventFeedHeaderViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    let eventManager: EventManager
    let displayRelay = BehaviorRelay<Bool>(value: false)
    let updateHeightRelay = BehaviorRelay<CGFloat>(value: 0)
    let maxHeight: CGFloat = 48
    let context: FeedContextService?
    private(set) var viewData: EventHeaderViewData?
    private let renderSubject = PublishSubject<Void>()
    var renderObservable: Observable<Void> {
        renderSubject.asObservable()
    }

    init(eventManager: EventManager,
         context: FeedContextService?,
         userResolver: UserResolver) {
        self.eventManager = eventManager
        self.context = context
        self.userResolver = userResolver
        self.bind()
    }

    private func bind() {
        eventManager.dataObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                self?.handle(eventItems: data.datas)
        }).disposed(by: disposeBag)
    }

    private func handle(eventItems: [EventItem]) {
        guard let firstEvent = eventItems.first as? EventFeedHeaderViewItem else {
            self.remove()
            return
        }
        let moreMode: Bool
        let numberTitle: String
        let numbers = eventItems.count
        if numbers > 1 {
            moreMode = true
            numberTitle = "+\(numbers - 1)"
        } else {
            moreMode = false
            numberTitle = ""
        }
        let viewData = EventHeaderViewData(icon: firstEvent.icon,
                                           status: firstEvent.status,
                                           title: firstEvent.title,
                                           tags: firstEvent.tagItems,
                                           moreMode: moreMode,
                                           closeImage: Resources.event_close,
                                           numberTitle: numberTitle,
                                           moreImage: Resources.event_more,
                                           item: firstEvent)
        self.show(viewData: viewData)
    }

    private func show(viewData: EventHeaderViewData) {
        EventTracker.Feed.View(eventId: viewData.item.id, type: viewData.item.biz.rawValue)
        self.viewData = viewData
        self.renderSubject.onNext(())
        self.displayRelay.accept(true)
        self.updateHeightRelay.accept(maxHeight)
    }

    private func remove() {
        self.viewData = nil
        self.renderSubject.onNext(())
        self.displayRelay.accept(false)
        self.updateHeightRelay.accept(0)
    }
}

extension EventFeedHeaderViewModel {
    func tap(item: EventItem) {
        item.tap()
    }

    func fillter(item: EventItem) {
        self.eventManager.fillter(item: item)
    }
}
