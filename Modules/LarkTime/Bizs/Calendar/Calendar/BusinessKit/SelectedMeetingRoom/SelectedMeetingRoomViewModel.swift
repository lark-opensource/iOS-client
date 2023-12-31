//
//  SelectedMeetingRoomViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/5/14.
//

import Foundation
import CalendarFoundation
import RxSwift
import RxRelay

final class SelectedMeetingRoomViewModel {

    typealias DetailData = DetailMeetingRoomCellModel

    struct PassThroughAction {
        let itemDeleteHandler: ((Int) -> Void)?
        let itemFormHandler: ((Int) -> Void)?
        let itemClickHandler: ((Int) -> Void)?
    }

    enum Contents {
        case detail(_ data: DetailData)
        /// 保持和前一个页面的会议室删除、表单更新等数据显示联动
        case edit(_ data: BehaviorRelay<EventEditMeetingRoomViewDataType>, _ passThroughAction: PassThroughAction)
    }

    enum Route {
        case url(url: URL)
        case roomInfo(calendarID: String)
    }

    enum SourceType {
        case detail
        case edit
    }

    let contents: Contents
    let route = PublishRelay<Route>()
    let reloadTrigger = PublishRelay<Void>()
    private let bag = DisposeBag()

    init(contents: Contents) {
        self.contents = contents

        if case let .edit(relay, _) = contents {
            relay.bind { [weak self] _ in
                guard let self = self else { return }
                self.reloadTrigger.accept(())
            }.disposed(by: bag)
        }
    }

    var sourceType: SourceType {
        switch contents {
        case .edit: return .edit
        case .detail: return .detail
        }
    }
}

// 详情逻辑
extension SelectedMeetingRoomViewModel {

    enum DetailClickType {
        case trailingIcon
        case wholeCell
    }

    func clickDetail(on type: DetailClickType, at index: Int) {
        if case let .detail(data) = contents {
            switch type {
            case .wholeCell:
                if let appLink = data.items[safeIndex: index]?.appLink.flatMap { URL(string: $0) } {
                    route.accept(.url(url: appLink))
                }
            case .trailingIcon:
                if let calendarID = data.items[safeIndex: index]?.calendarID {
                    route.accept(.roomInfo(calendarID: calendarID))
                }
            }
        }
    }

    func detailItem(at index: Int) -> DetailMeetingRoomItemContent? {
        if case let .detail(data) = contents {
            return data.items[safeIndex: index]
        }
        return nil
    }
}

// 编辑逻辑
extension SelectedMeetingRoomViewModel {

    enum EditClickType {
        case trailingIcon
        case wholeCell
        case form
    }

    func clickEdit(on type: EditClickType, at index: Int) {
        if case let .edit(_, actions) = contents {
            switch type {
            case .form: actions.itemFormHandler?(index)
            case .trailingIcon: actions.itemDeleteHandler?(index)
            case .wholeCell: actions.itemClickHandler?(index)
            }
        }
    }
}

extension SelectedMeetingRoomViewModel {
    var count: Int {
        switch contents {
        case let .detail(data): return data.items.count
        case let .edit(data, _): return data.value.items.count
        }
    }

    func editItem(at index: Int) -> EventEditMeetingRoomItemDataType? {
        if case let .edit(data, _) = contents {
            return data.value.items[safeIndex: index]
        }
        return nil
    }
}
