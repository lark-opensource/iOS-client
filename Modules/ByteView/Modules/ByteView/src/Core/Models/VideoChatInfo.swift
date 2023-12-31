//
//  VideoChatInfo.swift
//  ByteView
//
//  Created by kiri on 2021/4/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

extension VideoChatInfo {
    var cohost: [Participant] {
        return participants.filter { $0.meetingRole == .coHost }
    }

    static func formatMeetingNumber(_ meetingNumber: String) -> String {
        let s = meetingNumber
        guard s.count >= 9 else {
            return ""
        }
        let index1 = s.index(s.startIndex, offsetBy: 3)
        let index2 = s.index(s.endIndex, offsetBy: -3)
        return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
    }

    var formattedMeetingNumber: String {
        return Self.formatMeetingNumber(meetNumber)
    }

    func participant(byUser user: ByteviewUser) -> Participant? {
        participants.first(where: { $0.user == user })
    }

    func callInType(accountId: String) -> CallInType {
        let callInType: CallInType
        if self.type == .call, let participant = self.participants.first(where: { $0.user.id != accountId }),
           let pstnInfo = participant.pstnInfo {
            switch pstnInfo.pstnSubType {
            case .ipPhone:
                if pstnInfo.bindType == .lark {
                    callInType = .ipPhoneBindLark
                } else {
                    callInType = .ipPhone(pstnInfo.mainAddress)
                }
            case .enterprisePhone:
                let callerName = getCallerName(participant, pstnInfo: pstnInfo)
                callInType = .enterprisePhone(callerName)
            case .recruitmentPhone:
                let callerName = getCallerName(participant, pstnInfo: pstnInfo)
                callInType = .recruitmentPhone(callerName)
            default:
                callInType = .vc
            }
        } else {
            callInType = .vc
        }
        return callInType
    }

    private func getCallerName(_ participant: Participant, pstnInfo: PSTNInfo) -> String {
        let callerName: String
        let nickname = participant.settings.nickname
        if !nickname.isEmpty {
            callerName = nickname
        } else if !pstnInfo.displayName.isEmpty {
            callerName = pstnInfo.displayName
        } else {
            callerName = pstnInfo.mainAddress
        }
        return callerName
    }
}
