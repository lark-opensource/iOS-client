//
//  OldGroupFreeBusyController.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/7/28.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import RoundedHUD
import EENavigator
import CalendarFoundation
import LarkContainer
import RustPB
import LarkGuide

final class OldGroupFreeBusyController: CalendarController, UserResolverWrapper {
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?

    private let disposeBag = DisposeBag()

    private var groupFreeBusyView: GroupFreeBusyView
    private var groupFreeBusyModel: GroupFreeBusyModel
    private let attendeesGetter: GetAttendeesByUserId
    private let dataLoader: ArrangementDataLoaderProtocol
    private let getCreateEventCoordinator: GetCreateEventCoordinator
    private var createEventSucceedHandler: CreateEventSucceedHandler
    private let calendarApi: CalendarRustAPI
    private let chatId: String
    private var selectedChatters: [String] = []
    private var orderedChatters: [String] = []
    private var needScrollToCurrentTime = true
    private let timeZoneService: TimeZoneService
    private let chatType: String
    private let createEventBody: CalendarCreateEventBody?
    private var hasTracedView: Bool = false

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         chatId: String,
         chatType: String,
         firstWeekday: DaysOfWeek,
         getNewEventMinute: @escaping (() -> Int),
         calendarApi: CalendarRustAPI,
         attendeesGetter: @escaping GetAttendeesByUserId,
         dataLoader: ArrangementDataLoaderProtocol,
         getCreateEventCoordinator: @escaping GetCreateEventCoordinator,
         createEventSucceedHandler: @escaping CreateEventSucceedHandler,
         getNormalDetailController: @escaping GetNormalDetailController,
         is12HourStyle: BehaviorRelay<Bool>,
         timeZoneService: TimeZoneService,
         createEventBody: CalendarCreateEventBody? = nil
    ) {

        CalendarMonitorUtil.startTrackFreebusyViewInChatTime()
        self.dataLoader = dataLoader
        self.chatType = chatType
        self.attendeesGetter = attendeesGetter
        self.calendarApi = calendarApi
        self.getCreateEventCoordinator = getCreateEventCoordinator
        self.createEventSucceedHandler = createEventSucceedHandler
        self.chatId = chatId
        self.createEventBody = createEventBody
        self.userResolver = userResolver
        let (startTime, endTime): (Date, Date)
        if let createEventBody = createEventBody {
            startTime = createEventBody.startDate
            if let endDate = createEventBody.endDate {
                endTime = endDate
            } else {
                endTime = (startTime + getNewEventMinute().minute)!
            }
        } else {
            startTime = Date()
            endTime = Date()
        }
        self.groupFreeBusyModel = GroupFreeBusyModel(sunStateService: SunStateService(userResolver: userResolver),
                                                     chatId: chatId,
                                                     startTime: startTime,
                                                     endTime: endTime,
                                                     firstWeekday: firstWeekday,
                                                     is12HourStyle: is12HourStyle.value)

        groupFreeBusyView = GroupFreeBusyView(content: groupFreeBusyModel,
                                              is12HourStyle: is12HourStyle.value,
                                              getNewEventMinute: getNewEventMinute)
        self.timeZoneService = timeZoneService
        super.init(nibName: nil, bundle: nil)
        groupFreeBusyView.delegate = self
        initNewEventHandle()
        isNavigationBarHidden = true

        is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (is12HourStyle) in
            self?.renewGroupFreeBusyView(is12HourStyle: is12HourStyle)
        }).disposed(by: disposeBag)

    }

    private func layoutViews() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(groupFreeBusyView)

        groupFreeBusyView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        groupFreeBusyView.setTimeZoneStr(timeZoneStr: groupFreeBusyModel.getTzDisplayName())
        groupFreeBusyView.updateCurrentUiDate(uiDate: groupFreeBusyModel.getUiCurrentDate())
    }

    private func renewGroupFreeBusyView(is12HourStyle: Bool) {
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewData()
        layoutViews()
        loadChatters()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        groupFreeBusyView.hideLoading(shouldRetry: false, failed: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        groupFreeBusyView.relayoutArrangementPanelAndHeader(newWidth: self.view.frame.width)
    }

    private func bindViewData() {
        groupFreeBusyModel.sunStateService.rxMapHasChanged
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.groupFreeBusyView.updateHeaderFooter(model: self.groupFreeBusyModel)
            }).disposed(by: disposeBag)
    }

    private func checkScrollToCurrentTime() {
        guard needScrollToCurrentTime else { return }
        defer { needScrollToCurrentTime = false }
        if let createEventBody = createEventBody {
            groupFreeBusyView.scrollToTime(time: groupFreeBusyModel.calibrationDateForUI(date: createEventBody.startDate), animated: false)
            DispatchQueue.main.async {
                self.groupFreeBusyView.showInterval()
            }
        } else {
            groupFreeBusyView.scrollToTime(time: groupFreeBusyModel.getUiCurrentDate(), animated: false)
        }
    }

    private func loadChatters() {
        groupFreeBusyView.showLoading(shouldRetry: true)
        CalendarMonitorUtil.startTrackFreebusyViewChatterTime()
        if let attendee = createEventBody?.attendees.first {
            // from createEventBody 特化逻辑
            let (chatId, selectedChatterIds): (String, [String]?)
            switch attendee {
            case .p2p(let aChatId, _), .group(let aChatId, _), .meetingGroup(let aChatId, _):
                chatId = aChatId
                selectedChatterIds = nil
            case .partialGroupMembers(let aChatId, let memberChatterIds), .partialMeetingGroupMembers(let aChatId, let memberChatterIds):
                chatId = aChatId
                selectedChatterIds = memberChatterIds
            case .meWithMeetingRoom:
                assertionFailure("群忙闲不应该处理此类型")
                chatId = ""
                selectedChatterIds = nil
                return
            }
            loadGroupMembers(with: chatId, selectedChatterIds: selectedChatterIds)
        } else {
            calendarApi.getChatFreeBusyChatters(chatId: chatId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] result in
                    guard let `self` = self else { return }
                    CalendarMonitorUtil.endTrackFreebusyViewChatterTime()
                    CalendarMonitorUtil.startTrackFreebusyViewAttendeeTime()
                    self.selectedChatters = result.selectedChatters
                    self.orderedChatters = result.orderedChatters
                    self.loadAttendees(userIds: result.selectedChatters)
                    }, onError: {[weak self] (_) in
                        self?.groupFreeBusyView.hideLoading(shouldRetry: true, failed: true)
                    }, onDisposed: { [weak self] in
                        self?.checkScrollToCurrentTime()
                    }).disposed(by: disposeBag)
        }
    }

    private func loadGroupMembers(with chatId: String, selectedChatterIds: [String]?) {
        calendarApi.pullGroupChatterCalendarIDs(chatIDs: [chatId])
            .collectSlaInfo(.FreeBusyInstance, action: "load_group_attendee", source: "chat")
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (response: Server.PullGroupChatterCalendarIDsResponse) in
                    guard let self = self else { return }
                    var attendeeCalendarIds = Array(response.chatterCalendarIDMap.values)
                    if let selectedIds = selectedChatterIds {
                        self.selectedChatters = selectedIds
                        attendeeCalendarIds = attendeeCalendarIds.filter {
                            return selectedIds.contains($0)
                        }
                    } else {
                        self.selectedChatters = attendeeCalendarIds
                    }
                    self.orderedChatters = self.selectedChatters
                    self.loadAttendees(userIds: self.selectedChatters)
                },
                onError: { [weak self] _ in
                    self?.groupFreeBusyView.hideLoading(shouldRetry: true, failed: true)
                },
                onDisposed: { [weak self] in
                    self?.checkScrollToCurrentTime()
                }
            )

    }

    private func loadAttendees(userIds: [String]) {
        attendeesGetter(userIds)
            .collectSlaInfo(.FreeBusyInstance, action: "load_attendee", source: "chat")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (attendees) in
                guard let `self` = self else { return }
                CalendarMonitorUtil.endTrackFreebusyViewAttendeeTime(calNum: attendees.count)

                self.groupFreeBusyModel.changeAttendees(attendees: attendees)
                self.groupFreeBusyView.hideLoading(shouldRetry: true, failed: false)
                self.groupFreeBusyView.setHeaderViewInfo(model: self.groupFreeBusyModel.headerViewModel)
                self.groupFreeBusyView.updateHeaderFooter(model: self.groupFreeBusyModel)
                CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()
                self.loadData(is12HourStyle: self.groupFreeBusyModel.is12HourStyle)
                }, onError: { [weak self] (_) in
                    self?.groupFreeBusyView.hideLoading(shouldRetry: true, failed: true)
                }, onDisposed: { }).disposed(by: disposeBag)

        calendarApi.checkCollaborationPermissionIgnoreError(uids: userIds)
            .observeOn(MainScheduler.instance)
            .subscribeForUI { [weak self] forbiddenIDs in
                guard let self = self else { return }
                self.groupFreeBusyModel.usersRestrictedForNewEvent = forbiddenIDs
            }.disposed(by: disposeBag)
    }

    private func loadData(is12HourStyle: Bool, needShowLoading: Bool = true) {
        loadData(calendarIds: groupFreeBusyModel.calendarIds,
                 cellWidth: groupFreeBusyModel.cellWidth(with:
                                                            TimeIndicator.indicatorWidth(is12HourStyle: is12HourStyle), totalWidth: view.bounds.width),
                 startTime: groupFreeBusyModel.startTime,
                 endTime: groupFreeBusyModel.endTime,
                 needShowLoading: needShowLoading)
    }

    private func loadData(calendarIds: [String],
                          cellWidth: CGFloat,
                          startTime: Date,
                          endTime: Date,
                          needShowLoading: Bool = true) {
        if needShowLoading {
            self.groupFreeBusyView.showLoading(shouldRetry: false)
        }
        self.groupFreeBusyView.cleanInstance(calendarIds: calendarIds,
                                             startTime: groupFreeBusyModel.calibrationDateForUI(date: startTime),
                                             endTime: groupFreeBusyModel.calibrationDateForUI(date: endTime))
        dataLoader.loadInstanceData(calendarIds: calendarIds,
                                    date: startTime,
                                    panelSize: CGSize(width: cellWidth, height: 1200),
                                    timeZoneId: groupFreeBusyModel.getTimeZone().identifier)
            .collectSlaInfo(.FreeBusyInstance, action: "load_instance", source: "chat")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] serverInstanceData in
                guard let self = self else { return }
                if needShowLoading {
                    self.groupFreeBusyView.hideLoading(shouldRetry: false, failed: false)
                }
                self.groupFreeBusyModel.changeServerData(serverInstanceData)
                self.loadSunState()
                self.groupFreeBusyView.reloadServerData(model: self.groupFreeBusyModel)
                self.viewWillLayoutSubviews()

                CalendarMonitorUtil.endTrackFreebusyViewInChatTime(calNum: self.groupFreeBusyModel.attendees.count)
                self.traceViewOnlyOnce(with: serverInstanceData)
                DispatchQueue.main.async {
                    if self.viewIfLoaded?.window != nil,
                       CalConfig.isMultiTimeZone,
                       self.groupFreeBusyModel.headerViewModel.shouldShowTimeString,
                       let headerCell = self.groupFreeBusyView.headerFirstCell(),
                       let newGuideManager = self.newGuideManager {
                        GuideService.checkShowTzInfoGuide(controller: self, newGuideManager: newGuideManager, referView: headerCell)
                    }
                }
                }, onError: { [weak self] (_) in
                    guard let self = self else { return }
                    self.groupFreeBusyModel.changeServerData(ServerInstanceData())
                    self.groupFreeBusyView.reloadServerData(model: self.groupFreeBusyModel)
                    if needShowLoading {
                        self.groupFreeBusyView.hideLoading(shouldRetry: false, failed: true)
                    }
                    self.viewWillLayoutSubviews()
                }, onDisposed: { [weak self] in
                    if self == nil && needShowLoading {
                        self?.groupFreeBusyView.hideLoading(shouldRetry: false, failed: false)
                    }
            }).disposed(by: disposeBag)
    }

    private func loadSunState() {
        groupFreeBusyModel.sunStateService.loadData(citys: Array(groupFreeBusyModel.timezoneMap.values), date: Int64(groupFreeBusyModel.startTime.timeIntervalSince1970))
    }

    private func initNewEventHandle() {
        groupFreeBusyView.addNewEvent = { [weak self] (_, _) in
            guard let `self` = self else { return }
            let attedees = self.groupFreeBusyModel.attendees.map { attendee -> CalendarEventAttendeeEntity in
                var newAttendee = attendee
                return newAttendee
            }
            var timeConflict: CalendarTracer.CalFullEditEventParam.TimeConfilct = .noConflict
            if !self.groupFreeBusyModel.workHourConflictCalendarIds.isEmpty {
                timeConflict = .workTime
            } else if self.groupFreeBusyModel.workHourConflictCalendarIds.isEmpty {
                timeConflict = .eventConflict
            }
            let actionSource: CalendarTracer.CalFullEditEventParam.ActionSource = self.chatType == "group" ? .findTimeGroup : .findTimeSingle
            CalendarTracer.shareInstance.calFullEditEvent(actionSource: actionSource,
                                                          editType: .new,
                                                          mtgroomCount: 0,
                                                          thirdPartyAttendeeCount: 0,
                                                          groupCount: 0,
                                                          userCount: 0,
                                                          timeConfilct: timeConflict)
            let restrictedUserids = self.groupFreeBusyModel.usersRestrictedForNewEvent
            let filteredAttendees = attedees.filter { !restrictedUserids.contains($0.id) }

            self.createEvent(
                withStartDate: self.groupFreeBusyModel.startTime,
                endDate: self.groupFreeBusyModel.endTime,
                meetingRooms: self.createEventBody?.meetingRoom ?? [],
                attendees: filteredAttendees
            )
        }
    }

    private func updateGroupChatters() {
        guard createEventBody == nil else { return }
        calendarApi.setChatFreeBusyChatters(chatId: chatId,
                                                        orderedChatters: orderedChatters,
                                                        selectedChatters: selectedChatters)
            .subscribe(onError: { (_) in }).disposed(by: disposeBag)
    }

    private func createEvent(
        withStartDate startDate: Date,
        endDate: Date,
        meetingRooms: [(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String)],
        attendees: [CalendarEventAttendeeEntity]
    ) {
        ReciableTracer.shared.recStartEditEvent()
        let attendeeSeeds: [EventAttendeeSeed]
        if let inputAttendee = createEventBody?.attendees.first,
           case .group(let chatId, let memberCount) = inputAttendee, memberCount == attendees.count {
            attendeeSeeds = [.group(chatId: chatId)]
        } else {
            attendeeSeeds = attendees.compactMap {
                guard let chatterId = $0.chatterId else { return nil }
                return .user(chatterId: chatterId)
            }
        }
        let editCoordinator = getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = startDate
            contextPointer.pointee.endDate = endDate
            contextPointer.pointee.attendeeSeeds = attendeeSeeds
            contextPointer.pointee.chatIdForSharing = self.chatId
            contextPointer.pointee.meetingRooms = meetingRooms
        }
        editCoordinator.delegate = self
        let scheduleConflictNum = (self.groupFreeBusyModel.freeBusyInfo?.busyAttendees.count ?? 0) +
        (self.groupFreeBusyModel.freeBusyInfo?.maybeFreeAttendees.count ?? 0)
        let attendeeNum = attendees.count
        editCoordinator.actionSource = self.chatType == "group" ? .chat(scheduleConflictNum: scheduleConflictNum, attendeeNum: attendeeNum) : .chatter
        editCoordinator.start(from: self)
        self.groupFreeBusyView.hideInterval()
            CalendarTracerV2.CalendarChat
                .traceClick {
                    $0.chat_id = self.chatId
                    $0.click("full_create_event").target("cal_event_full_create_view")
                }
    }

    private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OldGroupFreeBusyController: EventEditCoordinatorDelegate {

    func coordinator(
        _ coordinator: EventEditCoordinator,
        didSaveEvent pbEvent: Rust.Event,
        span: Span,
        extraData: EventEditExtraData?
    ) {
        let topMost = WindowTopMostFrom(vc: self)
        let handler = createEventSucceedHandler
        dismiss(animated: false) {
            if let from = topMost.fromViewController {
                handler(pbEvent, from)
            }
        }
    }

}

