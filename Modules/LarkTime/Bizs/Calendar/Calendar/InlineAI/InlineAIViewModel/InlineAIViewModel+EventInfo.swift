//
//  InlineAIViewModel+EventInfo.swift
//  Calendar
//
//  Created by pluto on 2023/10/15.
//

import Foundation
import LarkAIInfra
import RxSwift
import EventKit

// MARK: - 编辑页数据 推送&处理
extension InlineAIViewModel {

    private func addOnHistory() {
        if let info = currentEventInfo {
            historyMap.append(info)
        }
    }
    
    private func resetHistory() {
        if let info = currentEventInfo {
            historyMap = []
            historyMap.append(info)
        }
    }
    
    func historyDealer() {
        rxAction.accept(.eventCurInfoGet)

        if eventContentGenStage != .stage0 {
            if isInAdjustMode {
                addOnHistory()
            } else {
                resetHistory()
            }
        }
    }
    
    /// 重置为原始
    func resetToOriginalEventInfo() {
        if let info = originalEventInfo {
            rxAction.accept(.eventInfoFull(data: info))
        }
    }
    
    /// 确认上屏
    func confirmCurrentEventInfo() {
        rxAction.accept(.eventCurInfoGet)

        if var info = currentEventInfo {
            originalEventInfo = currentEventInfo
            info.model?.aiStyleInfo = AIGenerateEventInfoNeedHightLight()
            rxAction.accept(.eventInfoFull(data: info))
        }
        rxStatus.accept(.unknown)
    }
    
    /// show初始panel时被使用
    func updateOriginalEventInfo() {
        rxAction.accept(.eventCurInfoGet)
        originalEventInfo = currentEventInfo
    }
    
    /// 切换历史记录
    func changeHistory(pre: Bool) {
        if pre {
            if currentHistoryIndex > 0 {
                currentHistoryIndex -= 1
            }
        } else {
            if currentHistoryIndex < historyMap.count - 1 {
                currentHistoryIndex += 1
            }
        }
        
        if let info = historyMap[safeIndex: currentHistoryIndex] {
            rxAction.accept(.eventInfoFull(data: info))
            rxRoute.accept(.panel(panel: getFinishedAIPanelModel(hasHistory: true,
                                                                 feedBack: info.feedback)))
            updateCurrentEventInfo()
        }
    }
    
    func updateCurrentEventInfo() {
        rxAction.accept(.eventCurInfoGet)
    }
    
    /// 接受外部更新
    func updateCurrentEventFullInfo(info: InlineAIEventFullInfo?) {
        self.currentEventInfo = info
    }
    
    /// 数据对比过滤 && 数据推送
    func handleEventInfo(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        self.logger.info("INLINE_CALENDAR: handleEventInfo stage:\(currentStage)")

        let stStage = eventqueueStage
        for index in stStage.rawValue..<currentStage.rawValue {
            let checkstage = Server.CalendarMyAIInlineStage(rawValue: index + 1)
            switch checkstage {
            case .stage1:
                checkIfNeedHandleSummary(eventInfo: eventInfo)
            case .stage2:
                checkIfNeedHandleParticipants(eventInfo: eventInfo)
            case .stage3:
                checkIfNeedHandleTime(eventInfo: eventInfo)
            case .stage4:
                checkIfNeedHandleRule(eventInfo: eventInfo)
            case .stage5:
                checkIfNeedHandleMeetingRoom(eventInfo: eventInfo)
            case .stage6:
                checkIfNeedHandleMeetingNotes(eventInfo: eventInfo)
            default: break
            }
        }
        
        /// 更新 推送起始stage
        eventqueueStage = currentStage
        /// 更新 上屏的内容stage
        eventContentGenStage = eventInfoDataQueue.last?.stage ?? eventContentGenStage
        
        self.logger.info("INLINE_CALENDAR: eventqueueStage:\(eventContentGenStage)")
        excuteEventInfoDataQueue()
    }

