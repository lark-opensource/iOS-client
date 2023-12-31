//
//  ArrangementController.swift
//  Calendar
//
//  Created by pluto on 2023/9/7.
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

final class ArrangementController: UIViewController, Timable, UserResolverWrapper {
    let logger = Logger.log(ArrangementController.self, category: "Calendar.ArrangementFreeBusy")

    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var timeZoneService: TimeZoneService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?

    var timer: Timer?
    private let disposeBag = DisposeBag()
    private var arrangmentView: ArrangementView
    private var viewBoundsWidth: CGFloat = 0

    let userResolver: UserResolver
    let viewModel: ArrangementViewModel
    var didSelectedTimes: ((_ start: Date, _ end: Date, _ timeZoneId: String) -> Void)?

    
    init(viewModel: ArrangementViewModel) {
        self.viewModel = viewModel
        self.userResolver = viewModel.userResolver
        self.arrangmentView = ArrangementView(content: viewModel.arrangementModel,
                                              is12HourStyle: viewModel.rxIs12HourStyle.value)
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        regist12HoursChange()
        CalendarMonitorUtil.startTrackFreebusyViewInAppendTime(calNum: viewModel.attendees.count)
    }
       
    private func regist12HoursChange() {
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
        viewBoundsWidth = view.bounds.width
        self.view.backgroundColor = UIColor.ud.bgBody
        layoutView()
        configViewInfo()
        addLisetener()
        viewModel.loadInstanceData(shouldRetry: true)
    }
    
    
    private func layoutView() {
        self.view.addSubview(arrangmentView)
        arrangmentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        arrangmentView.delegate = self
    }
    
    private func configViewInfo() {
        let model = viewModel.arrangementModel
        arrangmentView.setHeaderViewInfo(model: model.headerViewModel)
        arrangmentView.updateHeaderFooter(model: model)
        arrangmentView.setTimeZoneStr(timeZoneStr: model.getTzDisplayName())
        arrangmentView.updateCurrentUiDate(uiDate: model.getUiCurrentDate())
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        arrangmentView.relayoutArrangementPanel(newWidth: self.view.frame.width)
    }

    private func renewArrangmentView(is12HourStyle: Bool) {
        arrangmentView.removeFromSuperview()
        viewModel.arrangementModel.is12HourStyle = is12HourStyle
        arrangmentView = ArrangementView(content: viewModel.arrangementModel, is12HourStyle: is12HourStyle)
        layoutView()
        configViewInfo()
        viewModel.loadInstanceData(shouldRetry: true)
    }

