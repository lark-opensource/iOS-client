//
//  EnterpriseCallParams.swift
//  ByteView
//
//  Created by lutingting on 2023/8/24.
//

import Foundation

struct EnterpriseCallParams: CallEntryParams {

    enum IdType {
        case calleeUserId
        case enterprisePhoneNumber
        case recruitmentPhoneNumber
        case ipPhoneNumber
        case candidateId

        var isPhoneNumber: Bool {
            self == .enterprisePhoneNumber || self == .recruitmentPhoneNumber || self == .ipPhoneNumber
        }
    }

    let id: String
    let idType: IdType
    let source: MeetingEntrySource
    let isJoinMeeting: Bool = false
    let isVoiceCall: Bool = true
    let calleeId: String?
    let calleeName: String?
    let calleeAvatarKey: String?
    let isE2EeMeeting: Bool = false

    var isEnterpriseDirectCall: Bool { source == "enterprise_direct_call" }

    var enterpriseCallUserName: String {
        if let calleeName = calleeName, !calleeName.isEmpty {
            return calleeName
        } else if idType.isPhoneNumber {
            return id
        } else {
            return ""
        }
    }

    // 直呼埋点唯一key
    var enterpriseCallMatchID: String?
    var enterpriseCallStartType: String?

    static func ipPhone(id: String, idType: IdType, calleeId: String?, calleeName: String?, calleeAvatarKey: String?) -> EnterpriseCallParams {
        return EnterpriseCallParams(id: id, idType: idType, source: "ip_phone", calleeId: calleeId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
    }

    static func enterprise(id: String, idType: IdType, calleeId: String?, calleeName: String?, calleeAvatarKey: String?) -> EnterpriseCallParams {
        return EnterpriseCallParams(id: id, idType: idType, source: "enterprise_direct_call", calleeId: calleeId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
    }
}

extension EnterpriseCallParams: CustomStringConvertible {
    var description: String {
        let isPhoneNumber = idType.isPhoneNumber
        let s = "EnterpriseCallParams(id: \(isPhoneNumber ? String(id.hash) : id), idType: \(idType), source: \(source), isVoiceCall: \(isVoiceCall), hasName: \(calleeName != nil), hasAvatar: \(calleeAvatarKey != nil))"
        return s
    }
}
