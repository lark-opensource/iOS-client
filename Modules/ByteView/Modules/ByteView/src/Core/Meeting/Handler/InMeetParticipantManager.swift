//
//  InMeetParticipantManager.swift
//  ByteView
//
//  Created by wulv on 2023/3/27.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import ByteViewTracker
import ByteViewSetting

final class InMeetParticipantManager {
    private let logger = Logger.participant
    private let session: MeetingSession
    let service: MeetingBasicService
    var account: ByteviewUser { service.account }
    var httpClient: HttpClient { service.httpClient }
    private let myselfNotifier: MyselfNotifier?
    var myself: Participant? { myselfNotifier?.myself }
    let meetingId: String
    let subType: MeetingSubType
    @RwAtomic private var meetType: MeetingType
    @RwAtomic private(set) var nameStrategy: InMeetParticipantStrategy?

    /// 全部参会人
    @RwAtomic private(set) var global = ParticipantData()
    /// 同组参会人（普通会议时和 global 相同；分组会议时，仅包含当前讨论组 or 同在主会场的人）
    @RwAtomic private(set) var currentRoom = ParticipantData()

    // 1v1 对方
    @RwAtomic private(set) var another: Participant?

    // 当前正在聚焦观看的参会人，是inMeetingInfo.focusVideoData的一层过滤
    // 因为「我被设为焦点」「我是主共享人」等情况下，即使后端推送也不应该进入“焦点模式”
    // https://bytedance.feishu.cn/docx/doxcn5iVj800BwtbjsDskch8w0g#doxcnuqgMGQ8CiCIuE7a4wUw9Fe
    @RwAtomic private(set) var focusing: Participant?
    @RwAtomic private var focusingUser: ByteviewUser?

    /// 拉取建议列表
    private(set) lazy var pullSuggestionTrigger = StrategyTrigger<Void>(with: .milliseconds(service.setting.suggestionConfig.requestInterval),
                                                                        id: "pullSuggested") { [weak self] _ in
        self?.pullSuggestedParticipants()
    }
    /// 建议列表/拒绝列表下发数据
    @RwAtomic private(set) var suggested: GetSuggestedParticipantsResponse?
    /// 建议数据 seq id
    @RwAtomic private var suggestionSeqID: Int64 = 0

    /// 是否收到全量参会人推送
    @RwAtomic private(set) var isFullParticipantsReceived = false

    /// 待废弃（移至宫格流）
    private var gridAggregator: WebinarGridParticipantAggregator?
    /// webinar 观众（嘉宾视角）
    @RwAtomic private(set) var attendee = ParticipantData()
    /// webinar 观众人数（嘉宾视角，>= attendees.count）
    @RwAtomic private(set) var attendeeNum: Int64?
    /// webinar 嘉宾（观众视角）
    @RwAtomic private(set) var attendeePanel = ParticipantData()

    /// - as计算池
    /// - 普通会议，对应当前讨论组/主会场参会人
    /// - Webinar 观众，对应 嘉宾 + 正在发言的观众
    /// - Webinar 嘉宾，对应 嘉宾 + 正在发言的观众
    @RwAtomic private(set) var activePanel = ParticipantData()

    private lazy var logDescription = "[InMeetParticipantManager][\(meetingId)]"
    init(session: MeetingSession, service: MeetingBasicService, info: VideoChatInfo) {
        self.session = session
        self.service = service
        self.meetingId = info.id
        self.subType = info.settings.subType
        self.meetType = info.type
        self.myselfNotifier = session.component(for: MyselfNotifier.self)
        self.gridAggregator = WebinarGridParticipantAggregator()
        let nameStrategy = info.makeStrategy(account: self.account, isShowAnotherNameEnabled: service.setting.isShowAnotherNameEnabled)
        self.nameStrategy = nameStrategy
        ParticipantService.setStrategy(strategy: nameStrategy, for: ParticipantStrategyKey(userId: account.id, meetingId: meetingId))
        if let myself = self.myself {
            self.global = ParticipantData(participants: [myself])
            self.currentRoom = ParticipantData(participants: [myself])
            if subType != .webinar || myself.meetingRole != .webinarAttendee {
                self.activePanel = ParticipantData(participants: [myself])
            } else if !myself.settings.isMicrophoneMutedOrUnavailable {
                self.activePanel = ParticipantData(participants: [myself])
            }
            self.nameStrategy?.updateParticipantsName(participants: [myself])
        }
        addListeners()
        logger.info("init \(logDescription)")
    }

    deinit {
        logger.info("deinit \(logDescription)")
    }

    func release() {
        removeListeners()
        nameStrategy = nil
        global = ParticipantData()
        currentRoom = ParticipantData()
        attendee = ParticipantData()
        attendeePanel = ParticipantData()
        activePanel = ParticipantData()
        suggested = nil
        gridAggregator = nil
    }

    private func addListeners() {
        session.push?.combinedInfo.addObserver(self)
        session.push?.fullParticipants.addObserver(self)
        session.push?.participantChange.addObserver(self)
        session.push?.attendeeChange.addObserver(self)
        session.push?.attendeeViewChange.addObserver(self)
        nameStrategy?.chattersInfoDidClear = { [weak self] in
            self?.handleChattersInfoChanged($0)
        }
        session.push?.inMeetingChange.addObserver(self)
        session.push?.suggestedParticipants.addObserver(self)
        myselfNotifier?.addListener(self)
    }

