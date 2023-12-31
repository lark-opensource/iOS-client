//
//  ExportVoteStatisticsRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/21.
//

import Foundation
import ServerPB

/// 独立tab生成投票统计表格
/// EXPORT_VOTE_STATISTICS = 89523
/// ServerPB_Videochat_vote_ExportVoteStatisticsRequest
public struct ExportVoteStatisticsRequest {
    public static let command: NetworkCommand = .server(.exportVoteStatistics)

    public init(meetingID: String, isTwelveHourTime: Bool, locale: String) {
        self.meetingID = meetingID
        self.isTwelveHourTime = isTwelveHourTime
        self.locale = locale
        self.timeZone = TimeZone.current.identifier
    }

    public var meetingID: String

    /// 格式: “区域/位置”, 例如“Asia/Shanghai”
    public var timeZone: String

    /// true: 12小时制，  false: 24小时制
    public var isTwelveHourTime: Bool

    /// 客户端语言
    public var locale: String
}

extension ExportVoteStatisticsRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_vote_ExportVoteStatisticsRequest
    func toProtobuf() throws -> ServerPB_Videochat_vote_ExportVoteStatisticsRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.timeZone = timeZone
        request.isTwelveHourTime = isTwelveHourTime
        request.locale = locale
        return request
    }
}
