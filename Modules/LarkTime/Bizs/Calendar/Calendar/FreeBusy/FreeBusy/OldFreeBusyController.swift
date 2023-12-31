//
//  OldFreeBusyController.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/7.
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

typealias GetAttendeesByUserId = (_ userIds: [String]) -> Observable<[PBAttendee]>

final class OldFreeBusyController: UIViewController, UIGestureRecognizerDelegate, UserResolverWrapper {

    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarInterface: CalendarInterface?

    let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    private let dataLoader: ArrangementDataLoaderProtocol
    private var freeBusyView: FreeBusyView
    private let userIds: [String]
    private let firstWeekday: DaysOfWeek

    private let attendeesGetter: GetAttendeesByUserId
    private var freeBusyModel: FreeBusyControllerModel
    private let getNewEventMinute: () -> Int
    private let getCreateEventCoordinator: GetCreateEventCoordinator
    private var createEventSucceedHandler: CreateEventSucceedHandler
    private let is12HourStyle: BehaviorRelay<Bool>
    private let getNormalDetailController: GetNormalDetailController
    private var hud: RoundedHUD? = RoundedHUD()
    private let timeZoneService: TimeZoneService

    private let meetingRoom: Rust.MeetingRoom?
    private var meetingRoomInfoTransform = CGAffineTransform.identity
    // 会议室当前个人用量
    private var rxOverUsageLimit: BehaviorRelay<Bool> = .init(value: false)

    /// 埋点专用，获取对方主日历id后埋点
    private let isFromProfile: Bool
    /// 埋点专用
    private var hasTrackedProfile: Bool = false
    /// 月历/滑动切换日期会调用多次，暂时依靠这个过滤埋点上报频率，后续切换UD组件fix
    private let debouncer: Debouncer = Debouncer(delay: 0.2)

    var eventCreateBody: CalendarCreateEventBody?
    var needLazyLoad: Bool = false
    private var viewBoundsWidth: CGFloat = 0