    private func removeListeners() {
        session.push?.combinedInfo.removeObserver(self)
        session.push?.fullParticipants.removeObserver(self)
        session.push?.participantChange.removeObserver(self)
        session.push?.attendeeChange.removeObserver(self)
        session.push?.attendeeViewChange.removeObserver(self)
        session.push?.inMeetingChange.removeObserver(self)
        session.push?.suggestedParticipants.removeObserver(self)
        myselfNotifier?.removeListener(self)
    }

    private let listeners = Listeners<InMeetParticipantListener>()

    func addListener(_ listener: InMeetParticipantListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: InMeetParticipantListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: InMeetParticipantListener) {
        if !global.isEmpty {
            listener.didChangeGlobalParticipants(global.defaultChange)
        }
        if !currentRoom.isEmpty {
            listener.didChangeCurrentRoomParticipants(currentRoom.defaultChange)
        }
        if let num = attendeeNum {
            listener.didChangeWebinarAttendeeNum(num)
        }
        if !attendee.isEmpty {
            listener.didChangeWebinarAttendees(attendee.defaultChange)
        }
        if !attendeePanel.isEmpty {
            listener.didChangeWebinarParticipantForAttendee(attendeePanel.defaultChange)
        }
        if meetType == .call, let p = another {
            listener.didChangeAnotherParticipant(p)
        }
        listener.didChangeFocusingParticipant(focusing, oldValue: nil)
        if let suggested = suggested {
            listener.didReceiveSuggestedParticipants(suggested)
        }
        if let binder = myself?.binder {
            listener.didChangeMyselfBinder(binder, oldValue: nil)
        }
    }

    // 排序规则https://bytedance.feishu.cn/docs/doccnsVC610vJD98ycaUFEwW6Gf#
    /// 将rust推送的增量信息与现有数据做merge
    private func mergeParticipantChange(for sourceData: ParticipantData, change: MeetingParticipantChange,
                                        skipSelfWhileRemove: Bool = false, function: String = #function) -> (ParticipantData, InMeetParticipantOutput.Modify) {
        var ringingInserts: [ByteviewUser: Participant] = [:]
        var nonRingingInserts: [ByteviewUser: Participant] = [:]
        var ringingUpdates: [ByteviewUser: Participant] = [:]
        var nonRingingUpdates: [ByteviewUser: Participant] = [:]
        var ringingRemoves: [ByteviewUser: Participant] = [:]
        var nonRingingRemoves: [ByteviewUser: Participant] = [:]
        var ringingDict = sourceData.ringingDict
        var nonRingingDict = sourceData.nonRingingDict
        // 增加或者更新
        change.upsertParticipants.forEach {
            let key = $0.user
            if $0.status == .ringing {
                if ringingDict[key] == nil {
                    ringingInserts[key] = $0
                } else if ringingDict[key] != $0 {
                    ringingUpdates[key] = $0
                }
                ringingDict[key] = $0
            } else {
                if nonRingingDict[key] == nil {
                    nonRingingInserts[key] = $0
                } else if nonRingingDict[key] != $0 {
                    nonRingingUpdates[key] = $0
                }
                nonRingingDict[key] = $0
            }
        }
        // 移除且不能移除自己
        // 拒接的用户在remove里，status=idle
        change.removeParticipants.forEach {
            let key = $0.user
            if ringingDict[key] == nil, nonRingingDict[key] == nil {
                /// 目前仅拒绝回复理由更新会走这里
                ringingRemoves[key] = $0
            } else {
                if ringingDict[key] != nil {
                    ringingRemoves[key] = $0
                    ringingDict.removeValue(forKey: key)
                }
                if nonRingingDict[key] != nil {
                    if $0.user == account, skipSelfWhileRemove { return }
                    nonRingingRemoves[key] = $0
                    nonRingingDict.removeValue(forKey: key)
                }
            }
        }
        // 非ringing中有的话要移除ringring中的数据
        nonRingingDict.forEach {
            let key = $0.key
            let ringingKey = ByteviewUser(id: key.id, type: key.type, deviceId: "")
            if ringingDict[ringingKey] != nil {
                ringingRemoves[ringingKey] = ringingDict[ringingKey]
                ringingDict.removeValue(forKey: ringingKey)
            } else if ringingDict[key] != nil {
                ringingRemoves[key] = ringingDict[key]
                ringingDict.removeValue(forKey: key)
            }
        }
        let mergedData = ParticipantData(ringingDict: ringingDict, nonRingingDict: nonRingingDict)
        let modify = InMeetParticipantOutput.Modify(ringing: .init(inserts: ringingInserts, updates: ringingUpdates, removes: ringingRemoves), nonRinging: .init(inserts: nonRingingInserts, updates: nonRingingUpdates, removes: nonRingingRemoves))
        logger.info("mergedData = \(mergedData), modify = \(modify)", function: function)
        return (mergedData, modify)
    }

