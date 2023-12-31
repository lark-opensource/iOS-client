//
//  StartMeetingBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

/// 发起会议, /client/byteview/startmeeting
public struct StartMeetingBody: CodablePathBody {
    public static let path: String = "/client/byteview/startmeeting"

    // 发起会议入口
    public var entrySource: VCMeetingEntry

    // 发起1v1
    public var userId: String?
    public var secureChatId: String = ""
    public var isCall: Bool = false
    public var isVoiceCall: Bool?
    public var isE2Ee: Bool = false

    // 通过开放平台开启1v1会议
    public var uniqueId: String?

    public init(entrySource: VCMeetingEntry) {
        self.entrySource = entrySource
    }

    public init(userId: String, secureChatId: String = "", isVoiceCall: Bool, entrySource: VCMeetingEntry, isE2Ee: Bool = false) {
        self.userId = userId
        self.secureChatId = secureChatId
        self.isCall = true
        self.isVoiceCall = isVoiceCall
        self.entrySource = entrySource
        self.isE2Ee = isE2Ee
    }

    public init(uniqueId: String, isVoiceCall: Bool, entrySource: VCMeetingEntry, isE2Ee: Bool) {
        self.uniqueId = uniqueId
        self.isCall = true
        self.isVoiceCall = isVoiceCall
        self.entrySource = entrySource
        self.isE2Ee = isE2Ee
    }
}

extension StartMeetingBody: CustomStringConvertible {
    public var description: String {
        "StartMeetingBody(userId: \(userId ?? ""), hasSecureChatId: \(!secureChatId.isEmpty), entrySource: \(entrySource), isCall: \(isCall), isVoiceCall: \(String(describing: isVoiceCall)), isE2Ee: \(isE2Ee), uniqueId: \(uniqueId ?? ""))"
    }
}
