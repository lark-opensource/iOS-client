//
//  EventDetailTableVideoLiveViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import Foundation
import LarkCombine
import RxSwift
import LarkContainer
import RustPB
import RxRelay

final class EventDetailTableVideoLiveViewModel: EventDetailComponentViewModel {

    typealias LiveStatus = RustPB.Videoconference_V1_AssociatedLiveStatus

    @ScopedInjectedLazy
    var calendarApi: CalendarRustAPI?

    @ScopedInjectedLazy
    var pushService: RustPushService?

    @ContextObject(\.rxModel) var rxModel

    var hasTracedShow = false
    let liveInfo = CurrentValueSubject<LiveStatus?, Never>(nil)
    let viewData = CurrentValueSubject<DetailVideoLiveHostCellContent?, Never>(nil)
    let rxToast = PublishRelay<ToastStatus>()
    let rxRoute = PublishRelay<Route>()

    private var event: EventDetail.Event {
        guard let event = context.rxModel.value.event else {
            EventDetail.logUnreachableLogic()
            return EventDetail.Event()
        }
        return event
    }

    private let rxBag = DisposeBag()
    private var bag: Set<AnyCancellable> = []

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindReactive()
    }
}

extension EventDetailTableVideoLiveViewModel {

    private func bindReactive() {

        rxModel.compactMap { $0.event }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                EventDetail.logInfo("videolive model changed")
                self.observeLivePush()
                self.loadLiveInfo()
            })
            .disposed(by: rxBag)

        liveInfo
            .compactMap { $0 }
            .sink { [weak self] liveInfo in
                guard let self = self else { return }
                let isLiving = liveInfo.liveStatus == .living
                let durationTime = liveInfo.durationTime
                EventDetail.logInfo("video live info changed: isLiving \(isLiving), durationTime: \(durationTime)")
                let viewData = DetailVideoLiveHostCellModel(isLiveInProgress: isLiving,
                                                            durationTime: durationTime,
                                                            url: self.event.videoMeeting.meetingURL)
                self.viewData.send(viewData)
            }.store(in: &bag)
    }

    private func observeLivePush() {
        let videoMeetingPush: Observable<()> = pushService?.rxVideoMeetingInfos
            .map { [weak self] infos -> VideoMeeting? in
                guard let self = self else { return nil }
                let event = self.event
                return infos
                    .last { $0.calendarID == event.calendarID
                            && $0.originalTime == event.originalTime
                            && $0.key == event.key
                    }
                    .map { VideoMeeting(pb: $0.videoMeeting) }
            }.map { _ in () } ?? .empty()
        let videoLiveHostPush: Observable<()> = pushService?.rxVideoLiveHostStatus.map { _ in () } ?? .empty()

        Observable.merge(videoMeetingPush, videoLiveHostPush)
            .bind { [weak self] _ in
                guard let self = self else { return }
                EventDetail.logInfo("reload live info")
                self.reloadLiveInfo()
            }.disposed(by: rxBag)
    }

    private func loadLiveInfo() {
        reloadLiveInfo()
    }

    private func reloadLiveInfo() {
        calendarApi?.getVideoLiveHostStatus(associatedId: associatedId)
            .subscribe {  [weak self] liveInfo in
                guard let self = self else { return }
                self.liveInfo.send(liveInfo)

                if liveInfo.liveStatus != .unknown {
                    self.traceVideoMeetingShowIfNeeded(with: liveInfo.liveStatus == .living)
                }
            } onError: { error in
                EventDetail.logError("reload live info error: \(error)")
            }.disposed(by: rxBag)
    }

    private var associatedId: String {
        return "\(event.key)_\(event.originalTime)"
    }
}

// MARK: - Route

extension EventDetailTableVideoLiveViewModel {
    enum Route {
        case url(url: URL)
    }
}

// MARK: - Action

extension EventDetailTableVideoLiveViewModel {

    enum Action {
        case tapVideo
    }

    func action(_ action: Action) {
        switch action {
        case .tapVideo: tapVideo()
        }
    }

    private func tapVideo() {

        EventDetail.logInfo("tap video action")
        rxToast.accept(.loading(info: I18n.Calendar_Common_LoadingCommon, disableUserInteraction: false))

        self.calendarApi?.getVideoChatByEvent(
            calendarID: event.calendarID,
            key: event.key,
            originalTime: Int(event.originalTime),
            forceRenew: false)
            .subscribe(onNext: { [weak self] videoMeeting in
                guard let self = self else { return }
                EventDetail.logInfo("jump to video: \(videoMeeting.url)")
                self.rxToast.accept(.remove)
                self.jumpVideo(videoMeeting)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                EventDetail.logError("jump to video error: \(error)")
                self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Common_FailedToLoad))
            }).disposed(by: rxBag)
    }

    private func jumpVideo(_ videoMeeting: VideoMeeting) {
        if videoMeeting.isExpired {
            EventDetail.logWarn("jump video failed. video expired")
            rxToast.accept(.tips(I18n.Calendar_Detail_VCExpired))
            return
        }
        guard let url = URL(string: videoMeeting.url) else {
            EventDetail.logError("jump to video live url error: \(videoMeeting.url)")
            return
        }
        rxRoute.accept(.url(url: url))
    }

}

// MARK: - Trace
extension EventDetailTableVideoLiveViewModel {

    func traceVideoMeetingShowIfNeeded(with isInMeeting: Bool) {
        guard hasTracedShow == false else { return }
        hasTracedShow = true
        CalendarTracerV2.EventDetailVideoMeeting.traceView {
            $0.is_in_meeting = isInMeeting.description
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.rxModel.value.instance, event: self.event))
        }
    }
}

struct DetailVideoLiveHostCellModel: DetailVideoLiveHostCellContent {
    var isLiveInProgress: Bool
    var durationTime: Int
    var url: String?
}
