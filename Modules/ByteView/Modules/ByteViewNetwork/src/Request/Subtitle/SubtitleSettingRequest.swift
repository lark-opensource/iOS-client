//
//  SubtitleSettingRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2022/10/30.
//

import Foundation
import ServerPB

public struct GetSubtitleSettingRequest {
    public static let command: NetworkCommand = .server(.getMeetingSubtitleSetting)
    public typealias Response = GetSubtitleSettingResponse
    public init() { }
}

extension GetSubtitleSettingRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSubtitleSettingRequest

    func toProtobuf() throws -> ServerPB.ServerPB_Videochat_GetSubtitleSettingRequest {
        return ProtobufType()
    }
}

public struct SetSubtitleSettingRequest {
    public static let command: NetworkCommand = .server(.setMeetingSubtitleSetting)
    public typealias Response = SetSubtitleSettingResponse

    public init(on: Bool) {
        self.phraseTranslationOn = on
    }

    public var phraseTranslationOn: Bool
}

extension SetSubtitleSettingRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_SetSubtitleSettingRequest

    func toProtobuf() throws -> ServerPB_Videochat_SetSubtitleSettingRequest {
        var req = ProtobufType()
        req.phraseTranslationOn = self.phraseTranslationOn
        return req
    }
}


public struct GetSubtitleSettingResponse {

    public var status: PhraseTranslationStatus

    public init(status: PhraseTranslationStatus = .unknown) {
        self.status = status
    }

    public enum PhraseTranslationStatus: Int {
        case unknown // 未能成功获取
        case disabled // 不展示勾选项卡
        case on // 开启状态
        case off // 关闭状态
        case unavailable // 置灰
    }
}

extension GetSubtitleSettingResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSubtitleSettingResponse

    init(pb: ServerPB_Videochat_GetSubtitleSettingResponse) throws {
        self.status = PhraseTranslationStatus(rawValue: pb.phraseTranslationStatus.rawValue) ?? .unknown
    }
}

/// 返回更新后的用户设备设置。仅包含请求中非空的设置。
public struct SetSubtitleSettingResponse {
        /// 是否设置成功
    public var success: Bool
}

extension SetSubtitleSettingResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_SetSubtitleSettingResponse

    init(pb: ServerPB_Videochat_SetSubtitleSettingResponse) throws {
        self.success = pb.success
    }
}
