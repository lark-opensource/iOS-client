//
//  FreeBusyController.swift
//  Calendar
//
//  Created by pluto on 2023/9/7.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import RoundedHUD
import LarkUIKit
import LarkContainer
import EENavigator
import UniverseDesignToast
import LKCommonsLogging

final class FreeBusyController: UIViewController {
    let logger = Logger.log(FreeBusyController.self, category: "Calendar.FreeBusyController")

    /// 月历/滑动切换日期会调用多次，暂时依靠这个过滤埋点上报频率，后续切换UD组件fix
    private let debouncer: Debouncer = Debouncer(delay: 0.2)
    
    lazy var  freeBusyView: FreeBusyView = {
        let view = FreeBusyView(startDate: Date(),
                                firstWeekday: viewModel.firstWeekday,
                                getNewEventMinute: viewModel.defaultDurationGetter,
                                is12HourStyle: viewModel.rxIs12HourStyle.value,
                                showHeaderView: true)
        return view
    }()
    
    let viewModel: FreeBusyViewModel
    let userResolver: UserResolver
    let disposeBag = DisposeBag()
    
    var needLazyLoad: Bool = false
    private var viewBoundsWidth: CGFloat = 0

    init(viewModel: FreeBusyViewModel) {
        self.viewModel = viewModel
        self.userResolver = viewModel.userResolver
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        CalendarMonitorUtil.startTrackFreebusyViewInProfileTime()
        regist12HoursChange()
        self.view.backgroundColor = UIColor.ud.bgBody
        layoutFreeBusyView(freeBusyView)
    }
    
    private func regist12HoursChange() {
        viewModel.rxIs12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            guard let `self` = self else { return }
            self.viewModel.freeBusyModel.changeIs12HourStyle(is12HourStyle: is12HourStyle)
            self.renewFreeBusyView(freeBusyModel: self.viewModel.freeBusyModel)
        }).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewData()
        setupFreeBusyView(freeBusyView)
        viewModel.trackCalendarProfile()
    }

    private func bindViewData() {
        viewModel.freeBusyModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateHeaderViewInfo(freeBusyModel: self.viewModel.freeBusyModel)
            }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        SettingService.shared().stateManager.activate()
        if needLazyLoad {
            freeBusyView.reloadData()
            needLazyLoad = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        freeBusyView.scrollToTime(time: viewModel.freeBusyModel.getUiCurrentDate(), animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        freeBusyView.relayoutForiPad(newWidth: self.view.frame.width)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewBoundsWidth = view.bounds.width
    }

    private func renewFreeBusyView(freeBusyModel: FreeBusyControllerModel) {
        freeBusyView.removeFromSuperview()
        freeBusyView = FreeBusyView(startDate: Date(),
                                    firstWeekday: viewModel.firstWeekday,
                                    getNewEventMinute: viewModel.defaultDurationGetter,
                                    is12HourStyle: viewModel.rxIs12HourStyle.value)
        layoutFreeBusyView(freeBusyView)
        setupFreeBusyView(freeBusyView)
        viewModel.loadAttendees()
    }

    private func setupFreeBusyView(_ freeBusyView: FreeBusyView) {
        freeBusyView.delegate = self
        freeBusyView.addNewEvent = { [weak self] (startTime, endTime) in
            guard let `self` = self else { return }
            CalendarTracer.shareInstance.calProfileBlock()
            self.freeBusyView.hideInterval()
            
            let startDate = self.viewModel.freeBusyModel.calibrationDate(date: startTime)
            let endDate = self.viewModel.freeBusyModel.calibrationDate(date: endTime)
            let restrictedUserids = self.viewModel.freeBusyModel.usersRestrictedForNewEvent
            let filteredAttendees = self.viewModel.freeBusyModel.attendees.filter { !restrictedUserids.contains($0.id) }
            let calendarID = self.viewModel.currentUserCalendarId

            self.viewModel.freeBusyModel.changeInstanceMap(calendarInstanceMap: [:])
            self.createEvent(withStartDate: startDate, endDate: endDate, attendees: filteredAttendees, calendarID: calendarID)
            self.viewModel.trackCalFullEditEvent()
        }
        freeBusyView.setTimeZoneStr(timeZoneStr: viewModel.freeBusyModel.getTzDisplayName())
    }

    private func layoutFreeBusyView(_ freeBusyView: FreeBusyView) {
        view.insertSubview(freeBusyView, at: 0)
        freeBusyView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func createEvent(
        withStartDate startDate: Date,
        endDate: Date,
        attendees: [CalendarEventAttendeeEntity],
        calendarID: String
    ) {
        ReciableTracer.shared.recStartEditEvent()
        let editCoordinator = viewModel.getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = startDate
            contextPointer.pointee.endDate = endDate
            contextPointer.pointee.attendeeSeeds = attendees
                .compactMap { $0.chatterId }
                .map { .user(chatterId: $0) }

            contextPointer.pointee.meetingRooms = []
            contextPointer.pointee.calendarID = calendarID
        }
        editCoordinator.delegate = self
        editCoordinator.actionSource = .profile
        editCoordinator.start(from: self)
        CalendarTracerV2.CalendarProfile.traceClick {
            $0.click("full_create_event").target("cal_event_full_create_view")
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            UDToast.removeToast(on: self.view)
        }
    }

    func updateHeaderViewInfo(freeBusyModel: FreeBusyControllerModel) {
        freeBusyView.setHeaderFoorterViewInfo(model: freeBusyModel.headerViewModel,
                                              footerAttributedString: freeBusyModel.footerAttrText)
    }
}

