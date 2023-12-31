//
//  NotesManageRequest.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation
import ServerPB

/// Command_NOTES_MANAGE = 89560
/// ServerPB_Videochat_notes_NotesManageRequest
public struct NotesManageRequest {

    public static let command: NetworkCommand = .server(.notesManage)
    public typealias Response = NotesManageResponse

    public init(action: Action,
                meetingID: String,
                createInfo: CreateInfo) {
        self.action = action
        self.meetingID = meetingID
        self.createInfo = createInfo
    }

    public var action: Action

    public var meetingID: String

    public var createInfo: CreateInfo

    public enum Action: Int {
        case unknown // = 0
        case create // = 1
    }

    public struct CreateInfo: CustomStringConvertible {
        /// 模板ID
        public var templateId: String
        /// 模板Token
        public var templateToken: String
        /// 语言
        public var locale: String
        /// 格式: “区域/位置”, 例如“Asia/Shanghai”
        public var timeZone: String

        public init(templateToken: String,
                    templateId: String,
                    locale: String,
                    timeZone: String) {
            self.templateToken = templateToken
            self.templateId = templateId
            self.locale = locale
            self.timeZone = timeZone
        }

        public var pbType: ServerPB_Videochat_notes_NotesManageRequest.CreateInfo {
            var pbType = ServerPB_Videochat_notes_NotesManageRequest.CreateInfo()
            pbType.templateToken = templateToken
            pbType.templateID = Int64(templateId) ?? 0
            pbType.locale = locale
            pbType.timeZone = timeZone
            return pbType
        }

        public var description: String {
            String(indent: "CreateInfo",
                   "templateToken.hash: \(templateToken.hashValue)",
                   "templateId.hash: \(templateId.hashValue)",
                   "locale: \(locale)",
                   "timeZone: \(timeZone)")
        }
    }

}

public struct NotesManageResponse {}

extension NotesManageRequest: RustRequestWithResponse, CustomStringConvertible {

    typealias ProtobufType = ServerPB_Videochat_notes_NotesManageRequest

    func toProtobuf() throws -> ServerPB_Videochat_notes_NotesManageRequest {
        var request = ProtobufType()
        request.action = ServerPB_Videochat_notes_NotesManageRequest.Action(rawValue: action.rawValue) ?? .unknown
        request.meetingID = meetingID
        request.createInfo = createInfo.pbType
        return request
    }

    public var description: String {
        String(indent: "NotesManageRequest",
               "action: \(action.rawValue)",
               "meetingId: \(meetingID)",
               "createInfo: \(createInfo)")
    }

}

extension NotesManageResponse: RustResponse {

    typealias ProtobufType = ServerPB_Videochat_notes_NotesManageResponse

    init(pb: ServerPB_Videochat_notes_NotesManageResponse) throws {}

}
