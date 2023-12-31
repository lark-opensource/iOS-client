//
//  MeetEndReason.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/4/15.
//

import Foundation
import ByteViewNetwork

enum RtcEndEvent: Hashable {
    case sdkError(Int)
    case streamingLost
    case startFailed
    case joinFailed
    case missingData
}

enum ServerBadType: Equatable {
    case createVCError(VCError)
    case acceptError(VCError)
    case heartBeatStopped
}

enum MeetEndReason: Equatable {
    case unknown // 未知

    case timeout // 客户端超时
    case cancel // 主动取消
    case reject // 主动拒绝
    case hangUp(inLobby: Bool = false, isHoldPstn: Bool) // 主动挂断
    case serverBad(ServerBadType) // 服务器出错
    case streamingSDKBad(RtcEndEvent) // 流媒体SDK出错
    case acceptOther // 忙线响铃接听

//    case ringTimeout // 等待接听超时
    case beCancelled // 被（主叫）取消
    case beRejected // 被（被叫）拒绝
    case beHungUp(_ otherID: ParticipantId?) // 被挂断
    case oppositeServerLost(_ otherID: ParticipantId?) // 对方与服务器断开
    case oppositeSDKException(_ otherID: ParticipantId?) // 对方流媒体出错
    case oppositeAcceptOther(_ otherID: ParticipantId?) // 对方忙线响铃接听
    case callException // Applink PSTN呼叫异常

    case trialTimeout(PlanType, isFree: Bool) // 时长耗尽
    case userEnd // 用户结束会议
    case meetingHasFinished // 会议已结束
    case beKickedOut(inLobby: Bool = false) // 被踢出
    case beInterrupted(isHoldPstn: Bool) // 强制中断
    case startAnother(isJoined: Bool) // 发起/加入另一个会议
    case leave // 投屏被抢离会
    case autoEnd // 单人自动结束
    case leaveBecauseUnsafe // 因为设备或者网络不安全，离开会议
    case otherDeviceReplaced // 被其它设备替代入会

    // 客户端自定义错误
    case mediaServiceLost // 媒体服务重启导致CallKit强制退会
}

extension MeetEndReason {
    var showDuration: TimeInterval {
        switch self {
        case .beKickedOut, .streamingSDKBad, .trialTimeout, .mediaServiceLost, .otherDeviceReplaced:
            return TimeInterval(3)
        case let .serverBad(type):
            switch type {
            case .heartBeatStopped:
                return TimeInterval(3)
            default:
                return TimeInterval(1)
            }
        default:
            return TimeInterval(1)
        }
    }
}

extension VideoChatInfo {
    func meetEndReason(account: ByteviewUser) -> MeetEndReason? {
        switch type {
        case .meet:
            guard let reason = participant(byUser: account)?.offlineReason else {
                return nil
            }
            switch reason {
            case .kickOut:
                return .beKickedOut(inLobby: false)
            case .end:
                return .beHungUp(nil)
            case .acceptOther:
                return .oppositeAcceptOther(nil)
            case .overtime:
                let countdown = settings.countdownDuration ?? 0
                return .trialTimeout(settings.planType, isFree: countdown > 0)
            case .leave:
                return .leave
            case .leaveBecauseUnsafe:
                return .leaveBecauseUnsafe
            case .otherDeviceReplaced:
                return .otherDeviceReplaced
            default:
                return nil
            }
        case .call:
            var otherID: ParticipantId?
            if let other = participants.first(where: { $0.user.id != account.id && !$0.user.deviceId.isEmpty }) {
                otherID = ParticipantId(id: other.user.id, type: other.type)
            }
            switch endReason {
            case .unknown:
                return nil
            case .hangUp:
                return .beHungUp(otherID)
            case .connectionFailed:
                return .oppositeServerLost(otherID)
            case .ringTimeout:
                return .timeout
            case .sdkException:
                return .oppositeSDKException(otherID)
            case .cancel:
                return .beCancelled
            case .refuse:
                return .beRejected
            case .acceptOther:
                return .oppositeAcceptOther(otherID)
            case .callException:
                return .callException
            default:
                return .beHungUp(otherID)
            }
        default:
            return nil
        }
    }
}