extension OldGroupFreeBusyController: GroupFreeBusyViewDelegate {
    func getTimeZone() -> TimeZone {
        return TimeZone(identifier: self.groupFreeBusyModel.getTimeZone().identifier) ?? TimeZone.current
    }

    func arrangementViewClosed(_ groupFreeBusyView: GroupFreeBusyView) {
        dismissSelf()
    }

    func timeChanged(_ groupFreeBusyView: GroupFreeBusyView, startTime: Date, endTime: Date) {
        groupFreeBusyModel.changeTimeRange(startTime: startTime, endTime: endTime)
        groupFreeBusyView.updateHeaderFooter(model: groupFreeBusyModel)
    }

    func dateChanged(_ groupFreeBusyView: GroupFreeBusyView, date: Date) {
        groupFreeBusyView.hideInterval()
        groupFreeBusyModel.changeTimeRange(by: date)
        groupFreeBusyView.updateHeaderFooter(model: groupFreeBusyModel)
        loadData(is12HourStyle: groupFreeBusyModel.is12HourStyle)
        groupFreeBusyView.setTimeZoneStr(timeZoneStr: groupFreeBusyModel.getTzDisplayName())
        CalendarTracerV2.CalendarChat.traceClick {
            $0.click("day_change").target("none")
            $0.chat_id = self.chatId
        }
    }

