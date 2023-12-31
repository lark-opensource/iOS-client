//
//  MeetingRoomFreeBusyController.swift
//  Calendar
//
//  Created by pluto on 2023/9/6.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import EENavigator
import UniverseDesignToast
import LKCommonsLogging

final class MeetingRoomFreeBusyController: UIViewController, UserResolverWrapper {
    let logger = Logger.log(MeetingRoomFreeBusyController.self, category: "Calendar.MeetingRoomFreeBusyController")

    @ScopedInjectedLazy var calendarInterface: CalendarInterface?
    @ScopedInjectedLazy var pushService: RustPushService?

    let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    
    private lazy var freeBusyView: FreeBusyView = {
       let view = FreeBusyView(startDate: viewModel.startDate,
                               firstWeekday: viewModel.firstWeekday,
                               getNewEventMinute: viewModel.defaultDurationGetter,
                               is12HourStyle: viewModel.rxIs12HourStyle.value,
                               showHeaderView: false)
        return view
    }()
    
    private var viewBoundsWidth: CGFloat = 0
    
    let viewModel: MeetingRoomFreeBusyViewModel
    
    init(viewModel: MeetingRoomFreeBusyViewModel) {
        self.viewModel = viewModel
        self.userResolver = viewModel.userResolver
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        self.view.backgroundColor = UIColor.ud.bgBody
        regist12HoursChange()
        layoutFreeBusyView(freeBusyView)
    }
    
    private func regist12HoursChange() {
        viewModel.rxIs12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            guard let `self` = self else { return }
            self.viewModel.freeBusyModel.changeIs12HourStyle(is12HourStyle: is12HourStyle)
            self.renewFreeBusyView(freeBusyModel: self.viewModel.freeBusyModel)
        }).disposed(by: disposeBag)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewData()
        setupFreeBusyView(freeBusyView)
        viewModel.loadAttendee()
        if let meetingRoom = viewModel.meetingRoom {
            addMeetingRoomInfoView(meetingRoom: meetingRoom)
            observeInstanceChanged(meetingRoom: meetingRoom)
        }
    }
    

    private func bindViewData() {
        viewModel.freeBusyModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateHeaderViewInfo(freeBusyModel: self.viewModel.freeBusyModel)
            }).disposed(by: disposeBag)
    }
    
    private func layoutFreeBusyView(_ freeBusyView: FreeBusyView) {
        view.insertSubview(freeBusyView, at: 0)
        freeBusyView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(88)
        }
    }
    
    private func setupFreeBusyView(_ freeBusyView: FreeBusyView) {
        freeBusyView.delegate = self
        freeBusyView.arrangePanelTitle = BundleI18n.Calendar.Calendar_Rooms_ReserveRoms
        freeBusyView.meetingRoomMaxDuration = viewModel.meetingRoom?.schemaExtraData.cd.resourceStrategy.map { TimeInterval($0.singleMaxDuration) }
        freeBusyView.addNewEvent = { [weak self] (startTime, endTime) in
            guard let `self` = self else { return }
            let duration = self.viewModel.freeBusyModel.earliestAvailableDuration()
            if !duration.isEmpty {
                self.freeBusyView.hideInterval()
                
                if duration != startTime..<endTime {
                    // toast需要在present新vc之后再弹出
                    if let targetView = self.view.window ?? self.view {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            UDToast.showTipsOnScreenCenter(with: BundleI18n.Calendar.Calendar_Rooms_EventTimeChanged, on: targetView)
                        }
                    }
                }
                let maxUsage = SettingService.shared().tenantSetting?.resourceSubscribeCondition.limitPerDay ?? 0
                guard maxUsage == 0 || !self.viewModel.rxOverUsageLimit.value else {
                    UDToast.showTips(with: BundleI18n.Calendar.Calendar_MeetingView_MaxReserveOnePersonPerDay(number: maxUsage), on: self.view)
                    return
                }
                self.createEvent(
                    withStartDate: duration.lowerBound,
                    endDate: duration.upperBound,
                    attendees: self.viewModel.freeBusyModel.attendees
                )
                
                CalendarTracer.shareInstance.calFullEditEvent(actionSource: .qrCode ,
                                                              editType: .new,
                                                              mtgroomCount: 0,
                                                              thirdPartyAttendeeCount: 0,
                                                              groupCount: 0,
                                                              userCount: 0,
                                                              timeConfilct: .noConflict)
            } else {
                guard let toast = self.viewModel.freeBusyModel.meetingRoomConflictReason(with: startTime..<endTime) else { return }
                UDToast.showFailure(with: toast, on: self.view)
            }
            return
        }
        
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
        freeBusyView.setTimeZoneStr(timeZoneStr: viewModel.freeBusyModel.getTzDisplayName())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        SettingService.shared().stateManager.activate()
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

    private func cellWidth(with rullerWidth: CGFloat) -> CGFloat {
        return (viewBoundsWidth - rullerWidth) / CGFloat(2)
    }

    private func renewFreeBusyView(freeBusyModel: FreeBusyControllerModel) {
        freeBusyView.removeFromSuperview()
        freeBusyView = FreeBusyView(startDate: viewModel.startDate,
                                    firstWeekday: viewModel.firstWeekday,
                                    getNewEventMinute: viewModel.defaultDurationGetter,
                                    is12HourStyle: viewModel.rxIs12HourStyle.value,
                                    showHeaderView: false)
        layoutFreeBusyView(freeBusyView)
        setupFreeBusyView(freeBusyView)
        viewModel.loadAttendee()
    }

    private func addMeetingRoomInfoView(meetingRoom: Rust.MeetingRoom) {
        let context = DetailOnlyContext(calendarID: meetingRoom.calendarID)
        let meetingRoomDetailVC = MeetingRoomDetailViewController(viewModel: MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver), userResolver: self.userResolver)
        addChild(meetingRoomDetailVC)
        view.addSubview(meetingRoomDetailVC.view)

        meetingRoomDetailVC.view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.snp.bottom).offset(-88)
            make.height.equalToSuperview().dividedBy(2)
        }
        meetingRoomDetailVC.setUpConfigFromFreebusy(height: self.view.bounds.height)
        meetingRoomDetailVC.didMove(toParent: self)
    }
    
    private func observeInstanceChanged(meetingRoom: Rust.MeetingRoom) {
        pushService?.rxMeetingRoomInstanceChanged
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] ids in
                guard let self = self else { return }
                if ids.contains(meetingRoom.calendarID) {
                    self.viewModel.loadAttendee()
                }
            })
            .disposed(by: disposeBag)
    }

    private func createEvent(withStartDate startDate: Date, endDate: Date, attendees: [CalendarEventAttendeeEntity]) {
        ReciableTracer.shared.recStartEditEvent()
        let editCoordinator = viewModel.getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = startDate
            contextPointer.pointee.endDate = endDate
            contextPointer.pointee.attendeeSeeds = attendees
                .compactMap { $0.chatterId }
                .map { .user(chatterId: $0) }
            contextPointer.pointee.attendeeSeeds.append(.user(chatterId: self.userResolver.userID))
            CalendarTracer.shared.meetingRoomFreeBusyActions(meetingRoomCalendarID: self.viewModel.meetingRoom?.calendarID ?? "", action: .createNewEvent)
            contextPointer.pointee.meetingRooms = self.viewModel.createEventBody?.meetingRoom ?? []
            contextPointer.pointee.calendarID = self.viewModel.currentUserCalendarId
        }
        editCoordinator.delegate = self
        editCoordinator.actionSource = .qrCode
        editCoordinator.start(from: self)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            UDToast.removeToast(on: self.view)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHeaderViewInfo(freeBusyModel: FreeBusyControllerModel) {
        freeBusyView.setHeaderFoorterViewInfo(model: freeBusyModel.headerViewModel, footerAttributedString: nil)
    }
}

