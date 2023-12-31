//
//  ParticipantsSort.swift
//  ByteView
//
//  Created by admin on 2022/7/26.
//

import Foundation
import RustPB

protocol ParticipantInfoForSortType {
    var isHost: Bool { get }
    var isCoHost: Bool { get }
    var deviceID: String { get }
    var isRing: Bool { get }
    var isMicHandsUp: Bool { get }
    var isCameraHandsUp: Bool { get }
    var isLocalRecordHandsUp: Bool { get }
    var micHandsUpTime: Int64 { get }
    var cameraHandsUpTime: Int64 { get }
    var localRecordHandsUpTime: Int64 { get }
    var joinTime: Int64 { get }
    var sortName: String { get }
    var user: ByteviewUser { get }
    var isInterpreter: Bool { get }
    var interpreterConfirmTime: Int64 { get }
    var isMicrophoneOn: Bool { get }
    var isFocusing: Bool { get }
    var hasHandsUpEmoji: Bool { get }
    var statusEmojiHandsUpTime: Int64 { get }
    var isExternal: Bool { get }
    var isSharer: Bool { get }
}

enum ParticipantsSortTool {
    static func partitionAndSort<T: ParticipantInfoForSortType>(_ participantInfos: [T], currentUser: ByteviewUser?) -> [T] {
        guard let currentUser = currentUser else {
            return participantInfos
        }

        typealias Rules = (T) -> Bool

        let rules: [Rules] = [
            // 排除主持人和自己的ringing成员
            { $0.isRing && !$0.isHost },
            // 自己
            { $0.user == currentUser },
            // 主持人且不为自己
            { $0.isHost },
            // 有举手行为的人，依次为举手发言、举手开麦、状态表情举手
            { $0.isMicHandsUp },
            { $0.isCameraHandsUp },
            { $0.isLocalRecordHandsUp },
            { $0.hasHandsUpEmoji },
            // 共享人
            { $0.isSharer },
            // 无状态表情的联席主持人且不为自己
            { $0.isCoHost },
            // 焦点视频不是联席主持人要放在联席主持人后最前，如果多个联席主持人有焦点视频，放在联席主持人列表最前
            { $0.isFocusing },
            // 传译员
            { $0.isInterpreter },
            // 开麦
            { $0.isMicrophoneOn },
            // 非外部用户
            { !$0.isExternal }
            // 其他
        ]

        var results = [[T]](repeating: [], count: rules.count + 1)
        participantInfos.forEach { participantInfo in
            let i: Int
            if let index = rules.firstIndex(where: { $0(participantInfo) }), index >= 0 && index < rules.count {
                i = index
            } else {
                i = rules.count
            }
            results[i].append(participantInfo)
        }

        let sorted = results.flatMap { sort($0) }
        return sorted
    }

    static func sort<T: ParticipantInfoForSortType>(_ participantInfos: [T]) -> [T] {
        let users = participantInfos
        var sorted: [T] = []
        let sortedUsers = users.sorted { (firP, secP) -> Bool in
            switch (firP.isFocusing, secP.isFocusing) {
            case (true, false):
                return true
            case (false, true):
                return false
            default:
                break
            }
            if firP.isMicHandsUp && secP.isMicHandsUp {
                return firP.micHandsUpTime < secP.micHandsUpTime
            } else if firP.isCameraHandsUp && secP.isCameraHandsUp {
                return firP.cameraHandsUpTime < secP.cameraHandsUpTime
            } else if firP.isLocalRecordHandsUp && secP.isLocalRecordHandsUp {
                return firP.localRecordHandsUpTime < secP.localRecordHandsUpTime
            } else if firP.hasHandsUpEmoji && secP.hasHandsUpEmoji {
                return firP.statusEmojiHandsUpTime < secP.statusEmojiHandsUpTime
            } else if firP.isInterpreter && secP.isInterpreter {
                return firP.interpreterConfirmTime < secP.interpreterConfirmTime
            } else if firP.isRing || firP.sortName.lowercased() == secP.sortName.lowercased() {
                return firP.joinTime < secP.joinTime
            } else {
                return firP.sortName.lowercased() < secP.sortName.lowercased()
            }
        }
        sorted.append(contentsOf: sortedUsers)
        return sorted
    }
}
