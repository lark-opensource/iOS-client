//
//  TransitionManager.swift
//  ByteView
//
//  Created by wulv on 2021/8/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

protocol TransitionManagerObserver: AnyObject {
    /// - Parameters:
    ///   - isTransition: 进入转场or离开转场
    ///   - info: 转场信息
    ///   - isFirst: 第一次进入转场or离开转场
    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?)
}

class TransitionManager {

    enum BeginEvent {
        case roomIdChanged(roomId: String?) // 自己的breakoutRoomId改变
        case userLeave // 用户主动离开
        case timerEnd // 停止分组讨论的倒计时结束了
    }

    @RwAtomic
    private var waitBegin: Bool = false
    @RwAtomic
    private var waitEnd: Bool = false
    @RwAtomic
    private var event: BeginEvent?
    private let minTime: TimeInterval = 2
    private var endTimer: Timer?
    private var skipFirst: Bool
    private var isFirst: Bool?
    @RwAtomic
    private var status: (Bool, BreakoutRoomInfo?) = (false, nil)
    var isTransitioning: Bool {
        status.0
    }
    var transitionInfo: BreakoutRoomInfo? {
        status.1
    }
    private let meeting: InMeetMeeting

    init(meeting: InMeetMeeting) {
        Logger.transition.debug("user first roomId: \(meeting.myself.breakoutRoomId)")
        self.meeting = meeting
        self.skipFirst = meeting.data.isOpenBreakoutRoom
        meeting.data.addListener(self)
        meeting.addMyselfListener(self)
    }

    deinit {
        endTimer?.invalidate()
    }

    private let observsers = Listeners<TransitionManagerObserver>()
    func addObserver(_ observer: TransitionManagerObserver) {
        observsers.addListener(observer)
    }

    func needTransition(_ event: BeginEvent) {
        self.event = event
        switch event {
        case .roomIdChanged(let roomId):
            Logger.transition.debug("will transition by id changed: \(roomId)")
            guard meeting.data.isOpenBreakoutRoom else {
                // 数据不完整，等待推送
                Logger.transition.debug("block transition, wait push isOpenBreakoutRoom")
                waitBegin = true
                return
            }
            if let id = roomId, !BreakoutRoomUtil.isMainRoom(id) {
                guard let room = getRoom(by: id) else {
                    // 数据不完整，等待推送
                    Logger.transition.debug("block transition, wait push breakoutroomInfo")
                    waitBegin = true
                    return
                }
                waitBegin = false
                transition(to: room)
            } else {
                waitBegin = false
                transitionToMainRoom()
            }
        case .userLeave:
            Logger.transition.debug("will transition by user leave room")
            waitBegin = false
            transitionToMainRoom()
        case .timerEnd:
            Logger.transition.debug("will transition by timer end")
            waitBegin = false
            transitionToMainRoom()
        }
    }

    private func tryEndTransition() {
        let (has, id) = targetRoomId()
        guard has else {
            Logger.transition.error("transition event not exist")
            return
        }
        guard canEndTransition(for: id) else {
            // 数据不完整，等待推送
            Logger.transition.debug("block end transition, wait push")
            waitEnd = true
            return
        }
        waitEnd = false
        endTransition()
    }

    private func targetRoomId() -> (Bool, String?) {
        guard let event = event else { return (false, nil) }
        let id: String?
        switch event {
        case .roomIdChanged(let roomId):
            id = roomId
        case .userLeave:
            id = BreakoutRoom.mainID
        case .timerEnd:
            id = BreakoutRoom.mainID
        }
        return (true, id)
    }

    private func getRoom(by roomId: String) -> BreakoutRoomInfo? {
        guard let rooms = meeting.data.inMeetingInfo?.breakoutRoomInfos.filter({ [weak self] room in
            return self?.isRoomVaild(room) ?? false
        }) else { return nil }
        return rooms.first(where: { $0.breakoutRoomId == roomId })
    }

    private func canTransition(for room: BreakoutRoomInfo) -> Bool {
        return isRoomVaild(room)
    }

    private func isRoomVaild(_ room: BreakoutRoomInfo) -> Bool {
        let v = !room.channelId.isEmpty
        if !v { Logger.transition.error("transition info invaild: \(room)") }
        return v
    }

    private func canEndTransition(for roomId: String?) -> Bool {
        if let id = roomId, !BreakoutRoomUtil.isMainRoom(id) {
            guard let room = getRoom(by: id) else { return false }
            return isRoomVaild(room)
        } else {
            return BreakoutRoomUtil.isMainRoom(meeting.myself.breakoutRoomId)
        }
    }

    private func transition(to room: BreakoutRoomInfo) {
        guard canTransition(for: room) else {
            Logger.transition.error("transition fail, room = \(room)")
            return
        }
        transition(with: room)
    }

    private func transitionToMainRoom() {
        transition(with: nil)
    }

    private func transition(with info: BreakoutRoomInfo?) {
        guard !isTransitioning else {
            Logger.transition.warn("aleady transition")
            return
        }
        Logger.transition.debug("transition with info: \(info)")
        isFirst = isFirst == nil ? true : false
        Util.runInMainThread {
            self.status = (true, info)
            self.observsers.forEach { $0.transitionStatusChange(isTransition: true, info: info, isFirst: self.isFirst) }
            self.addTimer()
        }
    }

    private func endTransition() {
        guard isTransitioning else {
            Logger.transition.warn("aleady end transition")
            return
        }
        Logger.transition.debug("end transition")
        Util.runInMainThread {
            self.status = (false, self.transitionInfo)
            self.observsers.forEach { $0.transitionStatusChange(isTransition: false,
                                                                info: self.transitionInfo, isFirst: self.isFirst) }
            self.removeTimer()
        }
    }

    private func addTimer() {
        guard endTimer == nil else { return }
        endTimer = Timer.scheduledTimer(withTimeInterval: minTime, repeats: false) { [weak self] _ in
            Logger.transition.debug("will end transition")
            self?.tryEndTransition()
        }
    }

    private func removeTimer() {
        endTimer?.invalidate()
        endTimer = nil
    }

}

// MARK: - InMeetDataListener
extension TransitionManager: InMeetDataListener {

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if waitBegin, case .roomIdChanged(let roomId) = event {
            guard inMeetingInfo.meetingSettings.isOpenBreakoutRoom else {
                Logger.transition.warn("transition fail, isOpen = false")
                return
            }
            guard let id = roomId else {
                Logger.transition.error("transition fail, roomId = nil")
                return
            }

            if let room = getRoom(by: id) {
                waitBegin = false
                transition(to: room)
            }
        }

        if waitEnd {
            tryEndTransition()
        }

        if isTransitioning {
            status = (isTransitioning, meeting.data.breakoutRoomInfo)
        }
    }
}

extension TransitionManager: MyselfListener {

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        guard !skipFirst else {
            skipFirst = false
            return
        }

        if oldValue?.breakoutRoomId != myself.breakoutRoomId {
            needTransition(.roomIdChanged(roomId: myself.breakoutRoomId))
            if waitEnd {
                tryEndTransition()
            }
        }
    }
}
