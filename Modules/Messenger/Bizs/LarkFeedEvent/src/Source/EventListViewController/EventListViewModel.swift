//
//  EventListViewModel.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import LKCommonsLogging
import LarkOpenFeed

final class EventListViewModel {
    private let disposeBag = DisposeBag()
    let eventManager: EventManager
    let title: String = BundleI18n.LarkFeedEvent.Lark_Event_EventList_Details_Title

    private let renderSubject = PublishSubject<Void>()
    var renderObservable: Observable<Void> {
        return renderSubject.asObservable()
    }
    private(set) var items: [EventListCellItem] = []

    init(eventManager: EventManager) {
        self.eventManager = eventManager
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
        guard let items = eventItems as? [EventListCellItem] else { return }
        self.items = items
        self.renderSubject.onNext(())
        var map: [EventBiz: [EventListCellItem]] = [:]
        items.forEach { item in
            if var list = map[item.biz] {
                list.append(item)
                map[item.biz] = list
            } else {
                map[item.biz] = [item]
            }
        }
        var listCount: [String: Int] = [:]
        map.forEach { (key: EventBiz, value: [EventListCellItem]) in
            listCount[key.rawValue] = value.count
        }
        EventTracker.List.View(count: items.count, listCount: listCount)
    }

    func clearList() {
        self.eventManager.fillter(items: self.items)
    }
}