    func moveAttendeeToFirst(_ groupFreeBusyView: GroupFreeBusyView, indexPath: IndexPath) {
        groupFreeBusyModel.moveAttendeeToFirst(indexPath: indexPath)
        if indexPath.row < selectedChatters.count {
            let chatter = selectedChatters[indexPath.row]
            selectedChatters.remove(at: indexPath.row)
            selectedChatters.insert(chatter, at: 0)
            if let index = orderedChatters.firstIndex(of: chatter) {
                orderedChatters.remove(at: index)
            }
            orderedChatters.insert(chatter, at: 0)
            updateGroupChatters()
        }

        CalendarTracerV2.CalendarChat.traceClick {
                $0.click("change_list").target("none")
                $0.chat_id = self.chatId
        }
    }

    func retry(_ groupFreeBusyView: GroupFreeBusyView) {
        loadChatters()
    }

    func chooseButtonClicked() {
        calendarDependency?.jumpToFreeBusyChatterController(from: self,
                                                           chatId: chatId,
                                                           selectedChatters: selectedChatters) { [weak self] chatters in
            CalendarTracer.shareInstance.groupFreeBusyChooseMemberCount(memberCount: chatters.count)
            guard let self = self else { return }
            if self.createEventBody != nil {
                self.selectedChatters = chatters
                self.orderedChatters = (self.orderedChatters.filter { chatters.contains($0) } + chatters).lf_unique()
                self.loadAttendees(userIds: self.selectedChatters)
            } else {
                self.calendarApi.sortChatFreeBusyChatters(chatId: self.chatId, chatters: chatters)
                    .collectSlaInfo(.FreeBusyInstance, action: "load_sorted_attendee", source: "chat")
                    .subscribe(onNext: { [weak self] result in
                        guard let `self` = self else { return }

                        self.orderedChatters = self.orderedChatters.filter { result.contains($0) }
                        let selectedChatters = self.orderedChatters + result.filter { !self.orderedChatters.contains($0) }
                        if !self.selectedChatters.elementsEqual(selectedChatters) {
                            self.selectedChatters = selectedChatters
                            self.loadAttendees(userIds: self.selectedChatters)
                            self.updateGroupChatters()
                        }
                        }, onError: {[weak self] (error) in
                            self?.groupFreeBusyView.hideLoading(shouldRetry: true, failed: true)
                        }, onDisposed: { }).disposed(by: self.disposeBag)
            }
            if self.selectedChatters.count != chatters.count {
                CalendarTracerV2.CalendarChat.traceClick {
                    $0.click("change_member").target("none")
                    $0.chat_id = self.chatId
                }
            }
        }
    }

