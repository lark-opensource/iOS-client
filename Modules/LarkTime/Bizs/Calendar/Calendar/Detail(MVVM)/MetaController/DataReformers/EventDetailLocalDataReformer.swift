//
//  EventDetailLocalDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import EventKit
import RxSwift

struct EventDetailLocalDataReformer {

    let event: EKEvent
    
    let scene: EventDetailScene

    init(ekEvent: EKEvent, scene: EventDetailScene) {
        self.event = ekEvent
        self.scene = scene
    }
}

extension EventDetailLocalDataReformer {

    var debugDescription: String {
        return """
            EventDetailLocalDataReformer:
            event: \(event.debugDescription)
            """
    }

    var description: String {
        return """
            EventDetailLocalDataReformer:
            event: \(event.description)
            """
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.local.rawValue
    }
}

extension EventDetailLocalDataReformer: EventDetailViewModelDataReformer {
    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        let metaData = EventDetailMetaData(model: EventDetailModel.local(event))
        return .just(EventDetailReformedInfo(metaData: metaData))
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var calEventID: String? = ""
        var key: String? = ""
        var originalTime: Int64? = 0
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: .local)
    }
}
