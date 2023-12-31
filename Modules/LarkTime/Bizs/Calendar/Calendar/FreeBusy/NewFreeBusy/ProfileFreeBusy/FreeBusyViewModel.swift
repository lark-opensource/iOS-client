//
//  FreeBusyViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import LarkContainer

protocol FreeBusyViewModelDelegate: AnyObject {
    func showLoading()
    func hideLoading()
    func reloadViewWithInstanceData()
    func getBoundsWidth() -> CGFloat
    func updateHeaderFooterInfo(freeBusyModel: FreeBusyControllerModel)
    func showFailedWithRetry()
}

class FreeBusyViewModel: FreeBusyDetailViewModel {
    let logger = Logger.log(FreeBusyViewModel.self, category: "Calendar.FreeBusyViewModel")
    
    lazy var freeBusyModel = FreeBusyControllerModel(sunStateService: SunStateService(userResolver: self.userResolver),
                                                     currentUserCalendarId: currentUserCalendarId,
                                                     is12HourStyle: rxIs12HourStyle.value)
    weak var delegate: FreeBusyViewModelDelegate?
    
    let userIds: [String]
    let isFromProfile: Bool
    let createEventSucceedHandler: CreateEventSucceedHandler
    
    init(userResolver: UserResolver,
         userIds: [String],
         isFromProfile: Bool,
         createEventSucceedHandler: @escaping CreateEventSucceedHandler) {
        self.userIds = userIds
        self.isFromProfile = isFromProfile
        self.createEventSucceedHandler = createEventSucceedHandler
        super.init(userResolver: userResolver)
        checkCollaborationPermissionIgnoreIDs(userIds: userIds)
        loadAttendees()
    }

    func loadAttendees() {
        guard let calendarApi = calendarApi else {
            logger.error("[FreeBusyViewModel] failed get calendarApi")
            return
        }
        DispatchQueue.main.async {
            self.delegate?.showLoading()
        }
        CalendarMonitorUtil.startTrackFreebusyViewAttendeeTime()

        calendarApi.getAttendees(uids: userIds)
            .subscribe(onNext: { [weak self] (attendees) in
                guard let `self` = self else { return }
                self.logger.info("getAttendees success with: \(attendees)")
                self.freeBusyModel.changeAttendees(attendees: attendees)
                CalendarMonitorUtil.endTrackFreebusyViewAttendeeTime(calNum: attendees.count)
                DispatchQueue.main.async {
                    self.delegate?.hideLoading()
                    self.delegate?.reloadViewWithInstanceData()
                    self.delegate?.updateHeaderFooterInfo(freeBusyModel: self.freeBusyModel)
                }
                
                self.trackProfileIfNeeded(attendees: attendees)
                SlaMonitor.traceSuccess(.FreeBusyInstance, action: "load_attendee", source: "profile")
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.logger.info("getAttendees error with: \(error)")
                DispatchQueue.main.async {
                    self.delegate?.showFailedWithRetry()
                }
                SlaMonitor.traceFailure(.FreeBusyInstance, error: error, action: "load_attendee", source: "profile")
            }).disposed(by: disposeBag)
    }
    
    func loadInstanceData(date: Date) throws -> (InstanceMap, [String: [WorkingHoursTimeRange]], [String: Bool]) {
        CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()

        let date = freeBusyModel.calibrationDate(date: date)
        let calendarIds = freeBusyModel.calendarIds
        let cellWidth = self.cellWidth(with: TimeIndicator.indicatorWidth(is12HourStyle: freeBusyModel.is12HourStyle))
        let serverInstanceData = try syncLoadInstanceDate(calendarIds: calendarIds,
                                                          date: date,
                                                          panelSize: CGSize(width: cellWidth, height: 1200),
                                                          timeZoneId: freeBusyModel.getTimeZone().identifier,
                                                          disposeBag: disposeBag)
        
        CalendarMonitorUtil.endTrackFreebusyViewInProfileTime()
        freeBusyModel.changetimezoneMap(serverInstanceData.timezoneMap)
        freeBusyModel.changeWorkHourSettingMap(serverInstanceData.workHourMap)
        freeBusyModel.privateCalMap = serverInstanceData.privateCalMap
        loadSunState()

        DispatchQueue.main.async {
            self.delegate?.updateHeaderFooterInfo(freeBusyModel: self.freeBusyModel)
        }
        return (serverInstanceData.instanceMap,
                freeBusyModel.workingHoursTimeRangeMap(date: date),
                freeBusyModel.privateCalMap)
    }
    
    
    private func checkCollaborationPermissionIgnoreIDs(userIds: [String]) {
        calendarApi?.checkCollaborationPermissionIgnoreError(uids: userIds)
            .subscribe ( onNext: { [weak self] forbiddenIDs in
                guard let self = self else { return }
                self.logger.info("[FreeBusyViewModel] checkCollaborationPermissionIgnoreError with: \(forbiddenIDs)")
                self.freeBusyModel.usersRestrictedForNewEvent = forbiddenIDs
            }, onError: { [weak self] (error) in
                self?.logger.error("[FreeBusyViewModel] checkCollaborationPermissionIgnoreError failed with: \(error)")
            }).disposed(by: disposeBag)
    }
    
    func loadSunState() {
        freeBusyModel.sunStateService.loadData(citys: Array(freeBusyModel.timezoneMap.values), date: Int64(freeBusyModel.startTime.timeIntervalSince1970))
    }
    
    func trackProfileIfNeeded(attendees: [CalendarEventAttendeeEntity]) {
        guard let calendarId = attendees.first?.attendeeCalendarId,
              let otherUserId = userIds.first
        else { return }
        CalendarTracer.shared.calProfileTapped(userId: otherUserId, calendarId: calendarId)
    }
    
    func trackCalendarProfile() {
        CalendarTracerV2.CalendarProfile.traceView()
    }
    
    func trackCalFullEditEvent() {
        var timeConflict: CalendarTracer.CalFullEditEventParam.TimeConfilct = .noConflict
        if !self.freeBusyModel.workHourConflictCalendarIds.isEmpty {
            timeConflict = .workTime
        } else if !self.freeBusyModel.getFreeBusyConflictcalendarIds().isEmpty {
            timeConflict = .eventConflict
        }

        CalendarTracer.shareInstance.calFullEditEvent(actionSource: .calProfile,
                                                      editType: .new,
                                                      mtgroomCount: 0,
                                                      thirdPartyAttendeeCount: 0,
                                                      groupCount: 0,
                                                      userCount: 0,
                                                      timeConfilct: timeConflict)
    }
    
    private func cellWidth(with rullerWidth: CGFloat) -> CGFloat {
        let viewBoundsWidth: CGFloat = self.delegate?.getBoundsWidth() ?? 0
        self.logger.info("[FreeBusyViewModel] viewBoundsWidth :\(viewBoundsWidth)")
        return (viewBoundsWidth - rullerWidth) / CGFloat(2)
    }
    
}