    /// Param:
    /// - participants: rust推的全量参会人
    /// - mergedData: rust推增量时，为merge后的值
    /// - modify: rust推增量时，modify携带增量信息
    private func handlePushParticipants(_ participants: [Participant]? = nil, mergedData: ParticipantData? = nil, modify: InMeetParticipantOutput.Modify? = nil) {
        // 先更新各参会人属性（myself -> global -> currentRoom -> another -> activePanel)
        var ps: [Participant] = []
        if let participants = participants {
            ps = participants
        } else if let mergedData = mergedData {
            ps = mergedData.nonRingingDict.map(\.value)
        }
        let oldMyself = myself
        let myselfChanged = updateMyself(with: ps)
        let oldGlobal = global
        let globalModify: InMeetParticipantOutput.Modify? = updateGlobal(participants: participants, mergedData: mergedData, modify: modify)
        let oldCurrentRoom = currentRoom
        let currentRoomModify: InMeetParticipantOutput.Modify? = updateCurrentRoom(oldMyself: oldMyself, oldGlobal: oldGlobal, globalModify: globalModify)
        let anotherChanged = updateAnother(with: ps)
        updateActivePanel(currentRoomModify: currentRoomModify)

        // 再回调，顺序 agg -> focusing -> global -> currentRoom -> another
        if let fullps = participants {
            updateParticipantAgg(full: fullps)
        } else if let modify = modify {
            updateParticipantAgg(modify: modify)
        }

        if globalModify?.isEmpty == false {
            updateFocusingParticipant()
        }
        if myselfChanged, let joinTogether = myself?.settings.targetToJoinTogether {
            // 预加载同步入会的关联方的信息
            httpClient.participantService.participantInfo(pid: joinTogether, meetingId: meetingId, completion: { _ in })
        }
        if let globalModify = globalModify, !globalModify.isEmpty {
            listeners.forEach { $0.didChangeGlobalParticipants(.init(modify: globalModify, counts: global.toCounts(), newData: global, oldData: oldGlobal)) }
            logger.info("did change global: \(global), modify = \(globalModify)")
        }
        if let currentRoomModify = currentRoomModify, !currentRoomModify.isEmpty {
            listeners.forEach { $0.didChangeCurrentRoomParticipants(.init(modify: currentRoomModify, counts: currentRoom.toCounts(), newData: currentRoom, oldData: oldCurrentRoom)) }
            logger.info("did change currentRoom: \(currentRoom),  modify = \(currentRoomModify)")
        }
        if meetType == .call, anotherChanged {
            if let p = another {
                httpClient.participantService.participantInfo(pid: p, meetingId: meetingId) { [weak self] user in
                    guard let self = self, let nowP = self.another, nowP.user == p.user, self.meetType == .call else { return }
                    self.another?.userInfo = user
                    self.listeners.forEach { $0.didChangeAnotherParticipant(self.another) }
                }
            } else {
                listeners.forEach { $0.didChangeAnotherParticipant(nil) }
            }
        }
    }

    private func updateParticipantStrategy(full: [Participant]? = nil, modify: InMeetParticipantOutput.Modify? = nil) {
        if let modify = modify {
            nameStrategy?.updateParticipantsName(modify: modify)
        } else if let full = full {
            nameStrategy?.updateParticipantsName(participants: full)
        }
    }

    private func updateMyself(with participants: [Participant]) -> Bool {
        let oldMyself = myself
        var binder: Participant?
        if var newMyself = participants.first(where: { $0.user == account }), newMyself != oldMyself {
            if let room = newMyself.settings.targetToJoinTogether {
                binder = participants.first(where: { $0.user == room })
            }
            let oldBinder = oldMyself?.binder
            newMyself.binder = binder
            myselfNotifier?.update(newMyself)
            if oldBinder != binder {
                listeners.forEach { $0.didChangeMyselfBinder(binder, oldValue: oldBinder) }
            }
            return true
        } else if let room = myself?.settings.targetToJoinTogether {
            binder = participants.first(where: { $0.user == room })
            let oldBinder = oldMyself?.binder
            if oldBinder != binder {
                myselfNotifier?.updateBinder(binder)
                listeners.forEach { $0.didChangeMyselfBinder(binder, oldValue: oldBinder) }
            }
            return false
        }
        return false
    }

    private func updateGlobal(participants: [Participant]?, mergedData: ParticipantData?, modify: InMeetParticipantOutput.Modify?) -> InMeetParticipantOutput.Modify? {
        var globalModify: InMeetParticipantOutput.Modify?
        if let fullData = mergedData, let modify = modify, !modify.isEmpty {
            globalModify = modify
            global = fullData
        } else if let fullps = participants {
            // 将全量转换成增量信息回调给外部
            globalModify = prepareDiff(old: global, new: fullps)
            global = .init(participants: fullps)
        }
        return globalModify
    }

