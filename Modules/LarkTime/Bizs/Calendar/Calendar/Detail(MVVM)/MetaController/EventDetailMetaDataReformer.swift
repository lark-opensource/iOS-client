//
//  EventDetailMetaDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import RxSwift
import RustPB

enum EventDetailEntrancePayload {

    case none
    case chat(_ chatId: String, _ meetingId: String?)
    case rsvpComment(_ rsvpString: String)
    case share(_ canJoin: Bool, _ token: String?, _ messageID: String)

    var rsvpString: String? {
        switch self {
        case .rsvpComment(let string): return string.isEmpty ? nil : string
        default: return nil
        }
    }

    var canJoinIn: Bool {
        switch self {
        case .share(let canJoin, _, _): return canJoin
        default: return false
        }
    }

    var token: String? {
        switch self {
        case .share(_, let token, _): return token
        default: return nil
        }
    }

    var messageID: String {
        switch self {
        case .share(_, _, let messageID): return messageID
        default: return ""
        }
    }

    var chatId: String? {
        switch self {
        case .chat(let chatID, _): return chatID
        default: return nil
        }
    }
    
    var meetingId: String? {
        switch self {
        case .chat(_, let meetingId): return meetingId
        default: return nil
        }
    }
}

struct EventDetailMetaData {
    /// 日程数据
    let model: EventDetailModel

    /// 入口所携带的附加数据
    let payload: EventDetailEntrancePayload

    init(model: EventDetailModel,
         payload: EventDetailEntrancePayload = .none) {
        self.model = model
        self.payload = payload
    }

    func updatedEvent(with event: EventDetail.Event, calendar: CalendarModel) -> Self? {
        if case let .pb(_, oldInstance) = model {
            let startTime: Int64
            let endTime: Int64

            // 非重复性日程 startTime/endTime 以 event 为准
            // 重复性日程需通过 rrule 计算 instance，暂不支持刷新时间
            if event.rrule.isEmpty {
                startTime = event.startTime
                endTime = event.endTime
            } else {
                startTime = oldInstance.startTime
                endTime = oldInstance.endTime
            }

            let newInstance = event.dt.makeInstance(with: calendar,
                                                    startTime: startTime,
                                                    endTime: endTime)
            return .init(model: .pb(event, newInstance),
                         payload: payload)
        }
        return nil
    }

    func updatedModel(with model: EventDetailModel) -> Self {
        return .init(model: model, payload: payload)
    }
}

extension EventDetailMetaData: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        return """
        model: \(model.description),
        payload: \(payload)
        """
    }

    var debugDescription: String {
        return """
        model: \(model.debugDescription),
        payload: \(payload)
        """
    }
}

struct EventDetailReformedInfo {

    // 日程详情页源数据
    let metaData: EventDetailMetaData
    // 是否需要从服务端二次更新数据
    let needRefreshFromServer: Bool

    init(metaData: EventDetailMetaData,
         needRefreshFromServer: Bool = false) {
        self.metaData = metaData
        self.needRefreshFromServer = needRefreshFromServer
    }
}

protocol EventDetailViewModelDataReformer: CustomStringConvertible, CustomDebugStringConvertible, MonitorDescription {
    /// 入口类型
    var scene: EventDetailScene { get }
    /// 从各入口源数据转化为视图详情页所需要的格式数据， Error类型要求是 ⚠️EventDetailMetaError⚠️
    func reformToViewModelData() -> Single<EventDetailReformedInfo>
    /// 用于从Reformer便捷获取原始数据 - for Tracker
    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource)
}
