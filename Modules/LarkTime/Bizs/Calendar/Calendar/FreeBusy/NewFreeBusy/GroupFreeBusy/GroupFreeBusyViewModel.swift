//
//  GroupFreeBusyViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import RxRelay
import RxSwift
import Foundation
import LarkContainer
import CalendarFoundation
import LKCommonsLogging

protocol GroupFreeBusyViewModelDelegate: AnyObject {
    func hideLoading(shouldRetry: Bool, failed: Bool)
    func showLoading(shouldRetry: Bool)
    func updateHeaderFooter()
    func checkScrollToCurrentTime()
    func getBoundsWidth() -> CGFloat
    func reloadViewWithInstanceData()
    func showGuide()
    func cleanInstance(calendarIds: [String], startTime: Date, endTime: Date)
}

class GroupFreeBusyViewModel: FreeBusyDetailViewModel {
    let logger = Logger.log(GroupFreeBusyViewModel.self, category: "Calendar.GroupFreeBusyViewModel")
    lazy var groupFreeBusyModel: GroupFreeBusyModel = configGroupFreeBusyModel()

    weak var delegate: GroupFreeBusyViewModelDelegate?
    
    let chatId: String
    let chatType: String
    let createEventBody: CalendarCreateEventBody?
    let createEventSucceedHandler: CreateEventSucceedHandler
    private var hasTracedView: Bool = false
    
    var selectedChatters: [String] = []
    var orderedChatters: [String] = []
    
    init(userResolver: UserResolver,
         chatId: String,
         chatType: String,
         createEventBody: CalendarCreateEventBody? = nil,
         createEventSucceedHandler: @escaping CreateEventSucceedHandler) {
        self.chatId = chatId
        self.chatType = chatType
        self.createEventBody = createEventBody
        self.createEventSucceedHandler = createEventSucceedHandler
        super.init(userResolver: userResolver)

        loadChatFreeBusyChattersAndAttendee()
        CalendarMonitorUtil.startTrackFreebusyViewChatterTime()
    }
    
    private func cleanInstance() {
        DispatchQueue.main.async {
            self.delegate?.cleanInstance(calendarIds: self.groupFreeBusyModel.calendarIds,
                                         startTime: self.groupFreeBusyModel.calibrationDateForUI(date: self.groupFreeBusyModel.startTime),
                                         endTime: self.groupFreeBusyModel.calibrationDateForUI(date: self.groupFreeBusyModel.endTime))
        }
    }
    
    func loadChatFreeBusyChattersAndAttendee() {
        guard let calendarApi = calendarApi else {
            logger.error("[GroupFreeBusyViewModel] failed get calendarApi")
            return
        }
        DispatchQueue.main.async {
            self.delegate?.showLoading(shouldRetry: true)
        }
        
        calendarApi.getChatFreeBusyChatters(chatId: chatId)
            .flatMap { [weak self] result -> Observable<[PBAttendee]> in
                guard let `self` = self else { return .just([]) }
                self.selectedChatters = result.selectedChatters
                self.orderedChatters = result.orderedChatters
                self.logger.info("[GroupFreeBusyViewModel] getChatFreeBusyChatters success with:\(result.selectedChatters) & \(result.orderedChatters)")
                self.checkCollaborationPermissionIgnoreIDs(userIds: result.selectedChatters)
                CalendarMonitorUtil.endTrackFreebusyViewChatterTime()
                CalendarMonitorUtil.startTrackFreebusyViewAttendeeTime()
                return calendarApi.getAttendees(uids: result.selectedChatters)
                    .collectSlaInfo(.FreeBusyInstance, action: "load_attendee", source: "chat")
            }.subscribe(onNext: { [weak self] (attendees) in
                guard let `self` = self else { return }
                self.logger.info("[GroupFreeBusyViewModel] getAttendees success with:\(attendees)")
                self.groupFreeBusyModel.changeAttendees(attendees: attendees)
                CalendarMonitorUtil.endTrackFreebusyViewAttendeeTime(calNum: attendees.count)
                CalendarMonitorUtil.startTrackFreebusyViewInstanceTime()

                DispatchQueue.main.async {
                    self.delegate?.updateHeaderFooter()
                }
                self.loadInstanceData()
            }, onError: {[weak self] (error) in
                self?.logger.error("[GroupFreeBusyViewModel] loadChatFreeBusyChattersAndAttendee error with: \(error)")
                DispatchQueue.main.async {
                    self?.delegate?.hideLoading(shouldRetry: true, failed: true)
                }

            }, onDisposed: { [weak self] in
                DispatchQueue.main.async {
                    self?.delegate?.checkScrollToCurrentTime()
                }
            }).disposed(by: disposeBag)
    }
    
