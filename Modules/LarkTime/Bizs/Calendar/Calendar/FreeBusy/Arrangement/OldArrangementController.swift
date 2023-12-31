//
//  OldArrangementController.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/19.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import LarkUIKit
import RoundedHUD
import LarkContainer
import Swinject
import UniverseDesignDialog
import LKCommonsLogging
import LarkGuide

final class OldArrangementController: UIViewController, Timable, UserResolverWrapper {
    var timer: Timer?
    private let dataLoader: ArrangementDataLoaderProtocol
    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    let logger = Logger.log(OldArrangementController.self, category: "Calendar.FreeBusy")

    private var arrangmentView: ArrangementView
    private var arrangementModel: ArrangmentModel
    var didSelectedTimes: ((_ start: Date, _ end: Date, _ timeZoneId: String) -> Void)?

    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var timeZoneService: TimeZoneService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?

    let defaultIs12HourStyle: Bool

    init(userResolver: UserResolver,
         dataLoader: ArrangementDataLoaderProtocol,
         attendees: [UserAttendeeBaseDisplayInfo],
         startTime: Date,
         endTime: Date,
         is12HourStyle: Bool,
         currentUserCalendarId: String,
         organizerCalendarId: String,
         rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>,
         timeZoneId: String) {
        CalendarMonitorUtil.startTrackFreebusyViewInAppendTime(calNum: attendees.count)
        self.userResolver = userResolver
        self.defaultIs12HourStyle = is12HourStyle
        let arrangementModel = ArrangmentModel(sunStateService: SunStateService(userResolver: userResolver),
                                               startTime: startTime,
                                               endTime: endTime,
                                               attendees: attendees,
                                               currentUserCalendarId: currentUserCalendarId,
                                               organizerCalendarId: organizerCalendarId,
                                               firstWeekday: SettingService.shared().getSetting().firstWeekday,
                                               is12HourStyle: is12HourStyle,
                                               rxTimezoneDisplayType: rxTimezoneDisplayType,
                                               timeZone: TimeZone(identifier: timeZoneId) ?? TimeZone.current)
        self.arrangementModel = arrangementModel
        self.dataLoader = dataLoader
        self.arrangmentView = ArrangementView(content: arrangementModel, is12HourStyle: is12HourStyle)

        super.init(nibName: nil, bundle: nil)
        calendarDependency?.is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            self?.renewArrangmentView(is12HourStyle: is12HourStyle)
        }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTimer(&timer) { [weak self] in
            self?.localRefreshService?.rxMainViewNeedRefresh.onNext(())
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer(&timer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(arrangmentView)
        arrangmentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        arrangmentView.delegate = self
        arrangmentView.setHeaderViewInfo(model: arrangementModel.headerViewModel)
        arrangmentView.updateHeaderFooter(model: arrangementModel)
        arrangmentView.setTimeZoneStr(timeZoneStr: arrangementModel.getTzDisplayName())
        arrangmentView.updateCurrentUiDate(uiDate: arrangementModel.getUiCurrentDate())
        CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()
        loadData(shouldRetry: true, is12HourStyle: self.is12HourStyle)
        arrangmentView.scrollToCenter(animated: false)
        addLisetener()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        arrangmentView.relayoutArrangementPanel(newWidth: self.view.frame.width)
    }

    private func renewArrangmentView(is12HourStyle: Bool) {
        arrangmentView.removeFromSuperview()
        arrangementModel.is12HourStyle = is12HourStyle
        arrangmentView = ArrangementView(content: arrangementModel, is12HourStyle: is12HourStyle)
        self.view.addSubview(arrangmentView)
        arrangmentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        arrangmentView.delegate = self
        arrangmentView.setHeaderViewInfo(model: arrangementModel.headerViewModel)
        arrangmentView.updateHeaderFooter(model: arrangementModel)
        arrangmentView.setTimeZoneStr(timeZoneStr: arrangementModel.getTzDisplayName())
        arrangmentView.updateCurrentUiDate(uiDate: arrangementModel.getUiCurrentDate())
        loadData(shouldRetry: true, is12HourStyle: is12HourStyle)
        arrangmentView.scrollToCenter(animated: false)
    }

    private func addLisetener() {
        localRefreshService?.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.arrangmentView.updateTimeLineViewFrame()
            }).disposed(by: disposeBag)
        arrangementModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.arrangmentView.updateHeaderFooter(model: self.arrangementModel)
            }).disposed(by: disposeBag)
    }

    private func loadSunState() {
        arrangementModel.sunStateService.loadData(citys: Array(arrangementModel.timezoneMap.values),
                                                  date: Int64(arrangementModel.startTime.timeIntervalSince1970))
    }

    private func loadData(shouldRetry: Bool, is12HourStyle: Bool) {
        loadData(calendarIds: arrangementModel.calendarIds,
                 cellWidth: arrangementModel.cellWidth(with: TimeIndicator.indicatorWidth(is12HourStyle: is12HourStyle), totalWidth: view.bounds.width),
                 startTime: arrangementModel.startTime,
                 endTime: arrangementModel.endTime,
                 shouldRetry: shouldRetry)
    }

    private func loadData(calendarIds: [String],
                          cellWidth: CGFloat,
                          startTime: Date,
                          endTime: Date,
                          shouldRetry: Bool) {
        self.arrangmentView.showLoading(shouldRetry: shouldRetry)
        self.arrangmentView.cleanInstance(calendarIds: calendarIds,
                                          startTime: arrangementModel.calibrationDateForUI(date: startTime),
                                          endTime: arrangementModel.calibrationDateForUI(date: endTime))
        dataLoader.loadInstanceData(calendarIds: calendarIds,
                                    date: startTime,
                                    panelSize: CGSize(width: cellWidth, height: 1200),
                                    timeZoneId: arrangementModel.getTimeZone().identifier)
            .collectSlaInfo(.FreeBusyInstance, action: "load_instance", source: "append")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] serverInstanceData in
                guard let `self` = self else { return }
                self.arrangmentView.hideLoading(shouldRetry: shouldRetry, failed: false)
                self.arrangementModel.changeServerData(serverInstanceData)
                self.loadSunState()
                self.arrangmentView.reloadServerData(model: self.arrangementModel)
                if Display.pad {
                    self.viewWillLayoutSubviews()
                }
                CalendarMonitorUtil.endTrackFreebusyViewInAppendTime()
                if self.viewIfLoaded?.window != nil,
                   CalConfig.isMultiTimeZone,
                   self.arrangementModel.headerViewModel.shouldShowTimeString,
                   let headerCell = self.arrangmentView.headerFirstCell(),
                   let newGuideManager = self.newGuideManager {
                    GuideService.checkShowTzInfoGuide(controller: self, newGuideManager: newGuideManager, referView: headerCell)
                }

                }, onError: { [weak self] (_) in
                    guard let `self` = self else { return }
                    self.arrangementModel.changeServerData(ServerInstanceData())
                    self.arrangmentView.reloadServerData(model: self.arrangementModel)

                    self.arrangmentView.hideLoading(shouldRetry: shouldRetry, failed: true)
                    if Display.pad {
                        self.viewWillLayoutSubviews()
                    }
                }, onDisposed: { [weak self] in
                    if self == nil {
                        self?.arrangmentView.hideLoading(shouldRetry: false, failed: false)
                    }
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension OldArrangementController: ArrangementViewDelegate {
    func arrangementViewClosed(_ arrangementView: ArrangementView) {
        dismissSelf()
    }

    // swiftlint:disable empty_count
    func arrangementViewDone(_ arrangementView: ArrangementView) {
        self.didSelectedTimes?(arrangementModel.startTime, arrangementModel.endTime, arrangementModel.getEventTimezone().identifier)
        typealias Param = CalendarTracer.CalTimeChangeParam
        var conflict = Param.TimeConflict.noConflict
        if !arrangementModel.workHourConflictCalendarIds.isEmpty {
            conflict = .workTime
        } else if arrangementModel.freeBusyInfo?.totalCount != 0 {
            conflict = .eventConflict
        }
        CalendarTracer.shareInstance.calTimeChange(timeConflict: conflict)
        dismissSelf()
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("select_time")
            $0.mergeEventCommonParams(commonParam: CommonParamData(eventStartTime: Int(arrangementModel.startTime.timeIntervalSince1970).description))
        }
    }

    func timeChanged(_ arrangementView: ArrangementView, startTime: Date, endTime: Date) {
        arrangementModel.changeTimeRange(startTime: startTime, endTime: endTime)
        arrangementView.updateHeaderFooter(model: arrangementModel)
    }

    func dateChanged(_ arrangementView: ArrangementView, date: Date) {
        arrangementModel.changeTimeRange(by: date)
        arrangementView.updateHeaderFooter(model: arrangementModel)
        loadData(shouldRetry: false, is12HourStyle: self.is12HourStyle)
        arrangmentView.setTimeZoneStr(timeZoneStr: arrangementModel.getTzDisplayName())
    }

    func moveAttendeeToFirst(_ arrangementView: ArrangementView, indexPath: IndexPath) {
        arrangementModel.moveAttendeeToFirst(indexPath: indexPath)
    }

    func retry(_ arrangementView: ArrangementView) {
        loadData(shouldRetry: true, is12HourStyle: self.is12HourStyle)
    }

    func timeZoneClicked() {
        // show dialog
        if self.arrangementModel.shouldSwitchToEventTimezone {
            self.confirmSwitchTimezone {[weak self] in
                guard let self = self else { return }
                self.arrangementModel.switchToEventTimezone()
                self.renewArrangmentView(is12HourStyle: self.is12HourStyle)
                self.goSelectTimeZoneVC()
            }
        } else {
            goSelectTimeZoneVC()
        }
    }

    // 当日程时区跟设备时区不同时，改变时区需要弹窗确认，确认后会切换为日程时区
    private func confirmSwitchTimezone( completion: @escaping () -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.Calendar.Calendar_G_EditAfterSwitchZone)
        dialog.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.Calendar.Calendar_G_SwitchButton, dismissCompletion: completion)
        self.present(dialog, animated: true)
    }
}
extension OldArrangementController {
    func goSelectTimeZoneVC() {
        guard let timeZoneService = self.timeZoneService else {
            logger.info("goSelectTimeZoneVC failed, can not get service from larkcontainer!")
            return
        }
        let previousTimeZone = self.arrangementModel.getTimeZone()
        let selectTz = BehaviorRelay(value: previousTimeZone)
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectTz,
            anchorDate: self.arrangementModel.startTime,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let self = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    self.arrangementModel.updateTzInfo(timeZone: timeZone)
                    self.arrangmentView.setTimeZoneStr(timeZoneStr: self.arrangementModel.getTzDisplayName())
                    self.arrangmentView.updateCurrentUiDate(uiDate: self.arrangementModel.getUiCurrentDate())
                    self.loadData(shouldRetry: false, is12HourStyle: self.is12HourStyle)
                }
            }
        )
        self.present(popupVC, animated: true, completion: nil)

        CalendarTracer.shareInstance.calClickTimeZoneEntry(from: .findtime)
    }

    var is12HourStyle: Bool {
        calendarDependency?.is12HourStyle.value ?? defaultIs12HourStyle
    }
}
