//
//  DetailLogic.swift
//  Calendar
//
//  Created by Rico on 2021/9/16.
//

import Foundation
import EventKit
import LarkContainer

/// 对基础数据模型进行业务层的逻辑扩展，仅限日程详情页使用
final class DetailLogicBox<Base>: BizLogicBox {
    let source: Base

    init(source: Base) {
        self.source = source
    }
}

protocol EventDetailLogicExtension {
    associatedtype CalendarCompatibleType
    var dt: CalendarCompatibleType { get }
}

extension EventDetailLogicExtension {
    var dt: DetailLogicBox<Self> {
        DetailLogicBox(source: self)
    }
}

extension EventDetail.Event: EventDetailLogicExtension {}
extension EventDetail.Attendee: EventDetailLogicExtension {}
extension EventDetail.Attendee.Status: EventDetailLogicExtension {}
extension EKEvent: EventDetailLogicExtension {}