    func timeZoneClicked() {
        goSelectTimeZoneVC()
    }
}

extension OldGroupFreeBusyController {

    func goSelectTimeZoneVC() {
        let previousTimeZone = self.groupFreeBusyModel.getTimeZone()
        let selectTz = BehaviorRelay(value: previousTimeZone)
        let popupVC = getPopupTimeZoneSelectViewController(
            with: timeZoneService,
            selectedTimeZone: selectTz,
            anchorDate: self.groupFreeBusyModel.startTime,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let self = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    self.groupFreeBusyModel.updateTzInfo(chatId: self.chatId, timeZone: timeZone)
                    self.groupFreeBusyView.setTimeZoneStr(timeZoneStr: self.groupFreeBusyModel.getTzDisplayName())
                    self.groupFreeBusyView.updateCurrentUiDate(
                        uiDate: self.groupFreeBusyModel.getUiCurrentDate(),
                        with: TimeZone(identifier: timeZone.identifier) ?? .current
                    )
                    self.loadData(is12HourStyle: self.groupFreeBusyModel.is12HourStyle)
                }

            }
        )
        self.present(popupVC, animated: true, completion: nil)

        CalendarTracer.shareInstance.calClickTimeZoneEntry(from: .chat)
    }

    private func traceViewOnlyOnce(with data: ServerInstanceData) {
        if !hasTracedView {
            CalendarTracerV2.CalendarChat.traceView {
                $0.has_event = (!data.instanceMap.values.flatMap { $0 }.isEmpty).description
                $0.chat_id = self.chatId
            }
            hasTracedView = true
        }
    }

}
