//
//  EventDetailMetaViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import RxRelay
import RxSwift
import LarkContainer
import EventKit
import CalendarFoundation

final class EventDetailMetaViewModel: UserResolverWrapper {

    let userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy
    var calendarApi: CalendarRustAPI?

    @ScopedInjectedLazy
    var localRefresh: LocalRefreshService?

    @ScopedInjectedLazy
    var calendarManager: CalendarManager?

    let rxReplayMetaDataStatus: Observable<EventDetailViewStatus>
    let rxToastStatus = PublishRelay<ToastStatus>()

    private let bag = DisposeBag()
    private let reformer: EventDetailViewModelDataReformer
    private var refreshReformer: EventDetailViewModelDataReformer?
    private let rxMetaData = BehaviorRelay<EventDetailMetaData?>(value: nil)
    private let options: EventDetailOptions
    private let refreshSubject = PublishSubject<EventDetailRefreshReason>()
    private let refreshHandle: EventDetailRefreshHandle
    private let monitor: EventDetailMonitor
    private let rxMetaDataStatus = BehaviorRelay<EventDetailViewStatus>(value: .initial)

    // webinarInfo 只在从 server 获取的日程里面有效，所以这里单独缓存一下
    private let rxWebinar = BehaviorRelay<EventWebinarInfo?>(value: nil)

    var debugCount = 0

    init(reformer: EventDetailViewModelDataReformer,
         options: EventDetailOptions,
         userResolver: UserResolver) {
        self.reformer = reformer
        self.options = options
        self.userResolver = userResolver
        self.refreshHandle = EventDetailRefreshHandle(refreshSubject: refreshSubject)
        let replayAll = rxMetaDataStatus.replayAll()
        self.rxReplayMetaDataStatus = replayAll.asObservable()
        self.monitor = EventDetailMonitor.makeMonitor(userResolver: userResolver)
        self.monitor.reformer = self.reformer.monitorDescription

        bindRx()

        // 这个要放在bindRx之后，否则有时序问题
        replayAll.connect().disposed(by: bag)

        loadMetaData()
    }

    /// 详情页可感知耗时
    func trackEventDetailLoadTime() {
        CalendarMonitorUtil.startTrackEventDetailView(actionSource: reformer.getTupleDataForTracker().actionSource,
                                                      calEventId: reformer.getTupleDataForTracker().calEventID ?? "",
                                                      originalTime: reformer.getTupleDataForTracker().originalTime ?? 0,
                                                      uid: reformer.getTupleDataForTracker().key ?? "")
    }

}

extension EventDetailMetaViewModel {

    func action(_ action: EventDetailMetaAction) {
        switch action {
        case .retryLoadEvent: retryLoadMetaData()
        }
    }

    private func retryLoadMetaData() {
        EventDetail.logInfo("retry load meta Data")
        self.rxMetaDataStatus.accept(.initial)
        loadMetaData()
    }
}

extension EventDetailMetaViewModel {

