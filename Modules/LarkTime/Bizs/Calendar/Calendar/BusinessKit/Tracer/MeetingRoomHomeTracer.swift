//
//  MeetingRoomHomeTracer.swift
//  Calendar
//
//  Created by zhuheng on 2022/3/14.
//

import UIKit
import Foundation

class MeetingRoomHomeTracer {
    enum ResourceType: String {
        case building_like
        case hierarchical
    }

    private let tracerID = "perf_cal_resource_main_view"
    private var isDelivered = false
    private var startTime: CFTimeInterval = 0
    private var loadInstanceDone = false

    private var resourceCostTime: Int = 0 // 会议室展示时间 ms
    private var resourceType: ResourceType = .building_like
    private var resourceCount: Int = 0

    func start() {
        startTime = CACurrentMediaTime()
    }

    func cancel() {
        isDelivered = true
    }

    // 记录会议室信息
    func loadBuildingSuccess(with type: ResourceType, count: Int) {
        guard !isDelivered else { return }

        resourceType = type
        resourceCount = count
    }

    func loadInstanceSuccess() {
        guard !isDelivered else { return }

        loadInstanceDone = true
    }

    func renderFinish() {
        guard !isDelivered else { return }

        let now = CACurrentMediaTime()
        if loadInstanceDone {
            let costTime = Int((now - startTime) * 1000)
            // 结束埋点
            CalendarTracer.shareInstance.writeEvent(
                eventId: tracerID,
                params: ["resource_display_type": resourceType.rawValue,
                         "resource_cost_time": resourceCostTime,
                         "data_length": resourceCount,
                         "cost_time": costTime])

            isDelivered = true
        } else {
            // 记录会议室展示时间
            resourceCostTime = Int((now - startTime) * 1000)
        }
    }

}
