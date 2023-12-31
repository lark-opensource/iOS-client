//
//  StartCallParams.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation

public struct StartCallParams: CallEntryParams {
    enum IdType {
        case userId
        case reservationId
    }
    let id: String
    let idType: IdType
    let source: MeetingEntrySource
    let isJoinMeeting: Bool
    let isVoiceCall: Bool
    let secureChatId: String
    let isE2EeMeeting: Bool
    let onError: ((StartCallError) -> Void)?

    static func openPlatform(id: String, isVoiceCall: Bool) -> StartCallParams {
        StartCallParams(id: id, idType: .reservationId, source: .openPlatform1v1, isJoinMeeting: true, isVoiceCall: isVoiceCall, secureChatId: "", isE2EeMeeting: false, onError: nil)
    }

    static func call(id: String, source: MeetingEntrySource, isVoiceCall: Bool = false, secureChatId: String = "",
                     isE2EeMeeting: Bool, onError: ((StartCallError) -> Void)? = nil) -> StartCallParams {
        StartCallParams(id: id, idType: .userId, source: source, isJoinMeeting: false, isVoiceCall: isVoiceCall, secureChatId: secureChatId, isE2EeMeeting: isE2EeMeeting, onError: onError)
    }
}


extension StartCallParams: CustomStringConvertible {
    public var description: String {
        let s = "StartCallParams(id: \(id), idType: \(idType), source: \(source), isVoiceCall: \(isVoiceCall), secureChatId: \(secureChatId), hasFailHandler: \(onError != nil))"
        return s
    }
}

public enum StartCallError: Error, Equatable {
    /// 屏蔽对方
    case collaborationBlocked
    /// 被屏蔽
    case collaborationBeBlocked
    /// 无权限
    case collaborationNoRights
    case otherError
}
