//
//  GetVideoChatOrderRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/12/6.
//

import Foundation
import RustPB

/// 拉取接口，拉取[index_begin, index_end]的顺序信息
/// 设置视频观看顺序 command: GET_VIDEO_CHAT_ORDER = 89315
/// Videoconference_V1_GetVideoChatOrderRequest
public struct GetVideoChatOrderRequest {
    public typealias Response = GetVideoChatOrderResponse
    public static let command: NetworkCommand = .rust(.getVideoChatOrder)

    public init(meetingID: String, needFullData: Bool, indexBegin: Int32 = 0, indexEnd: Int32 = 100, clientVersionID: Int64 = 0) {
        self.meetingID = meetingID
        self.indexBegin = indexBegin
        self.indexEnd = indexEnd
        self.needFullData = needFullData
        self.clientVersionID = clientVersionID
    }

    /// 会议id
    public var meetingID: String

    /// 拉取开始序号，index从0开始，begin和end都是闭区间
    public var indexBegin: Int32

    /// 拉取结束序号
    public var indexEnd: Int32

    /// 拉全量
    public var needFullData: Bool

    /// 指示客户端要拉取的顺序信息是哪个版本的
    public var clientVersionID: Int64
}

/// Videoconference_V1_GetVideoChatOrderResponse
public struct GetVideoChatOrderResponse {
    public var videoChatDisplayOrderInfo: VideoChatDisplayOrderInfo
}

extension GetVideoChatOrderRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVideoChatOrderRequest
    func toProtobuf() throws -> Videoconference_V1_GetVideoChatOrderRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.indexBegin = indexBegin
        request.indexEnd = indexEnd
        request.needFullData = needFullData
        request.clientVersionID = clientVersionID
        return request
    }
}

extension GetVideoChatOrderResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVideoChatOrderResponse
    init(pb: Videoconference_V1_GetVideoChatOrderResponse) throws {
        self.videoChatDisplayOrderInfo = pb.videoChatDisplayOrderInfo.vcType
    }
}
