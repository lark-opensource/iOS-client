//
//  EventDetailTableConflictViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2023/10/18.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import CalendarFoundation
import RustPB
import CTFoundation

class EventDetailTableConflictViewModel: EventDetailComponentViewModel {

    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.payload) var payload
    @ContextObject(\.scene) var scene
    @ContextObject(\.options) var options

    @ScopedInjectedLazy var api: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    private let disposeBag = DisposeBag()

    private lazy var serialSchedulerQueue = SerialDispatchQueueScheduler(qos: .userInteractive)

    let timezone = TimeZone.current
    private(set) lazy var rxConflictModel: BehaviorRelay<EventConflictModel> = .init(value: defaultConflictModel)

    var model: EventDetailModel {
        self.rxModel.value
    }

    var is12HourStyle: Bool {
        calendarDependency?.is12HourStyle.value ?? true
    }
    
    /// 是否加入日程
    var isJoined: Bool {
        /// 参考详情页底部 showJoinButton 逻辑
        let eventCalendarId = self.model.calendarId
        let currentUserCalendarId = self.calendarManager?.primaryCalendarID ?? ""
        let eventForReview = !(currentUserCalendarId == eventCalendarId)
        return !(options.contains(.needCalculateIsForReview) && eventForReview)
    }

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)
        bindRx()
    }

    private func bindRx() {
        rxModel
            .observeOn(serialSchedulerQueue)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchConflictData()
            }).disposed(by: disposeBag)
    }
}

extension EventDetailTableConflictViewModel {
    
    private func fetchConflictData() {
        guard let event = rxModel.value.event else {
            assertionFailure("no event")
            return
        }

        let observable: Observable<EventConflictModel?>
        switch scene {
        case .chat:
            observable = getMeetingConflict()
        case .url, .shareCard:
            observable = getDayInstancesForEventConflictWithEvent(event)
        default:
            observable = getDayInstancesForEventConflict(event)
        }
        observable
            .catchErrorJustReturn(nil)
            .subscribe(onNext: { [weak self] model in
                self?.sendToConflictModel(model)
            }).disposed(by: disposeBag)
    }

    /// 从会议群场景进入
    private func getMeetingConflict() -> Observable<EventConflictModel?> {
        guard let meetingId = payload.meetingId,
              let api = api else {
            assertionFailure("getMeetingConflict no chatId")
            return .just(nil)
        }
        return api.getMeetingConflict(meetingId: meetingId)
            .observeOn(serialSchedulerQueue)
            .map({ res -> EventConflictModel? in
                return EventConflictModel(
                    conflictType: res.conflictType,
                    conflictTime: res.conflictTime,
                    dayInstances: res.dayInstances,
                    event: res.event,
                    displayOriginalTime: res.displayOriginalTime,
                    nextStartTime: res.nextStartTime
                )
            })
    }

    /// 分享/链接场景进入
    private func getDayInstancesForEventConflictWithEvent(_ event: Rust.Event) -> Observable<EventConflictModel?> {
        guard let api = api else { return .just(nil) }
        return api.getDayInstancesForEventConflictWithEvent(event: event)
            .observeOn(serialSchedulerQueue)
            .map({ res -> EventConflictModel? in
                return EventConflictModel(
                    conflictType: res.conflictType,
                    conflictTime: res.conflictTime,
                    dayInstances: res.dayInstances,
                    event: res.event,
                    displayOriginalTime: res.displayOriginalTime,
                    nextStartTime: nil
                )
            })
    }

    /// 卡片、事件、vc场景进入
    private func getDayInstancesForEventConflict(_ event: Rust.Event) -> Observable<EventConflictModel?> {
        guard let api = api else { return .just(nil) }
        return api.getDayInstancesForEventConflict(
            rrule: event.rrule,
            timezone: timezone.identifier,
            startTime: event.startTime,
            endTime: event.endTime,
            isAllDay: event.isAllDay,
            eventSerId: event.serverID,
            eventCalendarId: event.calendarID
        )
        .observeOn(serialSchedulerQueue)
        .map({ res -> EventConflictModel? in
            return EventConflictModel(
                conflictType: res.conflictType,
                conflictTime: res.conflictTime,
                dayInstances: res.dayInstances,
                event: res.event,
                displayOriginalTime: res.displayOriginalTime,
                nextStartTime: nil
            )
        })
    }
}

extension EventDetailTableConflictViewModel {
    /// 详情页展示的 instance
    var currentInstance: Rust.Instance? {
        if let instance = rxModel.value.instance {
            return instance
        }
        return nil
    }

    /// 冲突日程
    var conflictModel: EventConflictModel? {
        rxConflictModel.value
    }
    
    func getDayInstance(with uniqueId: String) -> Rust.Instance? {
        conflictModel?.getDayInstance(with: uniqueId)
    }
    
}

extension EventDetailTableConflictViewModel {
    
    var defaultConflictModel: EventConflictModel {
        EventConflictModel(conflictType: .none, event: model.event)
    }
    