    private func updateCurrentRoom(oldMyself: Participant?, oldGlobal: ParticipantData, globalModify: InMeetParticipantOutput.Modify?) -> InMeetParticipantOutput.Modify? {
        guard let myself = myself else { return nil }
        let oldCurrentRoom = currentRoom
        var currentRoomModify: InMeetParticipantOutput.Modify?
        if let mdf = globalModify, !mdf.isEmpty {
            let mybkId = myself.breakoutRoomId
            /// 若组未变
            if let old = oldMyself, old.isInBreakoutRoom(mybkId) {
                var ringingInserts: [ByteviewUser: Participant] = [:]
                var nonringingInserts: [ByteviewUser: Participant] = [:]
                let insert: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, dict in
                    mdfs.forEach { (k, v) in
                        if v.isInBreakoutRoom(mybkId) {
                            dict[k] = v
                        }
                    }
                }
                insert(mdf.ringing.inserts, &ringingInserts)
                insert(mdf.nonRinging.inserts, &nonringingInserts)

                var ringingRemoves: [ByteviewUser: Participant] = [:]
                var nonringingRemoves: [ByteviewUser: Participant] = [:]
                let remove: ([ByteviewUser: Participant], [ByteviewUser: Participant], inout [ByteviewUser: Participant], Bool) -> Void = { mdfs, olds, dict, force in
                    mdfs.forEach { (k, v) in
                        if force || olds[k] != nil {
                            dict[k] = v
                        }
                    }
                }
                remove(mdf.ringing.removes, oldCurrentRoom.ringingDict, &ringingRemoves, true) // 防止遗漏拒接信息的更新
                remove(mdf.nonRinging.removes, oldCurrentRoom.nonRingingDict, &nonringingRemoves, false)

                var ringingUpdates: [ByteviewUser: Participant] = [:]
                var nonringingUpdates: [ByteviewUser: Participant] = [:]
                let update: ([ByteviewUser: Participant], [ByteviewUser: Participant], inout [ByteviewUser: Participant], inout [ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, olds, inserts, updates, removes in
                    mdfs.forEach { (k, v) in
                        if olds[k]  != nil {
                            // 之前同组
                            if v.isInBreakoutRoom(mybkId) {
                                // 仍同组
                                updates[k] = v
                            } else {
                                // 不同组
                                removes[k] = olds[k]
                            }
                        } else {
                            if v.isInBreakoutRoom(mybkId) {
                                // 新入组
                                inserts[k] = v
                            }
                        }
                    }
                }
                update(mdf.ringing.updates, oldCurrentRoom.ringingDict, &ringingInserts, &ringingUpdates, &ringingRemoves)
                update(mdf.nonRinging.updates, oldCurrentRoom.nonRingingDict, &nonringingInserts, &nonringingUpdates, &nonringingRemoves)

                currentRoomModify = .init(ringing: .init(inserts: ringingInserts, updates: ringingUpdates, removes: ringingRemoves), nonRinging: .init(inserts: nonringingInserts, updates: nonringingUpdates, removes: nonringingRemoves))
            } else {
                /// 若组已变
                var ringingInserts: [ByteviewUser: Participant] = [:]
                var nonRingingInserts: [ByteviewUser: Participant] = [:]
                let insertOld: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { olds, dict in
                    olds.forEach { (k, v) in
                        if v.isInBreakoutRoom(mybkId) {
                            dict[k] = v
                        }
                    }
                }
                insertOld(oldGlobal.ringingDict, &ringingInserts)
                insertOld(oldGlobal.nonRingingDict, &nonRingingInserts)

                let insert: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, dict in
                    mdfs.forEach { (k, v) in
                        if v.isInBreakoutRoom(mybkId) {
                            dict[k] = v
                        }
                    }
                }
                insert(mdf.ringing.inserts, &ringingInserts)
                insert(mdf.nonRinging.inserts, &nonRingingInserts)

                var ringingRemoves: [ByteviewUser: Participant] = oldCurrentRoom.ringingDict
                var nonRingingRemoves: [ByteviewUser: Participant] = oldCurrentRoom.nonRingingDict
                nonRingingRemoves.removeValue(forKey: myself.user)

                let remove: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, dict in
                    mdfs.forEach { (k, v) in
                        if v.isInBreakoutRoom(mybkId) {
                            /// 从新组中移除了
                            dict.removeValue(forKey: k)
                        }
                    }
                }
                remove(mdf.ringing.removes, &ringingInserts)
                remove(mdf.nonRinging.removes, &nonRingingInserts)

                var ringingUpdates: [ByteviewUser: Participant] = [:]
                var nonRingingUpdates: [ByteviewUser: Participant] = [:]
                let update: ([ByteviewUser: Participant], [ByteviewUser: Participant], inout [ByteviewUser: Participant], inout [ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, olds, inserts, updates, removes in
                    mdfs.forEach { (k, v) in
                        // 现在同组
                        if v.isInBreakoutRoom(mybkId) {
                            // 之前也同组
                            if olds[k] != nil {
                                // 转为更新
                                removes.removeValue(forKey: k)
                                updates[k] = v
                            } else {
                                // 之前不同组，标记新增
                                inserts[k] = v
                            }
                        } else {
                            // 之前同组
                            if olds[k] != nil {
                                // 更新remove值
                                removes[k] = v
                            }
                        }
                    }
                }
                update(mdf.ringing.updates, oldCurrentRoom.ringingDict, &ringingInserts, &ringingUpdates, &ringingRemoves)
                update(mdf.nonRinging.updates, oldCurrentRoom.nonRingingDict, &nonRingingInserts, &nonRingingUpdates, &nonRingingRemoves)

                currentRoomModify = .init(ringing: .init(inserts: ringingInserts, updates: ringingUpdates, removes: ringingRemoves), nonRinging: .init(inserts: nonRingingInserts, updates: nonRingingUpdates, removes: nonRingingRemoves))
            }
            if let newMdf = currentRoomModify, !newMdf.isEmpty {
                // 更新
                currentRoom.update(with: newMdf)
            }
        }
        logger.info("update currentRoom modify = \(currentRoomModify), old = \(oldCurrentRoom)")
        return currentRoomModify
    }

    /// 全量与全量间算diff
    private func prepareDiff(old: ParticipantData, new: [Participant], function: String = #function) -> InMeetParticipantOutput.Modify {
        prepareDiff(old: old, new: .init(participants: new))
    }
    private func prepareDiff(old: ParticipantData, new: ParticipantData, function: String = #function) -> InMeetParticipantOutput.Modify {
        let ringingChanges = diffData(old: old.ringingDict, new: new.ringingDict)
        let nonRingingChanges = diffData(old: old.nonRingingDict, new: new.nonRingingDict)
        let modify = InMeetParticipantOutput.Modify(ringing: ringingChanges, nonRinging: nonRingingChanges)
        logger.info("diff to modify = \(modify)", function: function)
        return modify
    }

    private func diffData(old: [ByteviewUser: Participant], new: [ByteviewUser: Participant]) -> InMeetParticipantOutput.Changes {
        var inserts: [ByteviewUser: Participant] = [:]
        var updates: [ByteviewUser: Participant] = [:]
        new.forEach { (k, v) in
            if old[k] == nil {
                inserts[k] = v
            } else if let oldValue = old[k], oldValue != v {
                updates[k] = v
            }
        }

        var removes: [ByteviewUser: Participant] = [:]
        old.forEach { (k, v) in
            if new[k] == nil {
                removes[k] = v
            }
        }
        return InMeetParticipantOutput.Changes(inserts: inserts, updates: updates, removes: removes)
    }

    private func updateAnother(with participants: [Participant]) -> Bool {
        if meetType == .call {
            let newAnother = participants.first(where: { $0.user != account })
            if newAnother != another {
                another = newAnother
                return true
            }
        }
        return false
    }

    private func updateActivePanel(oldMyself: Participant?, mySelf: Participant) {
        if subType == .webinar
            && oldMyself?.meetingRole != myself?.meetingRole
            && (oldMyself?.meetingRole == .webinarAttendee || myself?.meetingRole == .webinarAttendee) {
            if myself?.meetingRole == .webinarAttendee {
                activePanel = attendeePanel.filter { $0.value.meetingRole != .webinarAttendee || !$0.value.settings.isMicrophoneMutedOrUnavailable }
            } else {
                // tips: 当自己是观众时，participantChange会推一个自己，此时currentRoom包含观众
                activePanel = attendee.filter { !$0.value.settings.isMicrophoneMutedOrUnavailable } + currentRoom.filter { $0.value.meetingRole != .webinarAttendee || !$0.value.settings.isMicrophoneMutedOrUnavailable }

            }
            logger.info("update activePanel when mySelf changed = \(activePanel)")
        }
    }

    private func updateActivePanel(currentRoomModify: InMeetParticipantOutput.Modify?) {
        if subType == .webinar {
            if myself?.meetingRole != .webinarAttendee, let currentRoomModify = currentRoomModify, !currentRoomModify.isEmpty {
                // 嘉宾<->观众身份互换时，嘉宾/观众的推送无序，所以更新时要校验身份
                activePanel.update(with: currentRoomModify) { $0.meetingRole != .webinarAttendee }
            }
        } else if let currentRoomModify = currentRoomModify, !currentRoomModify.isEmpty {
            activePanel = currentRoom
        }
        logger.info("update activePanel when currentRoom changed = \(activePanel)")
    }

    private func updateActivePanel(attendeeModify: InMeetParticipantOutput.Modify) {
        guard subType == .webinar, myself?.meetingRole != .webinarAttendee else { return }
        // 嘉宾<->观众身份互换时，嘉宾/观众的推送无序，所以更新时要校验身份
        activePanel = updateData(activePanel, modify: attendeeModify, modifyCondition: { !$0.value.settings.isMicrophoneMutedOrUnavailable }) { $0.meetingRole == .webinarAttendee }
        logger.info("update activePanel when attendee changed = \(activePanel)")
    }

    private func updateActivePanel(attendeePanelModify: InMeetParticipantOutput.Modify) {
        guard subType == .webinar, myself?.meetingRole == .webinarAttendee else { return }
        activePanel = updateData(activePanel, modify: attendeePanelModify) { !$0.value.settings.isMicrophoneMutedOrUnavailable || $0.value.meetingRole != .webinarAttendee }
        logger.info("update activePanel when attendeePanel changed = \(activePanel)")
    }

    private func updateData(_ data: ParticipantData, modify: InMeetParticipantOutput.Modify,
                            modifyCondition: @escaping (Dictionary<ByteviewUser, Participant>.Element) -> Bool,
                            removeCondition: ((Participant) -> Bool)? = nil) -> ParticipantData {
        var ringingDict = data.ringingDict
        var nonRingingDict = data.nonRingingDict
        let insert: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, dict in
            mdfs.forEach { (k, v) in
                if modifyCondition((k, v)) {
                    dict[k] = v
                }
            }
        }
        insert(modify.ringing.inserts, &ringingDict)
        insert(modify.nonRinging.inserts, &nonRingingDict)

        let updates: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, dict in
            mdfs.forEach { (k, v) in
                if modifyCondition((k, v)) {
                    dict[k] = v
                } else {
                    dict.removeValue(forKey: k)
                }
            }
        }
        updates(modify.ringing.updates, &ringingDict)
        updates(modify.nonRinging.updates, &nonRingingDict)

        let removes: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { mdfs, dict in
            mdfs.forEach { (k, _) in
                if let removeCondition = removeCondition, let p = dict[k], !removeCondition(p) { return }
                dict.removeValue(forKey: k)
            }
        }
        removes(modify.ringing.removes, &ringingDict)
        removes(modify.nonRinging.removes, &nonRingingDict)

        return .init(ringingDict: ringingDict, nonRingingDict: nonRingingDict)
    }

    private func updateFocusingParticipant() {
        // 当前有"被聚焦者" && "我"不是"被聚焦者" && "被聚焦者"仍在会中 ==> 进入聚焦模式
        var newFocusingP: Participant?
        if let focusingUser = focusingUser, focusingUser != account,
           let participant = find(user: focusingUser,
                                  in: myself?.meetingRole == .webinarAttendee ? .attendeePanels : .global) {
            newFocusingP = participant
        }
        let oldFocusingP = focusing
        if newFocusingP?.identifier != oldFocusingP?.identifier {
            focusing = newFocusingP
            logger.info("change focusing participant: \(newFocusingP?.identifier)")
            listeners.forEach { $0.didChangeFocusingParticipant(newFocusingP, oldValue: oldFocusingP) }
        }
    }

    /// 这里participant未变，只是为了通知外部刷新备注名等信息，不太合理，找时机改掉
    private func handleChattersInfoChanged(_ chatterIds: Set<String>) {
        if chatterIds.isEmpty { return }
        let global = global
        if let modify = modifyWithChatterIds(chatterIds, data: global) {
            listeners.forEach { $0.didChangeGlobalParticipants(.init(modify: modify, counts: global.toCounts(), newData: global, oldData: global)) }
        }
        let currentRoom = currentRoom
        if let modify = modifyWithChatterIds(chatterIds, data: currentRoom) {
            listeners.forEach { $0.didChangeCurrentRoomParticipants(.init(modify: modify, counts: currentRoom.toCounts(), newData: currentRoom, oldData: currentRoom))}
        }
        let attendee = attendee
        if subType == .webinar, let modify = modifyWithChatterIds(chatterIds, data: attendee) {
            listeners.forEach { $0.didChangeWebinarAttendees(.init(modify: modify, counts: attendee.toCounts(), newData: attendee, oldData: attendee)) }
        }
    }

    private func modifyWithChatterIds(_ chatterIds: Set<String>, data: ParticipantData) -> InMeetParticipantOutput.Modify? {
        var updateRingings: [ByteviewUser: Participant] = [:]
        var updateNonRingings: [ByteviewUser: Participant] = [:]
        let update: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { current, dicts in
            current.forEach { (k, v) in
                if chatterIds.contains(v.user.id) {
                    dicts[k] = v
                }
            }
        }
        update(data.ringingDict, &updateRingings)
        update(data.nonRingingDict, &updateNonRingings)
        if !updateRingings.isEmpty || !updateNonRingings.isEmpty {
            let modify = InMeetParticipantOutput.Modify(ringing: .init(updates: updateRingings), nonRinging: .init(updates: updateNonRingings))
            return modify
        }
        return nil
    }

    private func pullSuggestedParticipants() {
        let request = GetSuggestedParticipantsRequest(meetingId: meetingId, includeDecline: true, seqID: suggestionSeqID)
        httpClient.getResponse(request, context: request) { [weak self] (result) in
            guard let self = self, let response = result.value else { return }
            self.logger.info("cur suggestion seq_id: \(self.suggestionSeqID), resp seq_id: \(response.seqID), latest: \(response.alreadyLatestSuggestion), count: \(response.suggestedParticipants.count), sips count: \(response.sipRooms.count)")
            self.suggestionSeqID = response.seqID
            if response.alreadyLatestSuggestion { return }
            self.suggested = response
            self.listeners.forEach { $0.didReceiveSuggestedParticipants(response) }
        }
    }
}

