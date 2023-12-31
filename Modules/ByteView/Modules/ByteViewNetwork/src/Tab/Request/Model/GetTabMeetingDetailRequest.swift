//
//  GetTabMeetingDetailResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 指定historyID, 获取会议详情
/// - GET_VC_TAB_MEETING_DETAIL = 89209
/// - Videoconference_V1_GetVCTabMeetingDetailRequest
public struct GetTabMeetingDetailRequest {
    public static let command: NetworkCommand = .rust(.getVcTabMeetingDetail)
    public typealias Response = GetTabMeetingDetailResponse
    public static let defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public init(historyId: String, queryType: QueryType, source: Source) {
        self.historyId = historyId
        self.queryType = queryType
        self.source = source
    }

    /// 需要获取详情的ID, 根据DetailQueryType取值不同代表不同含义
    public var historyId: String

    public var queryType: QueryType

    public var source: Source

    /// 格式: “区域/位置”, 例如“Asia/Shanghai”
    public var timeZone: String = TimeZone.current.identifier

    public enum Source: Int {

        case unknown // = 0

        /// 通过未接来电提醒bot跳转
        case fromBot // = 1

        /// 通过合集列表跳转
        case fromCollection // = 2
    }

    public enum QueryType: Int {

        /// 通过 historyID 获取详情页信息
        case historyID // = 0

        /// 通过 meetingID 获取详情页信息
        case meetingID // = 1
    }
}

/// 会议详情页完整数据
/// - Videoconference_V1_GetVCTabMeetingDetailResponse
public struct GetTabMeetingDetailResponse {

    public var historyID: String

    public var infos: [TabMeetingAbbrInfo]

    /// 9位会议号, 若没有则不展示
    public var meetingNumber: String

    /// 会议链接，若没有则不展示
    public var meetingURL: String

    /// 会议相关入会渠道信息，不用再去查询admin也不用判断featureConfig, 没有值的时候不显示
    public var accessInfos: TabAccessInfos

    /// 日程会议循环相关信息，若为空则不展示，否则端上解析展示循环信息
    public var calendarEventRule: String
}

extension GetTabMeetingDetailRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVCTabMeetingDetailRequest
    func toProtobuf() throws -> Videoconference_V1_GetVCTabMeetingDetailRequest {
        var request = ProtobufType()
        request.historyID = historyId
        request.queryType = queryType.pbType
        request.source = source.pbType
        request.timeZone = timeZone
        return request
    }
}

extension GetTabMeetingDetailResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVCTabMeetingDetailResponse
    init(pb: Videoconference_V1_GetVCTabMeetingDetailResponse) throws {
        self.historyID = pb.historyID
        self.infos = pb.infos.map({ $0.vcType })
        self.meetingNumber = pb.meetingNumber
        self.meetingURL = pb.meetingURL
        self.accessInfos = pb.accessInfos.vcType
        self.calendarEventRule = pb.calendarEventRrule
    }
}

extension GetTabMeetingDetailRequest.QueryType {
    var pbType: Videoconference_V1_DetailQueryType {
        switch self {
        case .historyID: return .historyID
        case .meetingID: return .meetingID
        }
    }
}

extension GetTabMeetingDetailRequest.Source {
    var pbType: Videoconference_V1_GetVCTabMeetingDetailRequest.Source {
        switch self {
        case .unknown: return .unknown
        case .fromBot: return .fromBot
        case .fromCollection: return .fromCollection
        }
    }
}
