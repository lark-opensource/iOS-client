//
//  EventDetailViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import RustPB
import UniverseDesignEmpty
import EENavigator

final class EventDetailViewModel: UserResolverWrapper {

    let userResolver: UserResolver
    let rxModel: BehaviorRelay<EventDetailModel>
    let state: EventDetailState
    let options: EventDetailOptions
    let scene: EventDetailScene
    let payload: EventDetailEntrancePayload
    let refreshHandle: EventDetailRefreshHandle

    // webinarInfo 只在从 server 获取的日程里面有效，所以这里单独缓存一下
    let rxWebinarInfo: BehaviorRelay<EventWebinarInfo?>

    let rxToast: PublishRelay<ToastStatus> = PublishRelay()

    let disposeBag = DisposeBag()
    private let monitor: EventDetailMonitor
    private let rxMetaDataStatus: BehaviorRelay<EventDetailViewStatus>
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    init(userResolver: UserResolver,
         rxModel: BehaviorRelay<EventDetailModel>,
         options: EventDetailOptions,
         scene: EventDetailScene,
         payload: EventDetailEntrancePayload,
         refreshHandle: EventDetailRefreshHandle,
         monitor: EventDetailMonitor,
         rxWebinarInfo: BehaviorRelay<EventWebinarInfo?>,
         rxMetaDataStatus: BehaviorRelay<EventDetailViewStatus>) {
        self.userResolver = userResolver
        self.rxModel = rxModel
        self.state = EventDetailState()
        self.options = options
        self.scene = scene
        self.payload = payload
        self.refreshHandle = refreshHandle
        self.monitor = monitor
        self.rxWebinarInfo = rxWebinarInfo
        self.rxMetaDataStatus = rxMetaDataStatus

        self.rxWebinarInfo.subscribe {[weak self] webinarInfo in
            guard let self = self, let webinarInfo = webinarInfo else { return }
            EventDetail.logInfo("update webinarinfo from server")
            self.state.webinarContext = EventDetailWebinarContext(webinarInfo: webinarInfo)
        }.disposed(by: disposeBag)

        observeEventChangePush()
        observeEventMeetingChangePush()
    }

    var isForReview: Bool {
        switch model {
        case .local: return false
        case let .pb(event, _):
            let eventForReview = !(event.calendarID == calendarManager?.primaryCalendarID)
            return options.contains(.needCalculateIsForReview) && eventForReview
        case .meetingRoomLimit: return false
        }
    }

    var model: EventDetailModel {
        rxModel.value
    }

    var context: EventDetailContext {
        EventDetailContext(rxModel: rxModel,
                           state: state,
                           options: options,
                           payload: payload,
                           refreshHandle: refreshHandle,
                           monitor: monitor,
                           scene: scene)
    }

    var webinarContext: EventDetailWebinarContext? {
        state.webinarContext
    }

    // 日程push刷新
    private func observeEventChangePush() {
        let getEventPB: (() -> Observable<CalendarEvent>) = { [weak self] in
            guard let self = self, let api = self.calendarApi else { return .empty() }
            return api.getEventPB(
                calendarId: self.model.calendarId,
                key: self.model.key,
                originalTime: self.model.originalTime
            ).collectSlaInfo(.EventDetail,
                             action: "load_updated_event",
                             source: "event",
                             additionalParam: ["entity_id": self.model.key])
        }

        // 这个 push 只能拉本地日程，不能拉 serverEvent，不然会造成死循环。因为 sdk 会在 getServerEvent 里面推送这个 push
        pushService?.rxActiveEventChanged.filter { [weak self] events -> Bool in
            guard let self = self else { return false }
            var event = Rust.ChangedActiveEvent()
            event.calendarID = self.model.calendarId
            event.key = self.model.key
            return events.contains(event)
        }.map { _ in () }
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                EventDetail.logInfo("receive active event changed from push")
                getEventPB().subscribe(onNext: { [weak self] event in
                    guard let self = self else { return }
                    guard event.key == self.model.key,
                          event.calendarID == self.model.calendarId,
                          event.originalTime == self.model.originalTime else {
                        // 二次确认，有可能和其他refresh有冲突，防止bad case
                        return
                    }

                    EventDetail.logInfo("refresh event from push")
                    self.refreshHandle.refresh(newEvent: event)
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    if error.errorType() == .offline { return }
                    self.rxMetaDataStatus.accept(.error(error.asDetailError.toViewStatusErrorOrDefault()))
                    self.monitor.track(.failure(.load, nil, error, [:]))
                }).disposed(by: self.disposeBag)

            }).disposed(by: disposeBag)
    }

    lazy var conflictViewComponent: EventDetailTableConflictViewComponent = {
        let viewModel = EventDetailTableConflictViewModel(context: context, userResolver: userResolver)
        return EventDetailTableConflictViewComponent(viewModel: viewModel, userResolver: userResolver)
    }()
}

