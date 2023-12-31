//
//  UpdateSubtitleLanguageRequest.swift
//  ByteViewNetwork
//
//  Created by wulv on 2023/3/14.
//

import Foundation
import ServerPB

/// 会前修改字幕翻译语言 UPDATE_SUBTITLE_LANGUAGE = 89472
/// - ServerPB_Videochat_UpdateSubtitleLanguageRequest
public struct UpdateSubtitleLanguageRequest {
    public static let command: NetworkCommand = .server(.updateSubtitleLanguage)
    public typealias Response = UpdateSubtitleLanguageResponse

    public init(subtitleLanguage: SubtitleLanguage) {
        self.subtitleLanguage = subtitleLanguage
    }

    public var subtitleLanguage: SubtitleLanguage

    public struct SubtitleLanguage {
        public var language: String

        public init(language: String) {
            self.language = language
        }
    }
}


public struct UpdateSubtitleLanguageResponse {
    public var status: Status

    public enum Status: Int, Hashable {
        case unknown // = 0
        case success // = 1
        case fail // = 2
    }
}

extension UpdateSubtitleLanguageRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_UpdateSubtitleLanguageRequest
    typealias PBSubtitleLanguage = ServerPB_Videochat_UpdateSubtitleLanguageRequest.SubtitleLanguage
    func toProtobuf() throws -> ServerPB_Videochat_UpdateSubtitleLanguageRequest {
        var request = ProtobufType()
        var pbLanguage = PBSubtitleLanguage()
        pbLanguage.language = subtitleLanguage.language
        request.subtitleLanguage = pbLanguage
        return request
    }
}

extension UpdateSubtitleLanguageResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_UpdateSubtitleLanguageResponse
    init(pb: ServerPB_Videochat_UpdateSubtitleLanguageResponse) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
    }
}