    private func addLisetener() {
        localRefreshService?.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.arrangmentView.updateTimeLineViewFrame()
            }).disposed(by: disposeBag)
        
        viewModel.arrangementModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.arrangmentView.updateHeaderFooter(model: self.viewModel.arrangementModel)
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension ArrangementController: ArrangementViewDelegate {
    func arrangementViewClosed(_ arrangementView: ArrangementView) {
        dismissSelf()
    }

    // swiftlint:disable empty_count
    func arrangementViewDone(_ arrangementView: ArrangementView) {
        self.didSelectedTimes?(viewModel.arrangementModel.startTime, viewModel.arrangementModel.endTime, viewModel.arrangementModel.getEventTimezone().identifier)
        var conflict = CalendarTracer.CalTimeChangeParam.TimeConflict.noConflict
        if !viewModel.arrangementModel.workHourConflictCalendarIds.isEmpty {
            conflict = .workTime
        } else if viewModel.arrangementModel.freeBusyInfo?.totalCount != 0 {
            conflict = .eventConflict
        }
        CalendarTracer.shareInstance.calTimeChange(timeConflict: conflict)
        dismissSelf()
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("select_time")
            $0.mergeEventCommonParams(commonParam: CommonParamData(eventStartTime: Int(viewModel.arrangementModel.startTime.timeIntervalSince1970).description))
        }
    }

    func timeChanged(_ arrangementView: ArrangementView, startTime: Date, endTime: Date) {
        viewModel.arrangementModel.changeTimeRange(startTime: startTime, endTime: endTime)
        arrangementView.updateHeaderFooter(model: viewModel.arrangementModel)
    }

    func dateChanged(_ arrangementView: ArrangementView, date: Date) {
        viewModel.arrangementModel.changeTimeRange(by: date)
        arrangementView.updateHeaderFooter(model: viewModel.arrangementModel)
        viewModel.loadInstanceData(shouldRetry: false)
        arrangmentView.setTimeZoneStr(timeZoneStr: viewModel.arrangementModel.getTzDisplayName())
    }

    func moveAttendeeToFirst(_ arrangementView: ArrangementView, indexPath: IndexPath) {
        viewModel.arrangementModel.moveAttendeeToFirst(indexPath: indexPath)
    }

    func retry(_ arrangementView: ArrangementView) {
        viewModel.loadInstanceData(shouldRetry: true)
    }

    func timeZoneClicked() {
        // show dialog
        if self.viewModel.arrangementModel.shouldSwitchToEventTimezone {
            self.confirmSwitchTimezone {[weak self] in
                guard let self = self else { return }
                self.viewModel.arrangementModel.switchToEventTimezone()
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
extension ArrangementController {
    func goSelectTimeZoneVC() {
        guard let timeZoneService = self.timeZoneService else {
            logger.info("goSelectTimeZoneVC failed, can not get service from larkcontainer!")
            return
        }
        let previousTimeZone = self.viewModel.arrangementModel.getTimeZone()
        let selectTz = BehaviorRelay(value: previousTimeZone)
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectTz,
            anchorDate: self.viewModel.arrangementModel.startTime,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let self = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    self.viewModel.arrangementModel.updateTzInfo(timeZone: timeZone)
                    self.arrangmentView.setTimeZoneStr(timeZoneStr: self.viewModel.arrangementModel.getTzDisplayName())
                    self.arrangmentView.updateCurrentUiDate(uiDate: self.viewModel.arrangementModel.getUiCurrentDate())
                    self.viewModel.loadInstanceData(shouldRetry: false)
                }
            }
        )
        self.present(popupVC, animated: true, completion: nil)

        CalendarTracer.shareInstance.calClickTimeZoneEntry(from: .findtime)
    }

    var is12HourStyle: Bool {
        viewModel.rxIs12HourStyle.value
    }
}

extension ArrangementController: ArrangementViewModelDelegate {
    func getBoundsWidth() -> CGFloat {
        return viewBoundsWidth
    }
    
    func hideLoading(shouldRetry: Bool, failed: Bool) {
        arrangmentView.hideLoading(shouldRetry: shouldRetry, failed: failed)
    }
    
    func showLoading(shouldRetry: Bool) {
        arrangmentView.showLoading(shouldRetry: shouldRetry)
    }
    
    func reloadViewWithInstanceData() {
        arrangmentView.reloadServerData(model: viewModel.arrangementModel)
        if Display.pad {
            self.viewWillLayoutSubviews()
        }
        arrangmentView.scrollToCenter(animated: false)
    }
    
    func showGuide() {
        if self.viewIfLoaded?.window != nil,
           CalConfig.isMultiTimeZone,
           self.viewModel.arrangementModel.headerViewModel.shouldShowTimeString,
           let headerCell = self.arrangmentView.headerFirstCell(),
           let newGuideManager = self.newGuideManager {
            GuideService.checkShowTzInfoGuide(controller: self, newGuideManager: newGuideManager, referView: headerCell)
        }
    }
    
    func cleanInstance(calendarIds: [String], startTime: Date, endTime: Date) {
        arrangmentView.cleanInstance(calendarIds: calendarIds, startTime: startTime, endTime: endTime)
    }
}