    /// 收敛 conflictModel 信号发送
    private func sendToConflictModel(_ model: EventConflictModel?) {
        guard var model = model else {
            self.rxConflictModel.accept(defaultConflictModel)
            return
        }
        filterThirdPartySyncInstance(&model)
        model.handleCurrentUniqueId()
        fixConflictInstance(&model)
        filterDayInstances(&model)
        suppleyLayoutInfo(&model)
        self.rxConflictModel.accept(model)
    }
    
    /// 去重三方日程
    private func filterThirdPartySyncInstance(_ model: inout EventConflictModel) {
        guard let calendarManager = self.calendarManager else { return }
        
        let currentUserId = self.userResolver.userID
        // 参考CalendarManager.conflictExchangeCalendarIDs，不对可见性进行判断
        let conflictExchangeCalendarIDs: [String] = {
            calendarManager.allCalendars
                .filter {
                    let isConflictType = $0.isExchangeCalendar() || $0.isGoogleCalendar()
                    // 共享来的三方日历（主日历和公共日历）上的日程不算冲突（此次新增，FG 内生效）
                    let isSharedThird = (!$0.isPrimary && currentUserId == $0.userId) && FG.syncDeduplicationOpen
                    return isConflictType && !isSharedThird
                }.map { $0.serverId }
        }()
        // 参考CalendarManager.primaryCalendarIDsAndUserIDsDic，去掉可见性的判断
        let idsDic: [String: String] = {
            calendarManager.allCalendars.filter { $0.getCalendarPB().type == .primary }
                .reduce(into: [String: String]()) { dic, calendar in
                    dic[calendar.serverId] = calendar.userId
                }
        }()
        
        var entitys = model.dayInstances
        
        if !conflictExchangeCalendarIDs.isEmpty {
            let primaryKeys: [String] = FG.syncDeduplicationOpen ? entitys.compactMap {
                if let userID = idsDic[$0.calendarID] {
                    return $0.keyWithTimeTuple + userID
                } else { return nil }
            } : []
            // 主日历同步到 exchange，若主日历可见，exchange 隐藏（视图上仅显示一个），若为当前展示的冲突日程也需要保留
            entitys = model.dayInstances.filter({
                let key = $0.keyWithTimeTuple + (calendarManager.calendar(with: $0.calendarID)?.userId ?? "")
                return !($0.isSyncFromLark || (conflictExchangeCalendarIDs.contains($0.calendarID) && primaryKeys.contains(key))
                )
            })
        }
        
        model.dayInstances = entitys
    }

    /// 冲突日程块的 selfAttendeeStatus 跟随详情页 instance 的状态，场景：rsvp 操作
    /// 当为普通日程、例外日程时，冲突日程块的 selfAttendeeStatus 可以信任详情页 instance 状态
    /// 当为重复性日程时，rsvp 所有场景，冲突日程块也可以信任详情页 instance，rsvp 此次/后续，会重新 fetchConflictData
    private func fixConflictInstance(_ model: inout EventConflictModel) {
        let instances = model.dayInstances.map { instance in
            var instance = instance
            if model.isConflictInstance(uniqueId: instance.quadrupleStr) {
                if !isJoined {
                    /// 未加入日程时，始终显示未恢复状态
                    instance.selfAttendeeStatus = .needsAction
                } else if let currentInstance = currentInstance {
                    instance.selfAttendeeStatus = currentInstance.selfAttendeeStatus
                }
                return instance
            }
            return instance
        }
        model.dayInstances = instances
    }
    
    /// 过滤空闲、拒绝的日程（当前日程除外），跟随日历设置
    private func filterDayInstances(_ model: inout EventConflictModel) {
        let shouldShowDeclinedEvent = SettingService.shared().getSetting().showRejectSchedule
        let instances = model.dayInstances.compactMap { instance in
            /// 冲突日程不做处理
            if model.isConflictInstance(uniqueId: instance.quadrupleStr) {
                return instance
            }
            if instance.isFree {
                /// 过滤空闲日程
                return nil
            }
            if !shouldShowDeclinedEvent && instance.selfAttendeeStatus == .decline {
                /// 过滤空闲日程
                return nil
            }
            return instance
        }
        model.dayInstances = instances
    }
    
    /// 补充 layout 信息
    func suppleyLayoutInfo(_ model: inout EventConflictModel) {
        /// 数据源
        let startDay = model.dayInstances.map(\.startDay).min()
        let endDay = model.dayInstances.map(\.endDay).max()
        let range = JulianDayUtil.makeJulianDayRange(min: startDay, max: endDay)
        let dayInstanceMap = Instance.groupedByDay(
            from: model.dayInstances.map { Instance.rust($0) },
            for: range,
            in: timezone
        ).mapValues({ instances in
            instances.sorted { ins1, ins2 in
                ins1.uniqueId < ins2.uniqueId
            }
        })

        guard let layoutRequest = api?.getInstancesLayoutRequest else {
            assertionFailure("no layout request api")
            return
        }

        /// 获取layout信息
        let dayInstanceLayoutedMap: [JulianDay: [DayNonAllDayLayoutedInstance]] = DayInstanceLayoutUtil.syncPrepareLayoutInstance(layoutRequest: layoutRequest, from: dayInstanceMap, isSingleDay: true, in: timezone)
        
        model.layoutedDayInstancesMap = dayInstanceLayoutedMap
    }
}