extension FreeBusyController: EventEditCoordinatorDelegate {
    
    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span, extraData: EventEditExtraData?) {
        viewModel.createEventSucceedHandler(pbEvent, self)
        needLazyLoad = true
    }
}

extension FreeBusyController: FreeBusyViewDelegate {
    func removeHUD() {
        UDToast.removeToast(on: self.view)
    }

    func showHUDLoading(with text: String) {
        UDToast.showLoading(with: text, on: self.view)
    }

    func showHUDFailure(with text: String) {
        UDToast.showFailure(with: text, on: self.view)
    }

    func getCalendarIds(_ freeBusyView: FreeBusyView) -> [String] {
        return viewModel.freeBusyModel.calendarIds
    }

    func freeBusyView(_ freeBusyView: FreeBusyView, date: Date) throws -> (InstanceMap, [String: [WorkingHoursTimeRange]], [String: Bool])? {
        return try viewModel.loadInstanceData(date: date)
    }

    func freeBusyViewClosed(_ freeBusyView: FreeBusyView) {
        dismiss(animated: true, completion: nil)
    }

    func dateChanged(_ freeBusyView: FreeBusyView, monthViewChanged date: Date) {
        debouncer.call {
            CalendarTracerV2.CalendarProfile.traceClick {
                $0.click("day_change").target("none")
            }
        }
    }

    func dateChanged(_ freeBusyView: FreeBusyView, pageChanged date: Date) {
        self.freeBusyView.setTimeZoneStr(timeZoneStr: self.viewModel.freeBusyModel.getTzDisplayName(uiDate: date))
        debouncer.call {
            CalendarTracerV2.CalendarProfile.traceClick {
                $0.click("day_change").target("none")
            }
        }
    }

    func timeChanged(_ freeBusyView: FreeBusyView, startTime: Date, endTime: Date) {
        self.viewModel.freeBusyModel.changeTime(startTime: startTime, endTime: endTime)
        updateHeaderViewInfo(freeBusyModel: viewModel.freeBusyModel)
    }

    func intervalStateChanged(_ freeBusyView: FreeBusyView,
                              isHidden: Bool,
                              instanceMap: InstanceMap) {
        viewModel.freeBusyModel.changeInstanceMap(calendarInstanceMap: instanceMap)
        updateHeaderViewInfo(freeBusyModel: viewModel.freeBusyModel)
    }

    func timeZoneClicked() {
        guard let timeZoneService = self.viewModel.timeZoneService else {
            logger.info("goSelectTimeZoneVC failed, can not get service from larkcontainer!")
            return
        }
        let previousTimeZone = self.viewModel.freeBusyModel.getTimeZone()
        let selectTz = BehaviorRelay(value: previousTimeZone)
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectTz,
            anchorDate: self.viewModel.freeBusyModel.startTime,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let self = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    self.viewModel.freeBusyModel.updateTzInfo(timeZone: timeZone)
                    self.freeBusyView.setTimeZoneStr(timeZoneStr: self.viewModel.freeBusyModel.getTzDisplayName())
                    self.freeBusyView.updateCurrentUiDate(
                        uiDate: self.viewModel.freeBusyModel.getUiCurrentDate(),
                        with: TimeZone(identifier: timeZone.identifier) ?? .current
                    )
                    self.freeBusyView.reloadData()
                }

            }
        )
        self.present(popupVC, animated: true, completion: nil)

        CalendarTracer.shareInstance.calClickTimeZoneEntry(from: .profile)
    }

    func getUiCurrentDate() -> Date {
        viewModel.freeBusyModel.getUiCurrentDate()
    }

    func jumpToEventDetail(_ detailVC: UIViewController) {
        self.userResolver.navigator.push(detailVC, from: self)
    }
}

extension FreeBusyController: FreeBusyViewModelDelegate {
    func showLoading() {
        freeBusyView.showLoading()
    }
    
    func hideLoading() {
        freeBusyView.hideLoading()
    }
    func reloadViewWithInstanceData() {
        freeBusyView.reloadData()
    }
    
    func getBoundsWidth() -> CGFloat {
        return self.viewBoundsWidth
    }
    
    func updateHeaderFooterInfo(freeBusyModel: FreeBusyControllerModel) {
        updateHeaderViewInfo(freeBusyModel: freeBusyModel)
    }
    
    func showFailedWithRetry() {
        self.freeBusyView.showFailed(retry: {
            self.viewModel.loadAttendees()
        })
    }
}

extension FreeBusyController {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer,
           let view = pan.view {
            if view.transform.isIdentity { return true }
            let currentLocationY = pan.location(in: view).y
            let translationY = pan.translation(in: view).y
            return currentLocationY - translationY < 50
        }
        return true
    }
}