    func loadInstanceData() {
        DispatchQueue.main.async {
            self.delegate?.showLoading(shouldRetry: false)
        }
        cleanInstance()
        let viewBoundsWidth: CGFloat = self.delegate?.getBoundsWidth() ?? 0
        logger.info("[GroupFreeBusyViewModel] viewBoundsWidth :\(viewBoundsWidth)")
        let cellWidth: CGFloat = groupFreeBusyModel.cellWidth(with: TimeIndicator.indicatorWidth(is12HourStyle: rxIs12HourStyle.value), totalWidth: viewBoundsWidth)

        loadInstanceData(calendarIds: groupFreeBusyModel.calendarIds,
                         date: groupFreeBusyModel.startTime,
                         panelSize: CGSize(width: cellWidth, height: 1200),
                         timeZoneId: groupFreeBusyModel.getTimeZone().identifier)
        .collectSlaInfo(.FreeBusyInstance, action: "load_instance", source: "chat")
        .subscribe(onNext: { [weak self] serverInstanceData in
            guard let self = self else { return }

            self.logger.info( "[GroupFreeBusyViewModel] loadInstanceData success with: \(serverInstanceData)")
            CalendarMonitorUtil.endTrackFreebusyViewInChatTime(calNum: self.groupFreeBusyModel.attendees.count)

            self.groupFreeBusyModel.changeServerData(serverInstanceData)
            self.loadSunState()
            self.traceViewOnlyOnce(with: serverInstanceData)
            
            DispatchQueue.main.async {
                self.delegate?.hideLoading(shouldRetry: false, failed: false)
                self.delegate?.reloadViewWithInstanceData()
                self.delegate?.showGuide()
            }
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            self.logger.error("loadInstanceData failed with: \(error)")
            self.groupFreeBusyModel.changeServerData(ServerInstanceData())
            DispatchQueue.main.async {
                self.delegate?.hideLoading(shouldRetry: false, failed: true)
                self.delegate?.reloadViewWithInstanceData()
            }
        }, onDisposed: { [weak self] in
            DispatchQueue.main.async {
                self?.delegate?.hideLoading(shouldRetry: false, failed: false)
            }
        }).disposed(by: disposeBag)
    }
    