extension MeetingRoomFreeBusyController: EventEditCoordinatorDelegate {

    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span, extraData: EventEditExtraData?) {
        let topMost = WindowTopMostFrom(vc: self)
        dismiss(animated: false) {
            if let vc = topMost.fromViewController {
                self.viewModel.createEventSucceedHandler(pbEvent, vc)
            }
        }
    }

}

extension MeetingRoomFreeBusyController: FreeBusyViewDelegate {
    func removeHUD() {
        UDToast.removeToast(on: self.view)
    }

    func showHUDLoading(with text: String) {
        DispatchQueue.main.async {
            UDToast.showLoading(with: text, on: self.view)
        }
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
    }

    func dateChanged(_ freeBusyView: FreeBusyView, pageChanged date: Date) {
        self.freeBusyView.setTimeZoneStr(timeZoneStr: self.viewModel.freeBusyModel.getTzDisplayName(uiDate: date))

        if let meetingRoom = viewModel.meetingRoom {
            CalendarTracer.shared.meetingRoomFreeBusyActions(meetingRoomCalendarID: meetingRoom.calendarID, action: .changeDate)
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
    }

    func getUiCurrentDate() -> Date {
        viewModel.freeBusyModel.getUiCurrentDate()
    }

    func jumpToEventDetail(_ detailVC: UIViewController) {
        self.userResolver.navigator.push(detailVC, from: self)
    }
}

//extension MeetingRoomFreeBusyController {
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        if let pan = gestureRecognizer as? UIPanGestureRecognizer,
//           let view = pan.view {
//            if view.transform.isIdentity { return true }
//            let currentLocationY = pan.location(in: view).y
//            let translationY = pan.translation(in: view).y
//            return currentLocationY - translationY < 50
//        }
//        return true
//    }
//}

extension MeetingRoomFreeBusyController: MeetingRoomFreeBusyViewModelDelegate {
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

}