    private func bindRx() {
        rxMetaDataStatus.map { status -> EventDetailMetaData? in
            if case let .refresh(metaData) = status {
                return metaData
            }
            if case let .metaDataLoaded(metaData) = status {
                return metaData
            }
            return nil
        }.compactMap { $0 }
        .bind(to: rxMetaData)
        .disposed(by: bag)

        rxMetaData
            .compactMap { $0?.model.event }
            .compactMap { event -> Bool? in
                if let level = f_schemaCompatibleLevel(event.dt.schemaCollection),
                   level == .showHint {
                    return true
                }
                return nil
            }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.rxToastStatus.accept(.failure(I18n.Calendar_Common_AppOutOfDateToast()))
            }).disposed(by: bag)

        refreshSubject.subscribe { [weak self] reason in
            guard let self = self else { return }
            EventDetail.logInfo("refresh subject, reason: \(reason.description)")
            switch reason {
            case let .local(ekEvent): self.updateWithLocalEvent(newEvent: ekEvent)
            case let .edit(newEvent, span):
                if case .webinar = newEvent.category {
                    self.rxWebinar.accept(newEvent.webinarInfo)
                }
                self.updateWithEditEvent(newEvent: newEvent, span: span)
            case let .newEvent(newEvent): self.updateWithNewEvent(newEvent: newEvent)
            case let .newReformer(newReformer): self.updateWith(newReformer: newReformer)
            case .sameReformer: self.updateWith(newReformer: self.reformer)
            }
        } onError: { error in
            EventDetail.logError("refresh subject error: \(error)")
        }.disposed(by: bag)

    }

    private func loadMetaData() {
        self.rxMetaDataStatus.accept(.reforming)
        monitor.track(.start(.load))
        Single.zip(
            prepareDetailService(),
            self.reformer.reformToViewModelData()
        ).do(afterSuccess: { [weak self] ( _, formedInfo) in
            // 二次取服务端数据刷新
            guard let self = self else { return }
            self.loadServerEvent(with: formedInfo)
        }).subscribe { [weak self] (_, formedInfo) in
            guard let self = self else { return }
            EventDetail.logInfo("meta data load first event")
            self.rxMetaDataStatus.accept(.metaDataLoaded(formedInfo.metaData))
            self.monitor.track(.success(.load, formedInfo.metaData.model, [:]))
        } onError: { [weak self] (error) in
            guard let self = self else { return }
            EventDetail.logError("meta data loda first error: \(error)")
            if error.errorType() == .offline { return }
            self.rxMetaDataStatus.accept(.error(error.asDetailError.toViewStatusErrorOrDefault()))
            self.monitor.track(.failure(.load, nil, error, [:]))
        }.disposed(by: bag)
    }

    /// 前置加载Service服务
    private func prepareDetailService() -> Single<()> {
        SettingService.rxShared().asSingle()
        .map { _ in return () }
    }

    private func loadServerEvent(with formedInfo: EventDetailReformedInfo) {
        guard formedInfo.needRefreshFromServer,
              let event = formedInfo.metaData.model.event,
              !event.serverID.isEmpty else {
            EventDetail.logInfo("can not load server event")
            return
        }

        self.calendarApi?.getServerPBEvent(serverId: event.serverID)
            .collectSlaInfo(.EventDetail, action: "load_server_event", source: "server", additionalParam: ["entity_id": event.serverID])
            .subscribe { [weak self] updatedEvent in
                guard let self = self,
                      let updatedEvent = updatedEvent,
                      let calendar = self.calendarManager?.calendar(with: updatedEvent.calendarID),
                      let updatedMetaData = formedInfo.metaData.updatedEvent(with: updatedEvent, calendar: calendar) else {
                    EventDetail.logInfo("getServerPBEvent success but can not update event. is updatedEvent nil: \(updatedEvent == nil)")
                    return
                }
                EventDetail.logInfo("meta data load second server event")
                if updatedEvent.category == .webinar {
                    self.rxWebinar.accept(updatedEvent.webinarInfo)
                }
                self.rxMetaDataStatus.accept(.refresh(updatedMetaData))
            } onError: { [weak self] error in
                EventDetail.logError("load server event failed, error: \(error)")
                if error.errorType() == .offline {
                    self?.rxToastStatus.accept(.tips(I18n.Calendar_Toast_Disconnected))
                }
                if let statusError = error.asDetailError.toViewStatusError() {
                    self?.rxMetaDataStatus.accept(.error(statusError))
                }
            }.disposed(by: bag)

    }

    func buildContentViewModel() -> EventDetailViewModel? {
        guard let metaData = metaData else {
            return nil
        }

        // 首次构建Model，之后数据更新自动同步到下层VM
        let rxModel = BehaviorRelay(value: metaData.model)

        rxMetaData
            .compactMap { $0 }
            .map { $0.model }
            .do(onNext: { model in
                EventDetail.logInfo("rxModel receive value: \(model)")
            })
            .bind(to: rxModel)
            .disposed(by: bag)

        let rxWebinarInfo = BehaviorRelay<EventWebinarInfo?>(value: rxWebinar.value)
        rxWebinar.bind(to: rxWebinarInfo).disposed(by: bag)

        return EventDetailViewModel(userResolver: self.userResolver,
                                    rxModel: rxModel,
                                    options: options,
                                    scene: reformer.scene,
                                    payload: metaData.payload,
                                    refreshHandle: refreshHandle,
                                    monitor: monitor,
                                    rxWebinarInfo: rxWebinarInfo,
                                    rxMetaDataStatus: rxMetaDataStatus)
    }

    private var metaData: EventDetailMetaData? {
        return rxMetaData.value
    }

}