    private func checkIfNeedHandleSummary(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        guard let eventInfo = eventInfo else { return }

        let targetSum = eventInfo.summary
        let curSum = currentEventInfo?.model?.summary ?? ""
        let originSum = originalEventInfo?.model?.summary ?? ""

        if targetSum != curSum && targetSum != originSum {
            let info = InlineAIEventInfo(eventInfo: eventInfo,
                                         stage: .stage1,
                                         needHightLight: AIGenerateEventInfoNeedHightLight(summary: true),
                                         type: .summary,
                                         inAdjustMode: isInAdjustMode)

            eventInfoDataQueue.append(info)
        }
    }

    private func checkIfNeedHandleParticipants(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        guard let eventInfo = eventInfo else { return }
        if let currentParticipantIds = currentEventInfo?.model?.attendees {
            let targetParticipantIds = eventInfo.participantIds

            let currentUserIDs = currentParticipantIds.map {
                $0.getPBModel()?.user.userID
            }

            let currentGroupUserIDs: [String] = currentParticipantIds.map {
                var userIDs: [String] = []
                switch $0 {
                case .group(let groupAttendee):
                    let ids: [String] = groupAttendee.memberSeeds.map { $0.user.chatterID }
                    userIDs += ids
                case .user(let userAttendee):
                    let ids = userAttendee.chatterId
                    userIDs.append(ids)
                default:break
                }

                return userIDs
            }.reduce([], +)

            let ids = targetParticipantIds.filter {
                !currentGroupUserIDs.contains($0.description)
            }

            if !ids.isEmpty {
                let info = InlineAIEventInfo(eventInfo: eventInfo,
                                             stage: .stage4,
                                             needHightLight: AIGenerateEventInfoNeedHightLight(attendee: ids.map { $0.description }),
                                             type: .attendee,
                                             inAdjustMode: isInAdjustMode)
                eventInfoDataQueue.append(info)
            }
        }
    }

    private func checkIfNeedHandleTime(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        guard let eventInfo = eventInfo else { return }
        let targetStartTime = eventInfo.startTime
        let targetEndTime = eventInfo.endTime
        if targetStartTime != 0, targetEndTime != 0 {

            let currentEndTime = Int64(currentEventInfo?.model?.endDate.timeIntervalSince1970 ?? 0)
            let currentStartTime = Int64(currentEventInfo?.model?.startDate.timeIntervalSince1970 ?? 0)

            let originEndTime = Int64(originalEventInfo?.model?.endDate.timeIntervalSince1970 ?? 0)
            let originStartTime = Int64(originalEventInfo?.model?.startDate.timeIntervalSince1970 ?? 0)

            let startTimeChange = (targetStartTime != originStartTime) && (targetStartTime != currentStartTime)
            let endTimeChange = (targetEndTime != originEndTime) && (targetEndTime != currentEndTime)

            if startTimeChange || endTimeChange {
                let info = InlineAIEventInfo(eventInfo: eventInfo,
                                             stage: .stage2,
                                             needHightLight: AIGenerateEventInfoNeedHightLight(time: (startTimeChange, endTimeChange)),
                                             type: .time,
                                             inAdjustMode: isInAdjustMode)
                eventInfoDataQueue.append(info)
            }
        }
    }

    private func checkIfNeedHandleRule(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        guard let eventInfo = eventInfo else { return }

        if let targetRrule = EKRecurrenceRule.recurrenceRuleFromString(eventInfo.recRule) {
            let trule = targetRrule.getReadableRecurrenceRepeatString(timezone: eventInfo.timezone.description)

            let originRrule = originalEventInfo?.model?.rrule ?? EKRecurrenceRule()
            let orule = originRrule.getReadableRecurrenceRepeatString(timezone: originalEventInfo?.model?.timeZone.identifier ?? "")

            let currentRrule = currentEventInfo?.model?.rrule ?? EKRecurrenceRule()
            let crule = currentRrule.getReadableRecurrenceRepeatString(timezone: currentEventInfo?.model?.timeZone.identifier ?? "")

            let endDateChanged = (targetRrule.recurrenceEnd?.endDate != originRrule.recurrenceEnd?.endDate) && (targetRrule.recurrenceEnd?.endDate != currentRrule.recurrenceEnd?.endDate)
            let ruleChanged = (trule != orule) && (trule != crule)

            if ruleChanged || endDateChanged {
                let info = InlineAIEventInfo(eventInfo: eventInfo,
                                             stage: .stage3,
                                             needHightLight: AIGenerateEventInfoNeedHightLight(rrule:(ruleChanged, endDateChanged)),
                                             type: .rrule, inAdjustMode: isInAdjustMode)
                eventInfoDataQueue.append(info)
            }
        }
    }

