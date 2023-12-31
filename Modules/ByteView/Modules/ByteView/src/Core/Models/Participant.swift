//
//  Participant.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/12/13.
//

import Foundation
import ByteViewNetwork
import ByteViewRtcBridge

extension Participant {
    var rtcUid: RtcUID {
        rtcJoinId.isEmpty ? RtcUID(user.deviceId) : RtcUID(self.rtcJoinId)
    }
}

extension Participant.CallMeInfo {
    var rtcUID: RtcUID {
        RtcUID(callMeRtcJoinID)
    }
}

extension UserRTCNetStatus {
    var rtcUID: RtcUID {
        RtcUID(rtcJoinId)
    }
}

extension Participant {
    var isMicHandsUp: Bool {
        settings.handsStatus == .putUp
    }

    var isCameraHandsUp: Bool {
        settings.cameraHandsStatus == .putUp
    }

    var isLocalRecordHandsUp: Bool {
        settings.localRecordSettings?.localRecordHandsStatus == .putUp
    }

    var isCoHost: Bool {
        meetingRole == .coHost
    }

    var isRing: Bool {
        status == .ringing
    }

    var isInterpreter: Bool {
        settings.interpreterSetting?.isUserConfirm ?? false
    }

    // 判断是否是 External 参会人
    // 详细参见：https://bytedance.feishu.cn/docs/doccndN4VK3AYa6XK1VZfpBumQc#
    func isExternal(localParticipant: Participant?) -> Bool {
        guard let localParticipant = localParticipant else { return false }

        if user == localParticipant.user { // 本地用户
            return false
        }

        if localParticipant.tenantTag != .standard { // 自己是小 B 用户，则不关注 external
            return false
        }

        // 自己或者别人是 Guest，都不展示外部标签
        if localParticipant.isLarkGuest || isLarkGuest {
            return false
        }

        // 该用户租户 ID 未知
        if tenantId == "" || tenantId == "-1" {
            return false
        }

        if type == .larkUser || type == .room || type == .neoUser || type == .neoGuestUser || type == .standaloneVcUser || (type == .pstnUser && pstnInfo?.bindType == .lark) {
            return tenantId != localParticipant.tenantId
        } else {
            return false
        }
    }

    func isSameWith(rtcUid: RtcUID) -> Bool {
        return self.rtcUid == rtcUid
//        return self.rtcJoinId == rtcUid || (self.rtcJoinId.isEmpty && (self.user.id == rtcUid || self.deviceId == rtcUid))
    }
}

extension Array where Element == Participant {

    ///当前为onthecall状态的参会人
    var onTheCall: [Participant] {
        return filter({ $0.status == .onTheCall })
    }

    var ringing: [Participant] {
        return filter({ $0.status == .ringing })
    }

    var nonRinging: [Participant] {
        return filter({ $0.status != .ringing })
    }

    //未离会的同传参会人
    var onTheCallInterpreter: [Participant] {
        return filter({ $0.settings.interpreterSetting?.userIsOnTheCall ?? false })
    }

    /// 正在举手申请发言的人
    var micHandsUp: [Participant] {
        return filter({ $0.isMicHandsUp })
    }

    /// 正在举手申请打开摄像头的人
    var cameraHandsUp: [Participant] {
        return filter({ $0.isCameraHandsUp })
    }

    /// 正在举手申请打开本地录制的人
    var localRecordHandsUp: [Participant] {
        return filter({ $0.isLocalRecordHandsUp })
    }

    //状态表情正在举手的人
    var statusHandsUp: [Participant] {
        return filter({ $0.settings.conditionEmojiInfo?.isHandsUp ?? false })
    }
}

extension Array where Element == Participant {

    func first(withUser user: ByteviewUser) -> Element? {
        return first { $0.user == user }
    }

    func first(withRtcUid uid: RtcUID) -> Element? {
        return first { $0.rtcUid == uid }
    }
}