extension InMeetParticipantManager {

    var interviewerCount: Int {
        currentRoom.all.filter { $0.role == .interviewer }.count
    }

    var hasHostOrCohost: Bool {
        currentRoom.all.contains(where: { $0.meetingRole == .host || $0.meetingRole == .coHost })
    }

    var otherParticipant: Participant? {
        find { $0.user != session.account }
    }

    var otherUIdParticipant: Participant? {
        find { $0.user.id != session.account.id }
    }

    var duplicatedParticipant: Participant? {
        find { $0.user.id == session.account.id && $0.user.deviceId != session.account.deviceId }
    }
}

extension InMeetParticipantManager {

    enum FindStatus {
        case all
        case ringing
        case nonRinging

        var filter: (ParticipantData) -> [ByteviewUser: Participant] {
            switch self {
            case .all: return { _ in [:] }
            case .ringing: return { $0.ringingDict }
            case .nonRinging: return { $0.nonRingingDict }
            }
        }
    }

    enum FindType {
        /// 全部参会人
        case global
        /// 全部参会人（分组会议时，仅包含同组参会人）
        case currentRooms
        /// 观众（嘉宾视角）
        case attendees
        /// 嘉宾（观众视角）
        case attendeePanels
        /// as计算池
        case activePanels
    }