    private func checkIfNeedHandleMeetingRoom(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        guard let eventInfo = eventInfo else { return }

        let targetResourceIds: [String] = eventInfo.resourceIds.map { $0.description }

        let originResourceIds: [String] = originalEventInfo?.model?.meetingRooms.map({ $0.uniqueId }) ?? []

        let currentResourceIds: [String] = currentEventInfo?.model?.meetingRooms.map({ $0.uniqueId }) ?? []

        var addOnResourceIds: [String] = []

        let bleResource = eventInfo.resources.filter {
            !currentResourceIds.contains($0.resourceID.description) && $0.resourceType == .bleResource
        }

        let bleResourceIds: [String] = bleResource.map {
            $0.resourceID.description
        }
        var fullEventinfo = eventInfo
        if isInAdjustMode {
            addOnResourceIds = targetResourceIds.filter {
                !currentResourceIds.contains($0)
            }
            fullEventinfo.resourceIds = (addOnResourceIds + originResourceIds).map { Int64($0) ?? 0 }
        } else {
            addOnResourceIds = targetResourceIds.filter {
                !originResourceIds.contains($0)
            }
        }

        var addOnResources: [AIGenerateMeetingRoom] = []
        for item in addOnResourceIds {
            let info = AIGenerateMeetingRoom(resourceID: item,
                                             resourceType: bleResourceIds.contains(item) ? .bleResource : .normalResource)
            addOnResources.append(info)
        }

        if !addOnResourceIds.isEmpty {
            let info = InlineAIEventInfo(eventInfo: fullEventinfo,
                                         stage: .stage5,
                                         needHightLight: AIGenerateEventInfoNeedHightLight(meetingRoom: addOnResources),
                                         type: .meetingRoom,
                                         inAdjustMode: isInAdjustMode)
            eventInfoDataQueue.append(info)
        }
    }

    private func checkIfNeedHandleMeetingNotes(eventInfo: Server.MyAICalendarEventInfo? = nil) {
        guard let eventInfo = eventInfo else { return }
        if eventInfo.meetingNotes.docToken.isEmpty { return }
        let currentNoChange: Bool = eventInfo.meetingNotes.docToken == currentEventInfo?.meetingNotesModel?.token
        let originalNoChange: Bool = eventInfo.meetingNotes.docToken == originalEventInfo?.meetingNotesModel?.token
        if currentNoChange || originalNoChange { return }

        let info = InlineAIEventInfo(eventInfo: eventInfo,
                                     stage: .stage6,
                                     needHightLight: AIGenerateEventInfoNeedHightLight(meetingNotes: true),
                                     type: .meetingNotes,
                                     inAdjustMode: isInAdjustMode)
        eventInfoDataQueue.append(info)
    }

