//
//  ArrangementViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import RxRelay
import RxSwift
import Foundation
import LarkContainer
import LKCommonsLogging

protocol ArrangementViewModelDelegate: AnyObject {
    func getBoundsWidth() -> CGFloat
    func hideLoading(shouldRetry: Bool, failed: Bool)
    func showLoading(shouldRetry: Bool)
    func reloadViewWithInstanceData()
    func showGuide()
    func cleanInstance(calendarIds: [String], startTime: Date, endTime: Date)
}

class ArrangementViewModel: FreeBusyDetailViewModel {
    let logger = Logger.log(ArrangementViewModel.self, category: "Calendar.ArrangementViewModel")
    
    lazy var arrangementModel = ArrangmentModel(sunStateService: SunStateService(userResolver: userResolver),
                                                startTime: startTime,
                                                endTime: endTime,
                                                attendees: attendees,
                                                currentUserCalendarId: currentUserCalendarId,
                                                organizerCalendarId: organizerCalendarId,
                                                firstWeekday: firstWeekday,
                                                is12HourStyle: rxIs12HourStyle.value,
                                                rxTimezoneDisplayType: rxTimezoneDisplayType,
                                                timeZone: TimeZone(identifier: timeZoneId) ?? TimeZone.current)

    let attendees: [UserAttendeeBaseDisplayInfo]
    let startTime: Date
    let endTime: Date
    let organizerCalendarId: String
    let rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>
    let timeZoneId: String
    
    weak var delegate: ArrangementViewModelDelegate?
    
    init(userResolver: UserResolver,
         dataSource: ArrangementDataSource) {
        self.attendees = dataSource.attendees
        self.startTime = dataSource.startTime
        self.endTime = dataSource.endTime
        self.organizerCalendarId = dataSource.organizerCalendarId
        self.rxTimezoneDisplayType = dataSource.rxTimezoneDisplayType
        self.timeZoneId = dataSource.timeZoneId
        super.init(userResolver: userResolver)
        self.filterParam = dataSource.filterParam
    }
    
    private func cleanInstance() {
        DispatchQueue.main.async {
            self.delegate?.cleanInstance(calendarIds: self.arrangementModel.calendarIds,
                                         startTime: self.arrangementModel.calibrationDateForUI(date: self.arrangementModel.startTime),
                                         endTime: self.arrangementModel.calibrationDateForUI(date: self.arrangementModel.endTime))
        }
    }
    
    func loadInstanceData(shouldRetry: Bool) {
        DispatchQueue.main.async {
            self.delegate?.showLoading(shouldRetry: shouldRetry)
        }
        cleanInstance()
        let viewBoundsWidth: CGFloat = self.delegate?.getBoundsWidth() ?? 0
        logger.info("[ArrangementViewModel] viewBoundsWidth :\(viewBoundsWidth)")
        let cellWidth: CGFloat = arrangementModel.cellWidth(with: TimeIndicator.indicatorWidth(is12HourStyle: rxIs12HourStyle.value), totalWidth: viewBoundsWidth)
        CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()

        loadInstanceData(calendarIds: arrangementModel.calendarIds,
                         date: arrangementModel.startTime,
                         panelSize: CGSize(width: cellWidth, height: 1200),
                         timeZoneId: arrangementModel.getTimeZone().identifier)
        .collectSlaInfo(.FreeBusyInstance, action: "load_instance", source: "append")
        .subscribe(onNext: { [weak self] serverInstanceData in
            guard let self = self else { return }
            self.logger.info( "[ArrangementViewModel] loadInstanceData success with: \(serverInstanceData)")
            CalendarMonitorUtil.endTrackFreebusyViewInAppendTime()

            self.arrangementModel.changeServerData(serverInstanceData)
            self.loadSunState()
            
            DispatchQueue.main.async {
                self.delegate?.hideLoading(shouldRetry: shouldRetry, failed: false)
                self.delegate?.reloadViewWithInstanceData()
                self.delegate?.showGuide()
            }
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            self.logger.error("loadInstanceData failed with: \(error)")
            self.arrangementModel.changeServerData(ServerInstanceData())
            DispatchQueue.main.async {
                self.delegate?.hideLoading(shouldRetry: shouldRetry, failed: true)
                self.delegate?.reloadViewWithInstanceData()
            }
        }, onDisposed: { [weak self] in
            DispatchQueue.main.async {
                self?.delegate?.hideLoading(shouldRetry: false, failed: false)
            }
        }).disposed(by: disposeBag)
    }
    
    
    private func loadSunState() {
        arrangementModel.sunStateService.loadData(citys: Array(arrangementModel.timezoneMap.values),
                                                  date: Int64(arrangementModel.startTime.timeIntervalSince1970))
    }
}
