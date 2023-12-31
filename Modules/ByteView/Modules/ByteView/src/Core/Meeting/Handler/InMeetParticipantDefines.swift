//
//  InMeetParticipantDefines.swift
//  ByteView
//
//  Created by wulv on 2023/3/30.
//

import Foundation
import ByteViewNetwork

protocol InMeetParticipantListener: AnyObject {
    /// 参会人变更（分组会议时，回调同会的参会人）
    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput)
    /// 参会人变更（分组会议时，仅回调同组的参会人，output也仅限同组参会人）
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput)
    /// 1v1对方的回调，只在call状态下回调
    func didChangeAnotherParticipant(_ participant: Participant?)
    /// 当前正在聚焦观看的参会人的回调，考虑了「我被设为焦点」、「我是主共享人」等业务逻辑
    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?)
    /// 建议人员/拒绝日程人员
    func didReceiveSuggestedParticipants(_ suggested: GetSuggestedParticipantsResponse)
    /// 绑定的用户变了，晚于myself变更
    func didChangeMyselfBinder(_ participant: Participant?, oldValue: Participant?)

    // --- webianr ---
    /// 观众人数变化，与观众变更同时推时，回调时序先于 didChangeWebinarAttendees()
    func didChangeWebinarAttendeeNum(_ num: Int64)
    /// 观众变更（嘉宾视角）
    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput)
    /// 嘉宾变更（观众视角）
    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput)
}

extension InMeetParticipantListener {
    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {}
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {}
    func didChangeAnotherParticipant(_ participant: Participant?) {}
    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {}
    func didReceiveSuggestedParticipants(_ suggested: GetSuggestedParticipantsResponse) {}
    func didChangeMyselfBinder(_ participant: Participant?, oldValue: Participant?){}

    func didChangeWebinarAttendeeNum(_ num: Int64) {}
    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {}
    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {}
}

struct ParticipantData {

    private(set) var ringingDict: [ByteviewUser: Participant]
    /// 目前等价于onTheCall
    private(set) var nonRingingDict: [ByteviewUser: Participant]
    init(ringingDict: [ByteviewUser: Participant] = [:], nonRingingDict: [ByteviewUser: Participant] = [:]) {
        self.ringingDict = ringingDict
        self.nonRingingDict = nonRingingDict
    }

    init(participants: [Participant]) {
        self.ringingDict = [:]
        self.nonRingingDict = [:]
        participants.forEach {
            if $0.status == .ringing {
                ringingDict[$0.user] = $0
            } else {
                nonRingingDict[$0.user] = $0
            }
        }
    }

    var all: [Participant] { ringingDict.map(\.value) + nonRingingDict.map(\.value) }
    var count: Int { ringingCount + nonRingingCount }
    var ringingCount: Int { ringingDict.count }
    var nonRingingCount: Int { nonRingingDict.count }
    var isEmpty: Bool { nonRingingDict.isEmpty && ringingDict.isEmpty }

    private var defaultModify: InMeetParticipantOutput.Modify {
        .init(ringing: .init(inserts: ringingDict), nonRinging: .init(inserts: nonRingingDict))
    }

    var defaultChange: InMeetParticipantOutput {
        .init(modify: defaultModify, counts: toCounts(), newData: self, oldData: .init())
    }

    mutating func update(with modify: InMeetParticipantOutput.Modify) {
        ringingDict += modify.ringing.inserts
        ringingDict += modify.ringing.updates
        ringingDict -= modify.ringing.removes
        nonRingingDict += modify.nonRinging.inserts
        nonRingingDict += modify.nonRinging.updates
        nonRingingDict -= modify.nonRinging.removes
    }

    /// 只对满足条件的子集删除
    mutating func update(with modify: InMeetParticipantOutput.Modify, removeCondition: @escaping (Participant) -> Bool) {
        ringingDict += modify.ringing.inserts
        ringingDict += modify.ringing.updates
        nonRingingDict += modify.nonRinging.inserts
        nonRingingDict += modify.nonRinging.updates
        let removes: ([ByteviewUser: Participant], inout [ByteviewUser: Participant]) -> Void = { modify, dict in
            modify.forEach {
                if let p = dict[$0.key], removeCondition(p) {
                    dict.removeValue(forKey: $0.key)
                }
            }
        }
        removes(modify.ringing.removes, &ringingDict)
        removes(modify.nonRinging.removes, &nonRingingDict)
    }

