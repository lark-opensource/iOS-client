//
//  GetVCTabHistoryListResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 获取历史会议，展示在独立tab列表页
/// - GET_VC_TAB_HISTORY_LIST = 89208
/// - Videoconference_V1_GetVCTabHistoryListRequest
public struct GetTabHistoryListRequest {
    public static let command: NetworkCommand = .rust(.getVcTabHistoryList)
    public typealias Response = GetTabHistoryListResponse
    public static let defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public init(historyId: String?, maxNum: Int64?, supportCal: Bool) {
        self.historyId = historyId
        self.maxNum = maxNum
        self.supportCal = supportCal
    }

    /// 查询历史记录开始位置，若为空，则服务端认为从头拉取，若有值，则服务端从下一条记录开始返回
    public var historyId: String?

    /// 最大查询数量，后端默认上限200，超出200时只返回200条记录
    public var maxNum: Int64?

    /// 是否支持 未加入，未被呼叫，但因为未拒绝日程而看到的会议展示
    public var supportCal: Bool

    public var timeZone: String = TimeZone.current.identifier
}

/// Videoconference_V1_GetVCTabHistoryListResponse
public struct GetTabHistoryListResponse: CustomStringConvertible {

    /// 历史视频会议记录
    public var items: [TabListItem]

    /// 是否还有更多记录
    public var hasMore: Bool

    /// 对应的 groot 下行版本号
    public var downVersion: Int32

    public var description: String {
        String(indent: "GetTabHistoryListResponse",
               "items: \(items.map({ $0.historyID }))",
               "hasMore: \(hasMore)",
               "downVersion: \(downVersion)")
    }
}

extension GetTabHistoryListRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVCTabHistoryListRequest
    func toProtobuf() throws -> Videoconference_V1_GetVCTabHistoryListRequest {
        var request = ProtobufType()
        if let historyId = historyId {
            request.historyID = historyId
        }
        if let maxNum = maxNum {
            request.maxNum = maxNum
        }
        request.timeZone = timeZone
        request.supportCal = supportCal
        return request
    }
}

extension GetTabHistoryListResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVCTabHistoryListResponse
    init(pb: Videoconference_V1_GetVCTabHistoryListResponse) throws {
        self.items = pb.items.map({ $0.vcType })
        self.hasMore = pb.hasMore_p
        self.downVersion = pb.downVersion
    }
}