extension EventDetailViewModel {

    private func observeEventMeetingChangePush() {
        guard let event = model.event,
              let instance = model.instance else { return }
        // 先拉一下会议状态
        updateVideoMeetingStatus()
        pushService?.rxVideoStatus
            .filter { $0.uniqueId == event.videoMeeting.uniqueID || event.videoMeeting.uniqueID.isEmpty }
            .map { $0.status }
            .bind { [weak self] _ in
                EventDetail.logInfo("onpush video status changed")
                self?.updateVideoMeetingStatus()
            }.disposed(by: disposeBag)
    }

    // 刷新视频会议状态
    private func updateVideoMeetingStatus() {
        guard let event = model.event,
              let instance = model.instance else { return }
        let videoMeeting = VideoMeeting(pb: event.videoMeeting)
        guard videoMeeting.type == .vchat else {
            return
        }
        let uniqueId = videoMeeting.uniqueId
        var source: VideoMeetingEventType = .normal
        if event.source == .people {
            source = .interview
        }
        let instanceDetails = CalendarInstanceDetails(uniqueID: uniqueId, key: event.key, originalTime: event.originalTime, instanceStartTime: model.startTime, instanceEndTime: model.endTime)
        calendarApi?.getVideoMeetingStatusRequest(instanceDetails: instanceDetails, source: source)
            .subscribe(onNext: { [weak self] vcStatus in
                guard let self = self else { return }
                self.context.state.isVideoMeetingLiving = vcStatus.status == .live
                EventDetail.logInfo("refresh meeting status, is meeting living: \(vcStatus.status == .live)")
            })
            .disposed(by: disposeBag)
    }
}

extension EventDetailViewModel {
    func registerActiveEvent() {
        calendarApi?.registerActiveEvent(calendarID: model.calendarId, key: model.key).subscribe().disposed(by: disposeBag)
    }

    func unRisterActiveEvent() {
        calendarApi?.unRegisterActiveEvent(calendarID: model.calendarId, key: model.key).subscribe().disposed(by: disposeBag)
    }

}

extension EventDetailViewModel {

    var calendar: EventDetail.Calendar? {
        return model.getCalendar(calendarManager: self.calendarManager)
    }

    func endLoadUITrack() {
        monitor.track(.success(.loadUI, model, [:]))
    }
}

extension EventDetailViewModel {
    func traceShow() {
        traceEventDetailShow()
        if !model.eventDescription.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.traceEventDetailDocShow()
            }
        }
    }

    private func traceEventDetailShow() {
        CalendarTracerV2.EventDetail.traceView {
            $0.event_type = self.model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
    }

    private func traceEventDetailDocShow() {
        CalendarTracerV2.EventDetailDoc.traceView {
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
            let linkTypeExist = DocUtils.docUrlDetector(self.rxModel.value.eventDescription, userNavigator: self.userResolver.navigator)
            let titleTypeExist = DocUtils.docUrlDetector(self.rxModel.value.docsDescription, userNavigator: self.userResolver.navigator)
            $0.has_doc = (linkTypeExist || titleTypeExist) ? "true" : "false"
        }
    }
}

#if !LARK_NO_DEBUG
// MARK: 日程详情页便捷调试数据
extension EventDetailViewModel: ConvenientDebugInfo {
    var eventDebugInfo: Rust.Event? {
        if case let .pb(event, _) = model {
            return event
        }
        return nil
    }
    var calendarDebugInfo: Rust.Calendar? {
        if case let .pb(event, _) = model {
            return calendarManager?.allCalendars.first(where: { $0.serverId == event.calendarID })?.getCalendarPB()
        }
        return nil
    }
    var meetingRoomInstanceDebugInfo: RoomViewInstance? {
        if case let .meetingRoomLimit(meetingRoom) = model {
            return meetingRoom
        }
        return nil
    }

    var meetingRoomDebugInfo: Rust.MeetingRoom? { nil }

    var otherDebugInfo: [String: String]? { nil }
}
#endif


extension EventDetailViewModel {
    var auroraColor: AuroraEventDetailColor {
        model.auroraColor
    }
}
