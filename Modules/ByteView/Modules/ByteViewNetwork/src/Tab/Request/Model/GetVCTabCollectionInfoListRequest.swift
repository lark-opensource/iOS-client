//
//  GetVCTabCollectionInfoListRequest.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/6/6.
//

import Foundation
import ServerPB

/// App 启动，以及长连断开后恢复时主动获取独立tab整体未接计数
/// - GET_VC_TAB_COLLECTION_INFO_LIST = 89215
/// - ServerPB_Videochat_tab_v2_GetVCTabCollectionInfoListRequest
public struct GetVCTabCollectionInfoListRequest {
    public static let command: NetworkCommand = .server(.getVcTabCollectionInfoList)
    public typealias Response = GetVCTabCollectionInfoListResponse

    public init(collectionID: String,
                pageNum: Int,
                fromHistoryID: String?) {
        self.collectionID = collectionID
        self.pageNum = pageNum
        self.fromHistoryID = fromHistoryID
    }

    public var collectionID: String

    /// 一页的个数，服务端限制最多200
    public var pageNum: Int

    /// 查询历史记录开始位置，若为空，则服务端认为从头拉取，若有值，则服务端从下一条记录开始返回
    public var fromHistoryID: String?

    /// 格式: “区域/位置”, 例如“Asia/Shanghai”
    public var timeZone: String = TimeZone.current.identifier
}

/// - ServerPB_Videochat_tab_v2_GetVCTabCollectionInfoListResponse
public struct GetVCTabCollectionInfoListResponse {

    public var collectionInfo: CollectionInfo
    /// 是否还有更多记录
    public var hasMore: Bool
    /// 展示最近几个月的数据
    public var monthsLimit: Int
}

extension GetVCTabCollectionInfoListRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_GetVCTabCollectionInfoListRequest
    func toProtobuf() throws -> ServerPB_Videochat_tab_v2_GetVCTabCollectionInfoListRequest {
        var request = ProtobufType()
        request.collectionID = collectionID
        request.pageNum = Int32(pageNum)
        if let fromHistoryID = fromHistoryID {
            request.fromHistoryID = fromHistoryID
        }
        request.timeZone = timeZone
        return request
    }
}

extension GetVCTabCollectionInfoListResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_GetVCTabCollectionInfoListResponse
    init(pb: ServerPB_Videochat_tab_v2_GetVCTabCollectionInfoListResponse) throws {
        self.collectionInfo = pb.collectionInfo.vcType
        self.hasMore = pb.hasMore_p
        self.monthsLimit = Int(pb.monthsLimit)
    }
}
