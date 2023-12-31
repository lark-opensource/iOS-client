//
//  GetSubtitleLanguageRequest.swift
//  ByteViewNetwork
//
//  Created by wulv on 2023/3/16.
//

import Foundation
import ServerPB

/// 会前获取字幕翻译语言 GET_SUBTITLE_LANGUAGE = 89471
/// - ServerPB_Videochat_UpdateSubtitleLanguageRequest
public struct GetSubtitleLanguageRequest {
    public static let command: NetworkCommand = .server(.getSubtitleLanguage)
    public typealias Response = GetSubtitleLanguageResponse

    public init() {}
}


public struct GetSubtitleLanguageResponse: Equatable {

    public var subtitleLanguage: SubtitleLanguage

    public struct SubtitleLanguage: Equatable {
        public var language: String

        public init(language: String) {
            self.language = language
        }
    }

    public var status: Status

    public enum Status: Int, Hashable {
        case unknown // = 0
        case success // = 1
        case fail // = 2
    }
}

extension GetSubtitleLanguageRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSubtitleLanguageRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetSubtitleLanguageRequest {
        ProtobufType()
    }
}

extension GetSubtitleLanguageResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetSubtitleLanguageResponse
    init(pb: ServerPB_Videochat_GetSubtitleLanguageResponse) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
        if !pb.subtitleLanguage.hasLanguage {
            self.subtitleLanguage = SubtitleLanguage(language: "")
        } else {
            self.subtitleLanguage = SubtitleLanguage(language: pb.subtitleLanguage.language)
        }
    }
}