    func loadAttendeeData(userIds: [String]) {
        guard let calendarApi = calendarApi else {
            logger.error("[GroupFreeBusyViewModel] failed get calendarApi")
            return
        }
        calendarApi.getAttendees(uids: userIds)
            .collectSlaInfo(.FreeBusyInstance, action: "load_attendee", source: "chat")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (attendees) in
                guard let `self` = self else { return }
                self.logger.info("[GroupFreeBusyViewModel] getAttendees success with: \(attendees)")
                self.groupFreeBusyModel.changeAttendees(attendees: attendees)
                self.groupFreeBusyModel.changeAttendees(attendees: attendees)
                
                DispatchQueue.main.async {
                    self.delegate?.hideLoading(shouldRetry: true, failed: false)
                    self.delegate?.updateHeaderFooter()
                }
                self.loadInstanceData()
            }, onError: { [weak self] (error) in
                self?.logger.error("[GroupFreeBusyViewModel] getAttendees error with: \(error)")
                DispatchQueue.main.async {
                    self?.delegate?.hideLoading(shouldRetry: true, failed: true)
                }
            }).disposed(by: disposeBag)
    }
    
    func sortFreeBusyChatters(chatters: [String]) {
        calendarApi?.sortChatFreeBusyChatters(chatId: chatId, chatters: chatters)
            .collectSlaInfo(.FreeBusyInstance, action: "load_sorted_attendee", source: "chat")
            .subscribe(onNext: { [weak self] result in
                guard let `self` = self else { return }
                self.orderedChatters = self.orderedChatters.filter { result.contains($0) }
                let selectedChatters = self.orderedChatters + result.filter { !self.orderedChatters.contains($0) }
                if !self.selectedChatters.elementsEqual(selectedChatters) {
                    self.selectedChatters = selectedChatters
                    self.loadAttendeeData(userIds: selectedChatters)
                    self.updateGroupChatter()
                }
            }, onError: {[weak self] (error) in
                self?.logger.error("[GroupFreeBusyViewModel] sortChatFreeBusyChatters error with: \(error)")
                DispatchQueue.main.async {
                    self?.delegate?.hideLoading(shouldRetry: true, failed: true)
                }
            }).disposed(by: self.disposeBag)
    }
    
    func updateGroupChatter() {
        guard createEventBody == nil else { return }
        calendarApi?.setChatFreeBusyChatters(chatId: chatId, orderedChatters: orderedChatters, selectedChatters: selectedChatters)
            .subscribe(onError: {[weak self] (error) in
                self?.logger.error("setChatFreeBusyChatters failed with: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    func loadSunState() {
        groupFreeBusyModel.sunStateService.loadData(citys: Array(groupFreeBusyModel.timezoneMap.values), date: Int64(groupFreeBusyModel.startTime.timeIntervalSince1970))
    }
    
    private func checkCollaborationPermissionIgnoreIDs(userIds: [String]) {
        calendarApi?.checkCollaborationPermissionIgnoreError(uids: userIds)
            .subscribe ( onNext: { [weak self] forbiddenIDs in
                guard let self = self else { return }
                self.logger.info("[GroupFreeBusyViewModel] checkCollaborationPermissionIgnoreError with: \(forbiddenIDs)")
                self.groupFreeBusyModel.usersRestrictedForNewEvent = forbiddenIDs
            }, onError: { [weak self] (error) in
                self?.logger.error("[GroupFreeBusyViewModel] checkCollaborationPermissionIgnoreError failed with: \(error)")
            }).disposed(by: disposeBag)
    }
    
    func moveAttendeeFirst(indexPath: IndexPath) {
        groupFreeBusyModel.moveAttendeeToFirst(indexPath: indexPath)
        if indexPath.row < selectedChatters.count {
            let chatter = selectedChatters[indexPath.row]
            selectedChatters.remove(at: indexPath.row)
            selectedChatters.insert(chatter, at: 0)
            if let index = orderedChatters.firstIndex(of: chatter) {
                orderedChatters.remove(at: index)
            }
            orderedChatters.insert(chatter, at: 0)
            updateGroupChatter()
        }
        
        CalendarTracerV2.CalendarChat.traceClick {
            $0.click("change_list").target("none")
            $0.chat_id = self.chatId
        }
    }
    
    private func configGroupFreeBusyModel() -> GroupFreeBusyModel {
        let (startTime, endTime): (Date, Date)
        if let createEventBody = createEventBody {
            startTime = createEventBody.startDate
            if let endDate = createEventBody.endDate {
                endTime = endDate
            } else {
                endTime = (startTime + defaultDurationGetter().minute ?? Date())
            }
        } else {
            startTime = Date()
            endTime = Date()
        }
        
        return GroupFreeBusyModel(sunStateService: SunStateService(userResolver: self.userResolver),
                                  chatId: chatId,
                                  startTime: startTime,
                                  endTime: endTime,
                                  firstWeekday: firstWeekday,
                                  is12HourStyle: rxIs12HourStyle.value)
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