    func filter(_ isIncluded: (Dictionary<ByteviewUser, Participant>.Element) -> Bool) -> ParticipantData {
        return .init(ringingDict: ringingDict.filter { isIncluded($0) }, nonRingingDict: nonRingingDict.filter { isIncluded($0) })
    }

    func filterSameRoom(_ breakoutRoomId: String) -> ParticipantData {
        filter { $0.value.isInBreakoutRoom(breakoutRoomId) }
    }

    func toCounts() -> InMeetParticipantOutput.Counts {
        return .init(ringing: ringingCount, nonRinging: nonRingingCount)
    }

    static func + (lhs: ParticipantData, rhs: ParticipantData) -> ParticipantData {
        return .init(ringingDict: lhs.ringingDict + rhs.ringingDict, nonRingingDict: lhs.nonRingingDict + rhs.nonRingingDict)
    }
}

struct InMeetParticipantOutput {

    struct Changes {
        /// 增加(非idle)
        let inserts: [ByteviewUser: Participant]
        /// 更新(非idle)
        let updates: [ByteviewUser: Participant]
        /// 删除(含idle)
        fileprivate(set) var removes: [ByteviewUser: Participant]
        init(inserts: [ByteviewUser: Participant] = [:], updates: [ByteviewUser: Participant] = [:], removes: [ByteviewUser: Participant] = [:]) {
            self.inserts = inserts
            self.updates = updates
            self.removes = removes
        }

        var isEmpty: Bool { inserts.isEmpty && updates.isEmpty && removes.isEmpty }
    }

    struct Modify {
        private(set) var ringing: Changes // removes 中包含拒接用户的信息
        private(set) var nonRinging: Changes
        var isEmpty: Bool { ringing.isEmpty && nonRinging.isEmpty }

        func filterSameRoom(_ breakoutRoomId: String) -> InMeetParticipantOutput.Modify {
            return .init(ringing: .init(inserts: ringing.inserts.filter { $0.value.isInBreakoutRoom(breakoutRoomId) },
                                        updates: ringing.updates.filter { $0.value.isInBreakoutRoom(breakoutRoomId) },
                                        removes: ringing.removes.filter { $0.value.isInBreakoutRoom(breakoutRoomId) }),
                         nonRinging: .init(inserts: nonRinging.inserts.filter { $0.value.isInBreakoutRoom(breakoutRoomId) },
                                           updates: nonRinging.updates.filter { $0.value.isInBreakoutRoom(breakoutRoomId) },
                                           removes: nonRinging.removes.filter { $0.value.isInBreakoutRoom(breakoutRoomId) }))
        }

        mutating func mergeRemoves(with mdf: InMeetParticipantOutput.Modify) {
            ringing.removes += mdf.ringing.removes
            nonRinging.removes += mdf.nonRinging.removes
        }
    }

    struct Counts {
        let ringing: Int
        let nonRinging: Int
    }

    let modify: Modify
    let counts: Counts
    let newData: ParticipantData
    let oldData: ParticipantData
    init(modify: Modify, counts: Counts, newData: ParticipantData, oldData: ParticipantData) {
        self.modify = modify
        self.counts = counts
        self.newData = newData
        self.oldData = oldData
    }

    /// 数据源总数
    /// 注意：webinar观众数据非全量，观众人数应使用participantManager.attendeeNum
    var sumCount: Int { counts.ringing + counts.nonRinging }
}

extension Dictionary where Key == ByteviewUser, Value == Participant {

    /// 性能不好，慎用
    fileprivate static func + (lhs: Dictionary, rhs: Dictionary) -> Dictionary {
        return lhs.merging(rhs, uniquingKeysWith: { $1 })
    }

    /// 性能不好，慎用
    fileprivate static func += (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs, uniquingKeysWith: { $1 })
    }

    static func - (lhs: Dictionary, rhs: Dictionary) -> Dictionary {
        var result = lhs
        rhs.forEach { result.removeValue(forKey: $0.key) }
        return result
    }

    static func -= (lhs: inout Dictionary, rhs: Dictionary) {
        rhs.forEach { lhs.removeValue(forKey: $0.key) }
    }
}

// MARK: - log info
extension InMeetParticipantOutput.Changes: CustomStringConvertible {
    var description: String { "insert: \(inserts.count), update: \(updates.count), remove: \(removes.count)" }
}

extension ParticipantData: CustomStringConvertible {
    var description: String { "ringings: \(ringingCount), nonRingings: \(nonRingingCount)" }
}
