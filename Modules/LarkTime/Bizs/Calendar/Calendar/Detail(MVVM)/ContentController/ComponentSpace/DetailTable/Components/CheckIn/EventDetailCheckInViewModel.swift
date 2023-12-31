//
//  EventDetailCheckInViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/20.
//

import Foundation
import RxSwift
import OpenCombine
import LarkContainer
import CalendarFoundation
import LarkTimeFormatUtils
import LarkRustClient
import ServerPB

struct EventDetailCheckInViewContent: EventDetailCheckInViewDateType {
    var titleHidden: Bool = true

    var subTitleHidden: Bool = true

    var arrowHidden: Bool = true

    var titleActive: Bool = true

    var subTitleActive: Bool = true

    var arrowActive: Bool = true

    var title: String?

    var subTitle: String = ""

    var disableReason: String = ""

    static var initialValue: Self {
        return EventDetailCheckInViewContent(titleHidden: false, titleActive: false, title: I18n.Calendar_Event_CheckInGenerating)
    }
}

class EventDetailCheckInViewModel: EventDetailComponentViewModel {

    @ContextObject(\.rxModel) var rxModel

    var model: EventDetailModel { rxModel.value }
    let viewData = CurrentValueSubject<EventDetailCheckInViewDateType?, Never>(EventDetailCheckInViewContent.initialValue)

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private let disposeBag = DisposeBag()
    private var loadViewDataDisposable: Disposable?

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.buildViewData()
            })
            .disposed(by: disposeBag)
    }

    private func buildViewData() {
        guard let instance = model.instance,
              let event = model.event else { return }

        EventDetail.logInfo("is12HourStyle: \(String(describing: self.calendarDependency?.is12HourStyle.value))")
        let options = Options(timeZone: .current,
                              is12HourStyle: self.calendarDependency?.is12HourStyle.value ?? true,
                              shouldShowGMT: true,
                              timeFormatType: .long,
                              timePrecisionType: .minute,
                              datePrecisionType: .day,
                              dateStatusType: .absolute,
                              shouldRemoveTrailingZeros: false)
        let startDate = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(instance.endTime))
        let checkInDate = event.checkInConfig.getCheckInDate(startDate: startDate, endDate: endDate)
        let subTitle = CalendarTimeFormatter.formatFullDateTimeRange(
            startFrom: checkInDate.startDate,
            endAt: checkInDate.endDate,
            isAllDayEvent: event.isAllDay,
            with: options)
        loadViewDataDisposable?.dispose()
        loadViewDataDisposable = loadViewData()
            .subscribe(onNext: { [weak self] info in
                var viewContent = EventDetailCheckInViewContent()
                viewContent.disableReason = info.disableReason
                viewContent.titleHidden = false
                viewContent.subTitleHidden = !info.checkInVisible
                viewContent.arrowHidden = !info.checkInVisible
                viewContent.titleActive = !(info.checkInVisible && info.checkInDisable)
                viewContent.arrowActive = info.checkInVisible && !info.checkInDisable
                viewContent.subTitleActive = false

                if !info.checkInVisible {
                    // 参与者视角
                    viewContent.title = I18n.Calendar_Event_DateTimeCanCheckIn(time: subTitle)
                } else {
                    // 组织者视角
                    viewContent.title = I18n.Calendar_Event_CheckInfoTitle
                    viewContent.subTitle = I18n.Calendar_Event_DateTimeCanCheckIn(time: subTitle)
                }

                self?.viewData.send(viewContent)
            }, onError: { [weak self] error in
                if error.errorType() == .calendarEventCheckInApplinkNoPermission {
                    var viewContent = EventDetailCheckInViewContent()
                    viewContent.titleHidden = false
                    viewContent.title = I18n.Calendar_Event_DateTimeCanCheckIn(time: subTitle)
                    self?.viewData.send(viewContent)
                }
            })
        loadViewDataDisposable?.disposed(by: disposeBag)
    }

    private func loadViewData() -> Observable<ServerPB_Calendarevents_GetEventCheckInInfoResponse> {
        var retryCount = 0 // 重试30次
        guard let rustApi = calendarApi else { return .empty() }
        return rustApi.getEventCheckInInfo(calendarID: Int64(model.calendarId) ?? 0,
                                           key: model.key,
                                           originalTime: model.originalTime,
                                           startTime: model.startTime,
                                           condition: [.visibility])
            .map({ info in
                guard !info.isGenerating else {
                    throw RCError.businessFailure(errorInfo: BusinessErrorInfo(code: ErrorType.calendarEventCheckInNotEnabled.rawValue,
                                                                               errorStatus: 0,
                                                                               errorCode: ErrorType.calendarEventCheckInNotEnabled.rawValue,
                                                                               debugMessage: "",
                                                                               displayMessage: "",
                                                                               serverMessage: "",
                                                                               userErrTitle: "",
                                                                               requestID: ""))
                }
                return info
            })
            .retryWhen({ error -> Observable<Int> in
                return error.flatMap { (er) -> Observable<Int> in
                    retryCount += 1
                    guard er.errorType() == .calendarEventCheckInNotEnabled, retryCount < 30 else {
                        return .error(er)
                    }
                    return Observable.interval(.milliseconds(2000), scheduler: MainScheduler.asyncInstance)
                }
            })
    }
}