extension EventDetailMetaViewModel {
    func startTrackLoadUI() {
        monitor.track(.start(.loadUI))
    }
}

extension EventDetailMetaViewModel {

    private func updateWithLocalEvent(newEvent: EKEvent) {
        guard let metaData = metaData else {
            EventDetail.logError("update rust event, but cannot get metaData")
            return
        }

        rxMetaData.accept(.init(model: .local(newEvent), payload: metaData.payload))
    }

    private func updateWithNewEvent(newEvent: EventDetail.Event) {
        guard let metaData = metaData else {
            EventDetail.logError("update rust event, but cannot get metaData")
            return
        }

        guard let event = metaData.model.event else {
            EventDetail.logError("update rust event, but cannot get origianl event or instance")
            return
        }

        guard let calendar = calendarManager?.calendar(with: newEvent.calendarID) else {
            EventDetail.logError("update rust event, but cannot get event calendar")
            return
        }

        guard let newModel = metaData.updatedEvent(with: newEvent, calendar: calendar) else {
            EventDetail.logError("update new rust event failed")
            return
        }

        rxMetaData.accept(metaData.updatedModel(with: newModel.model))
    }

    private func updateWithEditEvent(newEvent: EventDetail.Event, span: EventDetail.Event.Span) {

        guard let metaData = metaData else {
            EventDetail.logError("update rust event, but cannot get metaData")
            return
        }

        guard let event = metaData.model.event,
              let instance = metaData.model.instance else {
            EventDetail.logError("update rust event, but cannot get origianl event or instance")
            return
        }

        guard var calendar = calendarManager?.calendar(with: event.calendarID) else {
            EventDetail.logError("update rust event, but cannot get calendar")
            return
        }

        if calendar.serverId != newEvent.calendarID {
            guard let newCalendar = calendarManager?.calendar(with: newEvent.calendarID) else {
                EventDetail.logError("update rust event and change calendar, but cannot get the new calendar")
                return
            }
            calendar = newCalendar
        }

        var instanceStartTime = newEvent.startTime
        var instanceEndTime = newEvent.endTime
        if span == .allEvents {
            // 在保存全部时，editedEvent的startTime/endTime，是重复性日程第一天instance的startTime/endTime，而不是当前编辑天的
            let diff = newEvent.startTime - event.startTime
            instanceStartTime = instance.startTime + diff
            instanceEndTime = instance.endTime + diff
        }

        let newInstance = newEvent.dt.makeInstance(with: calendar,
                                                   startTime: instanceStartTime,
                                                   endTime: instanceEndTime)

        let newModel = EventDetailModel.pb(newEvent, newInstance)
        rxMetaData.accept(metaData.updatedModel(with: newModel))

        localRefresh?.rxEventNeedRefresh.onNext(())
        localRefresh?.rxCalendarDetailDismiss.onNext(())
    }

    private func updateWith(newReformer: EventDetailViewModelDataReformer) {

        // 持有 防止reformer为nil
        refreshReformer = newReformer

        newReformer.reformToViewModelData()
            .do(afterSuccess: { [weak self] formedInfo in
                // 二次取服务端数据刷新
                guard let self = self else { return }
                self.loadServerEvent(with: formedInfo)
            })
            .subscribe { [weak self] formedInfo in
                guard let self = self else { return }
                EventDetail.logInfo("new reformer meta data refresh")
                self.rxMetaDataStatus.accept(.refresh(formedInfo.metaData))
                EventDetail.logInfo("meta data refresh")
            } onError: { [weak self] (error) in
                EventDetail.logError("new reformer meta data refresh error: \(error)")
                if error.errorType() == .offline { return }
                self?.rxMetaDataStatus.accept(.error(error.asDetailError.toViewStatusErrorOrDefault()))
            }.disposed(by: bag)
    }
}