    init(userResolver: UserResolver,
         userIds: [String],
         currentUserCalendarId: String,
         firstWeekday: DaysOfWeek,
         getNewEventMinute: @escaping (() -> Int),
         attendeesGetter: @escaping GetAttendeesByUserId,
         dataLoader: ArrangementDataLoaderProtocol,
         getCreateEventCoordinator: @escaping GetCreateEventCoordinator,
         createEventSucceedHandler: @escaping CreateEventSucceedHandler,
         getNormalDetailController: @escaping GetNormalDetailController,
         is12HourStyle: BehaviorRelay<Bool>,
         timeZoneService: TimeZoneService,
         isFromProfile: Bool,
         eventCreateBody: CalendarCreateEventBody? = nil,
         meetingRoom: Rust.MeetingRoom? = nil,
         startDate: Date = Date()) {

        self.userResolver = userResolver
        self.firstWeekday = firstWeekday
        self.userIds = userIds
        self.attendeesGetter = attendeesGetter
        self.getNewEventMinute = getNewEventMinute
        self.dataLoader = dataLoader
        self.getCreateEventCoordinator = getCreateEventCoordinator
        self.createEventSucceedHandler = createEventSucceedHandler
        self.getNormalDetailController = getNormalDetailController
        self.is12HourStyle = is12HourStyle
        self.isFromProfile = isFromProfile
        let freeBusyModel = FreeBusyControllerModel(sunStateService: SunStateService(userResolver: userResolver),
            currentUserCalendarId: currentUserCalendarId,
            is12HourStyle: is12HourStyle.value
        )
        self.freeBusyModel = freeBusyModel
        self.meetingRoom = meetingRoom

        if isFromProfile {
            CalendarMonitorUtil.startTrackFreebusyViewInProfileTime()
        }
        // 带会议室时 直接隐藏headerView
        let showHeaderView = eventCreateBody.map { $0.meetingRoom.isEmpty } ?? true

        self.freeBusyView = FreeBusyView(
            startDate: startDate,
            firstWeekday: firstWeekday,
            getNewEventMinute: getNewEventMinute,
            is12HourStyle: freeBusyModel.is12HourStyle,
            showHeaderView: showHeaderView
        )
        if meetingRoom != nil {
            self.freeBusyView.arrangePanelTitle = BundleI18n.Calendar.Calendar_Rooms_ReserveRoms
        }
        self.freeBusyView.meetingRoomMaxDuration = meetingRoom?.schemaExtraData.cd.resourceStrategy.map { TimeInterval($0.singleMaxDuration) }
        self.timeZoneService = timeZoneService
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.ud.bgBody
        layoutFreeBusyView(freeBusyView)
        is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            guard let `self` = self else { return }
            self.freeBusyModel.changeIs12HourStyle(is12HourStyle: is12HourStyle)
            self.renewFreeBusyView(freeBusyModel: self.freeBusyModel)
        }).disposed(by: disposeBag)
        configCallBack()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewData()
        setupFreeBusyView(freeBusyView)
        loadAttendees(userIds: userIds)

        if let meetingRoom = meetingRoom {
            addMeetingRoomInfoView(meetingRoom: meetingRoom)
            observeInstanceChanged(meetingRoom: meetingRoom)
        }
        trackCalendarProfile()
    }

    private func bindViewData() {
        freeBusyModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateHeaderViewInfo(freeBusyModel: self.freeBusyModel)
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

        freeBusyView.scrollToTime(time: freeBusyModel.getUiCurrentDate(), animated: false)
    }

    override public func viewWillDisappear(_ animated: Bool) {
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
    
    
    private func configCallBack() {
        freeBusyView.arrangementCellClickCallBack = { [weak self] instance in
            guard let self = self else { return }
            let detailVC: UIViewController
            if instance.isEditable {
                guard let calendarInterface = self.calendarInterface else { return }
                detailVC = calendarInterface.getEventContentController(with: instance.key,
                                                                            calendarId: instance.currentUserAccessibleCalendarID,
                                                                            originalTime: instance.originalTime,
                                                                            startTime: instance.startTime,
                                                                            endTime: instance.endTime,
                                                                            instanceScore: "",
                                                                            isFromChat: false,
                                                                            isFromNotification: false,
                                                                            isFromMail: false,
                                                                            isFromTransferEvent: false,
                                                                       isFromInviteEvent: false,
                                                                       scene: .calendarView)
            } else {
                detailVC = EventDetailBuilder.build(userResolver: self.userResolver, roomInstance: instance)
            }
            self.jumpToEventDetail(detailVC)
        }
    }

    private func cellWidth(with rullerWidth: CGFloat) -> CGFloat {
        let showHeaderView = eventCreateBody.map { $0.meetingRoom.isEmpty } ?? true
        if showHeaderView {
            return (viewBoundsWidth - rullerWidth) / CGFloat(2)
        } else {
            return viewBoundsWidth - rullerWidth
        }
    }

    private func renewFreeBusyView(freeBusyModel: FreeBusyControllerModel) {
        freeBusyView.removeFromSuperview()
        freeBusyView = FreeBusyView(startDate: Date(),
                                    firstWeekday: firstWeekday,
                                    getNewEventMinute: getNewEventMinute,
                                    is12HourStyle: freeBusyModel.is12HourStyle)
        layoutFreeBusyView(freeBusyView)
        setupFreeBusyView(freeBusyView)
        loadAttendees(userIds: userIds)
    }

    private func addMeetingRoomInfoView(meetingRoom: Rust.MeetingRoom) {
        let context = DetailOnlyContext(calendarID: meetingRoom.calendarID)
        let meetingRoomDetailVC = MeetingRoomDetailViewController(viewModel: MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver), userResolver: self.userResolver)

        addChild(meetingRoomDetailVC)
        view.addSubview(meetingRoomDetailVC.view)
        meetingRoomDetailVC.containerView.isScrollEnabled = true
        meetingRoomDetailVC.view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.snp.bottom).offset(-88)
            make.height.equalToSuperview().dividedBy(2)
        }
        meetingRoomDetailVC.isNavigationBarHidden = true

        meetingRoomDetailVC.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        meetingRoomDetailVC.view.layer.cornerRadius = 7
        meetingRoomDetailVC.view.layer.shadowOffset = CGSize(width: 0, height: -3)
        meetingRoomDetailVC.view.layer.shadowOpacity = 1
        meetingRoomDetailVC.view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm, bindTo: view)
        meetingRoomDetailVC.titleView.subTitleLabel.numberOfLines = 1
        meetingRoomDetailVC.titleView.subTitleLabel.font = .ud.body2
        meetingRoomDetailVC.titleView.subTitleLabel.lineBreakMode = .byTruncatingTail
        meetingRoomDetailVC.titleView.titleLabel.numberOfLines = 0
        meetingRoomDetailVC.titleView.titleLabel.font = .ud.title3
        meetingRoomDetailVC.titleView.titleLabel.lineBreakMode = .byTruncatingTail

        var panIndicatorView: UIView = {
            let indicatorView = UIView()
            indicatorView.layer.cornerRadius = 2
            indicatorView.backgroundColor = UIColor.ud.N300
            return indicatorView
        }()

        meetingRoomDetailVC.view.addSubview(panIndicatorView)
        panIndicatorView.snp.makeConstraints {
            $0.width.equalTo(40)
            $0.height.equalTo(4)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
        }

        let pan = UIPanGestureRecognizer()
        meetingRoomDetailVC.view.addGestureRecognizer(pan)
        pan.delegate = self
        pan.rx.event.asDriver().drive(onNext: { [weak self, weak meetingRoomDetailVC] gesture in
            guard let originalTransform = self?.meetingRoomInfoTransform,
                  let view = gesture.view else { return }

            let minY = -(self?.view.bounds.height ?? 0) / 2 + 88
            let maxY: CGFloat = 0

            switch gesture.state {
            case .changed:
                let translation = gesture.translation(in: nil)
                var targetTransform = originalTransform.translatedBy(x: 0, y: translation.y)
                targetTransform.ty = max(minY, min(maxY, targetTransform.ty))
                view.transform = targetTransform
            case .cancelled, .ended:
                let centerPoint = (minY + maxY) / 2
                let finalY = view.transform.ty > centerPoint ? maxY : minY
                var finalTransform = view.transform
                finalTransform.ty = finalY
                if finalY == maxY {
                    meetingRoomDetailVC?.containerView.contentOffset = .zero
                }
                self?.meetingRoomInfoTransform = finalTransform
                UIView.animate(withDuration: 0.2) {
                    view.transform = finalTransform
                }
            default:
                // do nothing
                break
            }
        })
        .disposed(by: disposeBag)
        meetingRoomDetailVC.containerView.panGestureRecognizer.require(toFail: pan)

        meetingRoomDetailVC.didMove(toParent: self)
    }

    private func observeInstanceChanged(meetingRoom: Rust.MeetingRoom) {
        pushService?.rxMeetingRoomInstanceChanged
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] ids in
                guard let self = self else { return }
                if ids.contains(meetingRoom.calendarID) {
                    self.loadAttendees(userIds: self.userIds)
                }
            })
            .disposed(by: disposeBag)
    }

    private func pullResourceConsumedUsage(startDate: Date) {
        self.dataLoader.calendarApi?.getResourceSubscribeUsage(
            startTime: startDate,
            endTime: startDate.dayEnd(),
            rrule: "",
            key: "",
            originalTime: 0
        ).catchError { _ in return .empty() }
        .bind(to: self.rxOverUsageLimit)
        .disposed(by: disposeBag)
    }

    private func loadAttendees(userIds: [String]) {
        freeBusyView.showLoading()
        CalendarMonitorUtil.startTrackFreebusyViewAttendeeTime()
        attendeesGetter(userIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (attendees) in
                guard let `self` = self else { return }
                CalendarMonitorUtil.endTrackFreebusyViewAttendeeTime(calNum: attendees.count)
                self.freeBusyModel.changeAttendees(attendees: attendees)
                self.freeBusyView.hideLoading()
                self.freeBusyView.reloadData()
                self.freeBusyView.setHeaderFoorterViewInfo(
                    model: self.freeBusyModel.headerViewModel,
                    footerAttributedString: self.meetingRoom == nil ? self.freeBusyModel.footerAttrText : nil
                )
                self.trackProfileIfNeeded(attendees: attendees)
                if self.meetingRoom == nil {
                    SlaMonitor.traceSuccess(.FreeBusyInstance, action: "load_attendee", source: "profile")
                }
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.freeBusyView.showFailed(retry: {
                        self.loadAttendees(userIds: userIds)
                    })
                    if self.meetingRoom == nil {
                        SlaMonitor.traceFailure(.FreeBusyInstance, error: error, action: "load_attendee", source: "profile")
                    }
                }, onDisposed: { [weak self] in
                    if self == nil {
                        self?.freeBusyView.hideLoading()
                    }
            }).disposed(by: disposeBag)

        dataLoader.calendarApi?
            .checkCollaborationPermissionIgnoreError(uids: userIds)
            .observeOn(MainScheduler.instance)
            .subscribeForUI { [weak self] forbiddenIDs in
                guard let self = self else { return }
                self.freeBusyModel.usersRestrictedForNewEvent = forbiddenIDs
            }.disposed(by: disposeBag)
    }

    private func loadSunState() {
        freeBusyModel.sunStateService.loadData(citys: Array(freeBusyModel.timezoneMap.values), date: Int64(freeBusyModel.startTime.timeIntervalSince1970))
    }

    private func setupFreeBusyView(_ freeBusyView: FreeBusyView) {
        freeBusyView.delegate = self
        freeBusyView.addNewEvent = { [weak self] (startTime, endTime) in
            guard let `self` = self else { return }

            if self.meetingRoom != nil {
                let duration = self.freeBusyModel.earliestAvailableDuration()
                if !duration.isEmpty {
                    self.freeBusyView.hideInterval()

                    if duration != startTime..<endTime {
                        // toast需要在present新vc之后再弹出
                        let targetView = self.view.window ?? self.view!
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            UDToast.showTipsOnScreenCenter(with: BundleI18n.Calendar.Calendar_Rooms_EventTimeChanged, on: targetView)
                        }
                    }
                    let maxUsage = SettingService.shared().tenantSetting?.resourceSubscribeCondition.limitPerDay ?? 0
                    guard maxUsage == 0 || !self.rxOverUsageLimit.value else {
                        UDToast.showTips(with: BundleI18n.Calendar.Calendar_MeetingView_MaxReserveOnePersonPerDay(number: maxUsage), on: self.view)
                        return
                    }
                    self.createEvent(
                        withStartDate: duration.lowerBound,
                        endDate: duration.upperBound,
                        attendees: self.freeBusyModel.attendees
                    )
                    let fromQRCode = self.eventCreateBody.map { $0.meetingRoom.isEmpty } ?? true
                    CalendarTracer.shareInstance.calFullEditEvent(actionSource: fromQRCode ? .qrCode : .calProfile,
                                                                  editType: .new,
                                                                  mtgroomCount: 0,
                                                                  thirdPartyAttendeeCount: 0,
                                                                  groupCount: 0,
                                                                  userCount: 0,
                                                                  timeConfilct: .noConflict)
                } else {
                    guard let toast = self.freeBusyModel.meetingRoomConflictReason(with: startTime..<endTime) else { return }
                    UDToast.showFailure(with: toast, on: self.view)
                }
                return
            }

            let startDate = self.freeBusyModel.calibrationDate(date: startTime)
            let endDate = self.freeBusyModel.calibrationDate(date: endTime)
            let calendarID = self.freeBusyModel.currentUserCalendarId
            CalendarTracer.shareInstance.calProfileBlock()
            self.freeBusyView.hideInterval()
            self.freeBusyModel.changeInstanceMap(calendarInstanceMap: [:])

            let restrictedUserids = self.freeBusyModel.usersRestrictedForNewEvent
            let filteredAttendees = self.freeBusyModel.attendees.filter { !restrictedUserids.contains($0.id) }
            self.createEvent(
                withStartDate: startDate,
                endDate: endDate,
                attendees: filteredAttendees,
                calendarID: calendarID
            )
            var timeConflict: CalendarTracer.CalFullEditEventParam.TimeConfilct = .noConflict
            if !self.freeBusyModel.workHourConflictCalendarIds.isEmpty {
                timeConflict = .workTime
            } else if !self.freeBusyModel.getFreeBusyConflictcalendarIds().isEmpty {
                timeConflict = .eventConflict
            }

            let fromQRCode = self.eventCreateBody.map { $0.meetingRoom.isEmpty } ?? true

            CalendarTracer.shareInstance.calFullEditEvent(actionSource: fromQRCode ? .qrCode : .calProfile,
                                                          editType: .new,
                                                          mtgroomCount: 0,
                                                          thirdPartyAttendeeCount: 0,
                                                          groupCount: 0,
                                                          userCount: 0,
                                                          timeConfilct: timeConflict)

        }
        freeBusyView.setTimeZoneStr(timeZoneStr: freeBusyModel.getTzDisplayName())
    }

    private func layoutFreeBusyView(_ freeBusyView: FreeBusyView) {
        view.insertSubview(freeBusyView, at: 0)
        freeBusyView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            if meetingRoom == nil {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalToSuperview().inset(88)
            }
        }
    }

    private func createEvent(
        withStartDate startDate: Date,
        endDate: Date,
        attendees: [CalendarEventAttendeeEntity],
        calendarID: String? = nil
    ) {
        ReciableTracer.shared.recStartEditEvent()
        let editCoordinator = getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = startDate
            contextPointer.pointee.endDate = endDate
            contextPointer.pointee.attendeeSeeds = attendees
                .compactMap { $0.chatterId }
                .map { .user(chatterId: $0) }
            contextPointer.pointee.calendarID = calendarID

            let containsMeetingRoom = self.eventCreateBody?.attendees.contains(where: {
                if case .meWithMeetingRoom = $0 {
                    return true
                }
                return false
            })
            if containsMeetingRoom ?? false {
                contextPointer.pointee.attendeeSeeds.append(.user(chatterId: self.userResolver.userID))
                CalendarTracer.shared.meetingRoomFreeBusyActions(meetingRoomCalendarID: self.meetingRoom?.calendarID ?? "", action: .createNewEvent)
                contextPointer.pointee.calendarID = freeBusyModel.currentUserCalendarId
            }
            contextPointer.pointee.meetingRooms = self.eventCreateBody?.meetingRoom ?? []
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
            hud?.remove()
            hud = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OldFreeBusyController: EventEditCoordinatorDelegate {

    func coordinator(
        _ coordinator: EventEditCoordinator,
        didSaveEvent pbEvent: Rust.Event,
        span: Span,
        extraData: EventEditExtraData?
    ) {
        if meetingRoom != nil {
            let topMost = WindowTopMostFrom(vc: self)
            dismiss(animated: false) {
                if let vc = topMost.fromViewController {
                    self.createEventSucceedHandler(pbEvent, vc)
                }
            }
        } else {
            createEventSucceedHandler(pbEvent, self)
            needLazyLoad = true
        }

    }

}

extension OldFreeBusyController: FreeBusyViewDelegate {
    func removeHUD() {
        self.hud?.remove()
    }

    func showHUDLoading(with text: String) {
        self.hud?.showLoading(with: text, on: self.view, disableUserInteraction: false)
    }

    func showHUDFailure(with text: String) {
        RoundedHUD.showFailure(with: text, on: self.view)
    }

    func getCalendarIds(_ freeBusyView: FreeBusyView) -> [String] {
        return freeBusyModel.calendarIds
    }

    func freeBusyView(_ freeBusyView: FreeBusyView, date: Date) throws -> (InstanceMap, [String: [WorkingHoursTimeRange]], [String: Bool])? {
        CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()

        let date = freeBusyModel.calibrationDate(date: date)
        let calendarIds = freeBusyModel.calendarIds
        let cellWidth = self.cellWidth(with: TimeIndicator.indicatorWidth(is12HourStyle: freeBusyModel.is12HourStyle))
        let serverInstanceData = try dataLoader
            .syncLoadInstanceDate(calendarIds: calendarIds,
                                  date: date,
                                  panelSize: CGSize(width: cellWidth, height: 1200),
                                  timeZoneId: freeBusyModel.getTimeZone().identifier,
                                  disposeBag: disposeBag)
        // 会议室预定次数限制
        if meetingRoom != nil && SettingService.shared().tenantSetting?.resourceSubscribeCondition.limitPerDay != 0 {
            let calendar = TimeZoneUtil.getCalendar(timeZoneId: freeBusyModel.getTimeZone().identifier)
            let startTime = Int64(date.dayStart(calendar: calendar).timeIntervalSince1970)
            self.pullResourceConsumedUsage(startDate: date.dayStart())
        }
        CalendarMonitorUtil.endTrackFreebusyViewInProfileTime()
        freeBusyModel.changetimezoneMap(serverInstanceData.timezoneMap)
        self.loadSunState()
        freeBusyModel.changeWorkHourSettingMap(serverInstanceData.workHourMap)
        freeBusyModel.privateCalMap = serverInstanceData.privateCalMap
        DispatchQueue.main.async {
            self.updateHeaderViewInfo(freeBusyModel: self.freeBusyModel)
        }
        return (serverInstanceData.instanceMap,
                freeBusyModel.workingHoursTimeRangeMap(date: date),
                freeBusyModel.privateCalMap)
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
        self.freeBusyView.setTimeZoneStr(timeZoneStr: self.freeBusyModel.getTzDisplayName(uiDate: date))

        if let meetingRoom = meetingRoom {
            CalendarTracer.shared.meetingRoomFreeBusyActions(meetingRoomCalendarID: meetingRoom.calendarID, action: .changeDate)
        }

        debouncer.call {
            CalendarTracerV2.CalendarProfile.traceClick {
                $0.click("day_change").target("none")
            }
        }
    }

    func timeChanged(_ freeBusyView: FreeBusyView, startTime: Date, endTime: Date) {
        self.freeBusyModel.changeTime(startTime: startTime, endTime: endTime)
        updateHeaderViewInfo(freeBusyModel: freeBusyModel)
    }

    func intervalStateChanged(_ freeBusyView: FreeBusyView,
                              isHidden: Bool,
                              instanceMap: InstanceMap) {
        freeBusyModel.changeInstanceMap(calendarInstanceMap: instanceMap)
        updateHeaderViewInfo(freeBusyModel: freeBusyModel)
    }

    func updateHeaderViewInfo(freeBusyModel: FreeBusyControllerModel) {
        freeBusyView.setHeaderFoorterViewInfo(
            model: freeBusyModel.headerViewModel,
            footerAttributedString: meetingRoom == nil ? freeBusyModel.footerAttrText : nil
        )
    }

    func timeZoneClicked() {
        let previousTimeZone = self.freeBusyModel.getTimeZone()
        let selectTz = BehaviorRelay(value: previousTimeZone)
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectTz,
            anchorDate: self.freeBusyModel.startTime,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let self = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    self.freeBusyModel.updateTzInfo(timeZone: timeZone)
                    self.freeBusyView.setTimeZoneStr(timeZoneStr: self.freeBusyModel.getTzDisplayName())
                    self.freeBusyView.updateCurrentUiDate(
                        uiDate: self.freeBusyModel.getUiCurrentDate(),
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
        freeBusyModel.getUiCurrentDate()
    }

    func jumpToEventDetail(_ detailVC: UIViewController) {
        self.userResolver.navigator.push(detailVC, from: self)
    }
}

extension OldFreeBusyController {
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

// Trace
extension OldFreeBusyController {
    func trackProfileIfNeeded(attendees: [CalendarEventAttendeeEntity]) {
        guard let calendarId = attendees.first?.attendeeCalendarId,
              let otherUserId = userIds.first
        else { return }
        CalendarTracer.shared.calProfileTapped(userId: otherUserId, calendarId: calendarId)
    }

    func trackCalendarProfile() {
        // 从个人Profile页进入，否则为会议是忙闲
        if isFromProfile {
            CalendarTracerV2.CalendarProfile.traceView()
        }

    }
}