    private func excuteEventInfoDataQueue() {
        guard upScreenTimer == nil else { return }
        upScreenTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            guard let self = self else { return }
            self.screenDataUpdater()
        })
    }
    
    private func screenDataUpdater() {
        self.logger.info("INLINE_CALENDAR: currentStage \(currentStage) aiTaskStatus \(aiTaskStatus) isUpScreening \(isUpScreening) DataQueueisEmpty \(eventInfoDataQueue.isEmpty)")

        if (currentStage == .stage6 || aiTaskStatus != .processing) && !isUpScreening && eventInfoDataQueue.isEmpty {
            transferToFinishStatus()
            stopUpScreenTimer()
            return
        }
        
        if eventInfoDataQueue.isEmpty || isUpScreening { return }
        isUpScreening = true

        guard let data = self.eventInfoDataQueue[safeIndex: 0] else { return }
        switch data.type {
        case .summary, .time, .rrule:
            self.rxAction.accept(.eventInfoStage(data: data))
            self.outEventInfoQueueData()
            isUpScreening = false
        case .attendee:
            let onAddAttendeeCompleteCallBack: (()->Void) = { [weak self] in
                DispatchQueue.main.async {
                    self?.outEventInfoQueueData()
                    self?.isUpScreening = false
                }
            }
            let info = InlineAIEventInfo(eventInfo: data.eventInfo,
                                         stage: data.stage,
                                         needHightLight: data.needHightLight,
                                         type: data.type,
                                         inAdjustMode: data.inAdjustMode,
                                         attendeeCompleteCallBack: onAddAttendeeCompleteCallBack)

            if aiTaskStatus != .processing { return }
            self.rxAction.accept(.eventInfoStage(data: info))

        case .meetingRoom:
            guard let resourceIds = data.eventInfo?.resourceIds else { return }
            let calendarIDs: [String] = resourceIds.map { $0.description }
            self.logger.info("loadResourcesByCalendarIdsRequest with \(calendarIDs)")

            calendarApi?.loadResourcesByCalendarIdsRequest(calendarIDs: calendarIDs)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] res in
                    guard let self = self else { return }
                    self.logger.info("loadResourcesByCalendarIdsRequest success with \(res.resources.count)")

                    var meetingRooms: [CalendarMeetingRoom] = []
                    for item in res.resources {
                        let meetingRoom = item.value
                        let buildingName = res.buildings[meetingRoom.buildingID]?.name ?? ""
                        let tenantId = meetingRoom.tenantID
                        meetingRooms.append(CalendarMeetingRoom.makeMeetingRoom(fromResource: meetingRoom,
                                                                                buildingName: buildingName,
                                                                                tenantId: tenantId))
                    }

                    var sortedMeetingRooms: [CalendarMeetingRoom] = []
                    for item in calendarIDs {
                        let room = meetingRooms.filter { $0.uniqueId == item }
                        sortedMeetingRooms.append(contentsOf: room)
                    }


                    let info = InlineAIEventInfo(eventInfo: data.eventInfo,
                                                 stage: data.stage,
                                                 needHightLight: data.needHightLight,
                                                 type: data.type,
                                                 inAdjustMode: data.inAdjustMode,
                                                 meetingRoomModels: sortedMeetingRooms)
                    if aiTaskStatus != .processing { return }
                    rxAction.accept(.eventInfoStage(data: info))
                    self.outEventInfoQueueData()

                    isUpScreening = false
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    self.logger.error("loadResourcesByCalendarIdsRequest failed with \(error)")
                    
                    self.rxAction.accept(.eventInfoStage(data: data))
                    self.outEventInfoQueueData()
                    self.isUpScreening = false

                }).disposed(by: disposeBag)
            
        case .meetingNotes:
            guard let token = data.eventInfo?.meetingNotes.docToken else { return }
            meetingNotesLoader.getNotesInfo(with: token, docType: NotesType.createNotes.rawValue)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] model in
                    guard let self = self else { return }
                    self.logger.info("getNotesInfo success with \(String(describing: model?.docOwnerId))")

                    var meetingNotesModel = model
                    meetingNotesModel?.docOwnerId = data.eventInfo?.meetingNotes.docOwnerID
                    let info = InlineAIEventInfo(eventInfo: data.eventInfo,
                                                 stage: data.stage,
                                                 needHightLight: data.needHightLight,
                                                 type: data.type,
                                                 inAdjustMode: data.inAdjustMode,
                                                 meetingNotesModel: meetingNotesModel)
                    if aiTaskStatus != .processing { return }
                    self.rxAction.accept(.eventInfoStage(data: info))
                    self.outEventInfoQueueData()

                    isUpScreening = false
                }, onError: {[weak self] error in
                    guard let self = self else { return }
                    self.logger.error("getNotesInfo failed with \(error)")
                    self.rxAction.accept(.eventInfoStage(data: data))
                    self.outEventInfoQueueData()

                    self.isUpScreening = false
                }).disposed(by: disposeBag)
        default: break
        }
    }

    private func outEventInfoQueueData() {
        if eventInfoDataQueue.isEmpty { return }
        eventInfoDataQueue.remove(at: 0)
    }
    /// 重置上屏队列标记
    func resetEventqueueStage() {
        eventqueueStage = .stage0
        eventContentGenStage = .stage0
        aiTaskNeedEndCounter = 0
        aiTaskNeedEnd = false
        eventInfoDataQueue = []
    }
    
    func stopUpScreenTimer() {
        upScreenTimer?.invalidate()
        upScreenTimer = nil
    }
}