    private func source(for type: FindType, status: FindStatus) -> [ByteviewUser: Participant] {
        switch type {
        case .global: return status.filter(global)
        case .currentRooms: return status.filter(currentRoom)
        case .attendees: return status.filter(attendee)
        case .attendeePanels: return status.filter(attendeePanel)
        case .activePanels: return status.filter(activePanel)
        }
    }

    func find(user: ByteviewUser, in type: FindType = .currentRooms, status: FindStatus = .nonRinging) -> Participant? {
        guard status == .all else {
            return source(for: type, status: status)[user]
        }
        return source(for: type, status: .ringing)[user] ?? source(for: type, status: .nonRinging)[user]
    }

    func contains(user: ByteviewUser, in type: FindType = .currentRooms, status: FindStatus = .nonRinging) -> Bool {
        find(user: user, in: type, status: status) != nil
    }

    func find(in type: FindType = .currentRooms, status: FindStatus = .nonRinging, _ condition: ((Participant) -> Bool)) -> Participant? {
        guard status == .all else {
            return source(for: type, status: status).first(where: { condition($0.value) })?.value
        }
        return source(for: type, status: .ringing).first(where: { condition($0.value) })?.value ??
        source(for: type, status: .nonRinging).first(where: { condition($0.value) })?.value
    }

