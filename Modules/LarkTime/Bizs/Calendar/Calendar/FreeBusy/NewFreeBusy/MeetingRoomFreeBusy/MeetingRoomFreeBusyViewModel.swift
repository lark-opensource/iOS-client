//
//  MeetingRoomFreeBusyViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/8/31.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import CalendarFoundation
import LarkContainer

protocol MeetingRoomFreeBusyViewModelDelegate: AnyObject {
    func showLoading()
    func hideLoading()
    func reloadViewWithInstanceData()
    func getBoundsWidth() -> CGFloat
    func updateHeaderFooterInfo(freeBusyModel: FreeBusyControllerModel)
}

class MeetingRoomFreeBusyViewModel: FreeBusyDetailViewModel {
    let logger = Logger.log(MeetingRoomFreeBusyViewModel.self, category: "Calendar.MeetingRoomFreeBusyViewModel")
        
    var freeBusyModel: FreeBusyControllerModel
    weak var delegate: MeetingRoomFreeBusyViewModelDelegate?
    
    let userIds: [String]
    let createEventBody: CalendarCreateEventBody?
    let createEventSucceedHandler: CreateEventSucceedHandler
    let startDate: Date
    
    var rxOverUsageLimit: BehaviorRelay<Bool> = .init(value: false)

    var meetingRoomInfoTransform = CGAffineTransform.identity
    
    init(userResolver: UserResolver,
         userIds: [String],
         meetingRoom: Rust.MeetingRoom,
         createEventBody: CalendarCreateEventBody? = nil,
         createEventSucceedHandler: @escaping CreateEventSucceedHandler) {
        self.userIds = userIds
        self.createEventBody = createEventBody
        self.createEventSucceedHandler = createEventSucceedHandler
        self.startDate = createEventBody?.startDate ?? Date()
        freeBusyModel = FreeBusyControllerModel(sunStateService: SunStateService(userResolver: userResolver),
                                                currentUserCalendarId: "",
                                                is12HourStyle: true)
        super.init(userResolver: userResolver)
        self.meetingRoom = meetingRoom

        initialModel()
        observeInstanceChanged(meetingRoom: meetingRoom)
        loadAttendee()
    }
    
    private func initialModel() {
        freeBusyModel = FreeBusyControllerModel(sunStateService: SunStateService(userResolver: self.userResolver),
                                                currentUserCalendarId: currentUserCalendarId,
                                                is12HourStyle: rxIs12HourStyle.value)
    }
    
    private func specialAttendeesGetter() -> Observable<[PBAttendee]> {
        .just([CalendarMeetingRoom.toAttendeeEntity(fromResource: meetingRoom ?? Rust.MeetingRoom.init() , buildingName: "", tenantId: meetingRoom?.tenantID ?? "")])
    }
    
    func loadAttendee() {
        DispatchQueue.main.async {
            self.delegate?.showLoading()
        }
        specialAttendeesGetter()
            .subscribe(onNext: { [weak self] (attendees) in
                guard let `self` = self else { return }
                self.logger.info("[MeetingRoomFreeBusyViewModel] specialAttendeesGetter with: \(attendees)")
                self.freeBusyModel.changeAttendees(attendees: attendees)
                
                DispatchQueue.main.async {
                    self.delegate?.hideLoading()
                    self.delegate?.reloadViewWithInstanceData()
                    self.delegate?.updateHeaderFooterInfo(freeBusyModel: self.freeBusyModel)
                }
            }).disposed(by: disposeBag)
    }
    
    func loadInstanceData(date: Date) throws -> (InstanceMap, [String: [WorkingHoursTimeRange]], [String: Bool]) {
        CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()

        let date = freeBusyModel.calibrationDate(date: date)
        let calendarIds = freeBusyModel.calendarIds
        let cellWidth = self.cellWidth(with: TimeIndicator.indicatorWidth(is12HourStyle: freeBusyModel.is12HourStyle))
        self.logger.info("")
        let serverInstanceData = try syncLoadInstanceDate(calendarIds: calendarIds,
                                                          date: date,
                                                          panelSize: CGSize(width: cellWidth, height: 1200),
                                                          timeZoneId: freeBusyModel.getTimeZone().identifier,
                                                          disposeBag: disposeBag)
        // 会议室预定次数限制
        if meetingRoom != nil && SettingService.shared().tenantSetting?.resourceSubscribeCondition.limitPerDay != 0 {
            self.pullResourceConsumedUsage(startDate: date.dayStart())
        }
        freeBusyModel.changetimezoneMap(serverInstanceData.timezoneMap)
        freeBusyModel.changeWorkHourSettingMap(serverInstanceData.workHourMap)
        freeBusyModel.privateCalMap = serverInstanceData.privateCalMap
        DispatchQueue.main.async {
            self.delegate?.updateHeaderFooterInfo(freeBusyModel: self.freeBusyModel)
        }
        return (serverInstanceData.instanceMap,
                freeBusyModel.workingHoursTimeRangeMap(date: date),
                freeBusyModel.privateCalMap)
    }
    
    func pullResourceConsumedUsage(startDate: Date) {
        calendarApi?.getResourceSubscribeUsage(
            startTime: startDate,
            endTime: startDate.dayEnd(),
            rrule: "",
            key: "",
            originalTime: 0
        ).catchError { _ in return .empty() }
            .bind(to: self.rxOverUsageLimit)
            .disposed(by: disposeBag)
    }
    
    private func cellWidth(with rullerWidth: CGFloat) -> CGFloat {
        let viewBoundsWidth: CGFloat = self.delegate?.getBoundsWidth() ?? 0
        self.logger.info("[MeetingRoomFreeBusyViewModel] viewBoundsWidth :\(viewBoundsWidth)")
        return viewBoundsWidth - rullerWidth
    }
    
    private func observeInstanceChanged(meetingRoom: Rust.MeetingRoom) {
        pushService?.rxMeetingRoomInstanceChanged
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] ids in
                guard let self = self else { return }
                if ids.contains(meetingRoom.calendarID) {
                    self.loadAttendee()
                }
            })
            .disposed(by: disposeBag)
    }
    
}
