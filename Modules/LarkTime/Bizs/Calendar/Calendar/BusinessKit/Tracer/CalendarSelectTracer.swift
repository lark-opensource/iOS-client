//
//  CalendarSelectTracer.swift
//  Calendar
//
//  Created by zhuheng on 2022/3/14.
//

import UIKit
import Foundation
import LarkContainer
import RxSwift
import ThreadSafeDataStructure
import LKCommonsLogging

class CalendarSelectTracer: UserResolverWrapper {
    struct TracerParam {
        var calendarID: String
        var selectedTime: CFTimeInterval // 选中时的时间
        var pushCostTime: Int? // 从开始到收到 push 的耗时 ms
        var dataLength: Int? // 收到 push 拉取的 instance 数量
    }

    let pushService: RustPushService
    private let bag: DisposeBag = DisposeBag()

    // 勾选 calendar 后，2 分钟没收到 push 视为超时
    static let maxDurationMS: Double = 2 * 60 * 1000

    private let tracerID = "perf_cal_select_calendar_visible_view"

    private let logger = Logger.log(CalendarSubscribeTracer.self, category: "calendar.select.tracer")
    // 选中的日历
    private var selectedCalendar: SafeDictionary<String, TracerParam> = [:] + .readWriteLock
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        pushService = try self.userResolver.resolve(assert: RustPushService.self)
        pushService.rxCalendarRefresh
            .subscribe(onNext: { [weak self] syncInfos in
                var syncInfoMap = [String: Rust.CalendarSyncInfo]()
                syncInfos.forEach { info in
                    syncInfoMap[info.calendarID] = info
                }
                self?.receivePush(syncInfoMap: syncInfoMap)
            }).disposed(by: bag)
    }

    func start(with calendarID: String) {
        self.selectedCalendar[calendarID] = TracerParam(
            calendarID: calendarID,
            selectedTime: CACurrentMediaTime())
    }

    func receivePush(syncInfoMap: [String: Rust.CalendarSyncInfo]) {
        guard !selectedCalendar.isEmpty, let calendarManager = calendarManager else { return }

        selectedCalendar.safeWrite { dict in
            dict = dict.mapValues({ tracerParam in
                var newParam = tracerParam
                // 以第一次 pushCostTime 为准
                let currentTime = CACurrentMediaTime()

                if let syncInfo = syncInfoMap[tracerParam.calendarID] {
                    let isSyncDone = calendarManager.eventViewStartTime >= syncInfo.minInstanceCacheTime && calendarManager.eventViewEndTime <= syncInfo.maxInstanceCacheTime

                    if newParam.pushCostTime == nil && isSyncDone {
                        newParam.pushCostTime = Int((currentTime - newParam.selectedTime) * 1000)
                    }
                }
                return newParam
            })
        }
    }

    func setDataLength(_ length: Int) {
        guard !selectedCalendar.isEmpty else { return }

        selectedCalendar.safeWrite { dict in
            dict = dict.mapValues({ tracerParam -> TracerParam in
                var newParam = tracerParam
                newParam.dataLength = length
                return newParam
            })
        }
    }

    // 日历下日程为空，直接触发 end，避免不上报
    func endIfNeeded(instance: [Rust.Instance]) {
        func isNoInstances(in calendarID: String, instance: [Rust.Instance]) -> Bool {
            instance.filter { $0.calendarID == calendarID }.isEmpty
        }

        var needEndTrace = false

        selectedCalendar.safeRead { dict in
            dict.forEach { calendarID, param in
                if param.pushCostTime != nil && isNoInstances(in: calendarID, instance: instance) {
                    needEndTrace = true
                }
            }
        }

        if needEndTrace {
            end()
        }
    }

    func end() {
        guard !selectedCalendar.isEmpty else { return }

        let currentTime = CACurrentMediaTime()
        var isDelivered = false
        let viewTypeStr = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode).rawValue
        selectedCalendar.safeRead { dict in
            dict.values.forEach { tracerParam in
                let costTime = Int((currentTime - tracerParam.selectedTime) * 1000)
                if let pushCostTime = tracerParam.pushCostTime,
                   let dataLength = tracerParam.dataLength,
                   pushCostTime < Int(CalendarSelectTracer.maxDurationMS) {
                    logger.info("selectedCalendar end cost \(costTime)")
                    CalendarTracer.shareInstance.writeEvent(
                        eventId: tracerID,
                        params: ["calendar_id": tracerParam.calendarID,
                                 "push_cost_time": pushCostTime,
                                 "data_length": dataLength,
                                 "cost_time": costTime,
                                 "view_type": viewTypeStr])
                    isDelivered = true
                }
            }
        }

        if isDelivered {
            selectedCalendar.removeAll()
        }
    }

}