    func find(rtcUid: RtcUID, in type: FindType = .currentRooms, status: FindStatus = .nonRinging) -> Participant? {
        find(in: type, status: status) { $0.isSameWith(rtcUid: rtcUid) }
    }
}

extension InMeetParticipantManager: VideoChatCombinedInfoPushObserver {
    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        guard inMeetingInfo.id == meetingId else { return }

        let newType = inMeetingInfo.vcType
        if newType != meetType {
            meetType = newType
            if inMeetingInfo.vcType != .call {
                another = nil
            }
        }

        let newFocusing = inMeetingInfo.focusingUser
        if newFocusing != focusingUser {
            focusingUser = newFocusing
            updateFocusingParticipant()
        }
    }
}

extension InMeetParticipantManager: FullParticipantsPushObserver, ParticipantChangePushObserver, WebinarAttendeeChangePushObserver, WebinarAttendeeViewChangePushObserver {

    // 普通会议全量推送
    func didReceiveFullParticipants(meetingId: String, participants: [Participant]) {
        isFullParticipantsReceived = true
        DevTracker.cancelTimeout(.warning(.meeting_miss_fullparticipants), key: session.sessionId)
        logger.info("didReceiveFullParticipants: meetingId = \(meetingId), count = \(participants.count)")
        updateParticipantStrategy(full: participants)
        handlePushParticipants(participants)
        logger.info("after diff all participants, count = \(global.count), currentRoom count = \(currentRoom.count)")
    }

    // 普通会议增量推送
    func didReceiveParticipantChange(_ message: MeetingParticipantChange) {
        guard isFullParticipantsReceived else { return }
        logger.info("didReceiveParticipantChange, upsert = \(message.upsertParticipants.count), remove = \(message.removeParticipants.count)")
        let (mergedData, modify) = mergeParticipantChange(for: global, change: message, skipSelfWhileRemove: true)
        updateParticipantStrategy(modify: modify)
        handlePushParticipants(mergedData: mergedData, modify: modify)
        logger.info("after merge all participants, count = \(global.count), currentRoom count = \(currentRoom.count)")
    }

    // webinar 观众（嘉宾视角）全量推送
    func didReceiveFullWebinarAttendees(meetingId: String, attendees: [Participant], num: Int64?) {
        logger.info("didReceiveFullWebinarAttendees: meetingId = \(meetingId), count = \(attendees.count), num = \(num)")
        updateParticipantStrategy(full: attendees)
        if let num = num, attendeeNum != num {
            attendeeNum = num
            listeners.forEach { $0.didChangeWebinarAttendeeNum(num) }
        }
        let oldAttendee = attendee
        attendee = .init(participants: attendees)
        let modify = prepareDiff(old: oldAttendee, new: attendees)
        if !modify.isEmpty {
            updateActivePanel(attendeeModify: modify)
            updateWebinarAttendeeAgg(full: attendees)
            listeners.forEach { $0.didChangeWebinarAttendees(.init(modify: modify, counts: attendee.toCounts(), newData: attendee, oldData: oldAttendee)) }
            logger.info("after diff all attendees, count = \(attendee.count), modify = \(modify)")
        }
    }

    // webinar 观众（嘉宾视角）增量推送
    func didReceiveWebinarAttendeeChange(_ message: MeetingParticipantChange) {
        guard isFullParticipantsReceived else { return }
        logger.info("didReceiveWebinarAttendeeChange, upsert = \(message.upsertParticipants.count), remove = \(message.removeParticipants.count), num = \(message.attendeeNum)")
        let (merged, modify) = mergeParticipantChange(for: attendee, change: message)
        updateParticipantStrategy(modify: modify)
        if let num = message.attendeeNum, num != attendeeNum {
            attendeeNum = num
            listeners.forEach { $0.didChangeWebinarAttendeeNum(num) }
        }
        if !modify.isEmpty {
            let oldAttendee = attendee
            attendee = merged
            updateActivePanel(attendeeModify: modify)
            updateWebinarAttendeeAgg(modify: modify)
            listeners.forEach { $0.didChangeWebinarAttendees(.init(modify: modify, counts: merged.toCounts(), newData: merged, oldData: oldAttendee)) }
            logger.info("after merge all attendees, count = \(attendee.count)")
        }
    }

    // webinar 嘉宾（观众视角）全量推送
    func didReceiveFullWebinarAttendeeView(meetingId: String, participants: [Participant]) {
        Logger.webinarPanel.info("did receive full \(participants.count)")
        updateParticipantStrategy(full: participants)
        let oldAttendeePanel = attendeePanel
        attendeePanel = .init(participants: participants)
        let modify = prepareDiff(old: oldAttendeePanel, new: participants)
        if !modify.isEmpty {
            updateActivePanel(attendeePanelModify: modify)
            updateWebinarPanelAgg(full: participants)
            listeners.forEach { $0.didChangeWebinarParticipantForAttendee(.init(modify: modify, counts: attendeePanel.toCounts(), newData: attendeePanel, oldData: oldAttendeePanel)) }
            Logger.webinarPanel.info("after diff all attendeePanel, count = \(attendeePanel.count), modify = \(modify)")
        }
    }

    // webinar 嘉宾（观众视角）增量推送
    func didReceiveWebinarAttendeeViewChange(_ message: MeetingParticipantChange) {
        guard isFullParticipantsReceived else { return }
        Logger.webinarPanel.info("change upsert: \(message.upsertParticipants.count), remove: \(message.removeParticipants.count)")
        let (merged, modify) = mergeParticipantChange(for: attendeePanel, change: message)
        updateParticipantStrategy(modify: modify)
        if !modify.isEmpty {
            let oldAttendeePanel = attendeePanel
            attendeePanel = merged
            updateActivePanel(attendeePanelModify: modify)
            updateWebinarPanelAgg(modify: modify)
            listeners.forEach { $0.didChangeWebinarParticipantForAttendee(.init(modify: modify, counts: merged.toCounts(), newData: merged, oldData: oldAttendeePanel)) }
            Logger.webinarPanel.info("after merge all attendeePanel, count = \(attendeePanel.count)")
        }
    }
}

extension InMeetParticipantManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        updateActivePanel(oldMyself: oldValue, mySelf: myself)
    }
}

extension InMeetParticipantManager: SuggestedParticipantsChangedPushObserver {

    func didReceiveChanged(_ changed: InMeetingSuggestedParticipantsChanged) {
        guard meetingId == changed.meetingID else { return }
        pullSuggestionTrigger.excute(())
    }
}

extension InMeetParticipantManager: InMeetingChangedInfoPushObserver {

    func didReceiveInMeetingChangedInfo(_ inMeetingData: InMeetingData) {
        guard inMeetingData.meetingID == meetingId else { return }
        if inMeetingData.type == .webinarAttendeeNumChanged,
            let num = inMeetingData.attendeeNum, num != attendeeNum {
            attendeeNum = num
            listeners.forEach { $0.didChangeWebinarAttendeeNum(num) }
            logger.info("didReceiveInMeetingChangedInfo, attendeeNum = \(num)")
        }
    }
}

// ---- TODO：临时透传方案，待gridDatasource与sorter处理参会人变更的时序依赖被移除后下掉 -----
extension InMeetParticipantManager {

    func addGridParticipantListener(_ listener: GridParticipantAggregatorListener) {
        gridAggregator?.addNormalListener(listener, full: global.all)
    }

    func addGridWebinarAttendeeListener(_ listener: GridParticipantAggregatorListener) {
        gridAggregator?.addAttendeeListener(listener, full: attendeePanel.all)
    }

    func addGridWebinarParticipantListener(_ listener: GridParticipantAggregatorListener) {
        gridAggregator?.addListener(listener)
    }

    private func updateParticipantAgg(full: [Participant]? = nil, modify: InMeetParticipantOutput.Modify? = nil) {
        if let modify = modify {
            if subType == .webinar {
                gridAggregator?.handleParticipantChange(upsertParticipants: upserts(by: modify), removeParticipants: removes(by: modify))
            } else {
                gridAggregator?.transpondParticipantChange(upserts: upserts(by: modify), removes: removes(by: modify))
            }
        } else if let full = full {
            if subType == .webinar {
                gridAggregator?.handleFullParticipants(full)
            } else {
                gridAggregator?.transpondFullParticipants(full)
            }
        }
    }

    private func updateWebinarAttendeeAgg(full: [Participant]? = nil, modify: InMeetParticipantOutput.Modify? = nil) {
        guard subType == .webinar else { return }
        if let modify = modify {
            gridAggregator?.handleAttendeeChange(upsertParticipants: upserts(by: modify), removeParticipants: removes(by: modify))
        } else if let full = full {
            gridAggregator?.handleFullAttendees(full)
        }
    }

    private func updateWebinarPanelAgg(full: [Participant]? = nil, modify: InMeetParticipantOutput.Modify? = nil) {
        guard subType == .webinar else { return }
        if let modify = modify {
            gridAggregator?.transpondAttendeePanelChange(upserts: upserts(by: modify), removes: removes(by: modify))
        } else if let full = full {
            gridAggregator?.transpondFullAttendeePanel(full)
        }
    }

    private func upserts(by modify: InMeetParticipantOutput.Modify) -> [Participant] {
        return modify.ringing.inserts.map(\.value) + modify.ringing.updates.map(\.value) + modify.nonRinging.inserts.map(\.value) + modify.nonRinging.updates.map(\.value)
    }

    private func removes(by modify: InMeetParticipantOutput.Modify) -> [Participant] {
        return modify.ringing.removes.map(\.value) + modify.nonRinging.removes.map(\.value)
    }
}
// -----------------------------------------------------------------------------------
