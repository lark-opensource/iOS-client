//
//  QueryDocsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_VcQueryDocsRequest
public struct QueryDocsRequest {
    public static let command: NetworkCommand = .rust(.vcQueryDocs)
    public typealias Response = QueryDocsResponse

    public init(query: String, limit: Int32, offset: Int32, source: QuerySource, opts: QueryOpts = .init()) {
        self.query = query
        self.limit = limit
        self.offset = offset
        self.source = source
        self.opts = opts
    }

    public var query: String

    public var limit: Int32

    public var offset: Int32

    public var source: QuerySource

    public var opts: QueryOpts

    /// 接口调用所在页面，用于返回不同的图标url
    public enum QuerySource: Int, Equatable {

        /// magic share展示所有共享类型的页面
        case allPage = 1

        /// magic share妙享页面
        case magicSharePage // = 2

        /// magic share搜索下拉列表页面
        case searchListPage // = 3
    }

    public struct QueryOpts {
        public init() { }

        public var meetingSpaceId: String?

        public var withThumbnail: Bool?

        /// 为true时，仅返回支持magic share的文档
        public var onlySupportMs: Bool?
    }
}

/// Videoconference_V1_VcQueryDocsResponse
public struct QueryDocsResponse {
    public init(docs: [VcDocs], hasMore: Bool, total: Int32, offset: Int32) {
        self.docs = docs
        self.hasMore = hasMore
        self.total = total
        self.offset = offset
    }

    public var docs: [VcDocs]

    /// 是否还有更多结果
    public var hasMore: Bool

    /// 这次query一共有多少结果
    public var total: Int32

    /// 此offset字段为实际需要查询时回传给后端的offset字段
    public var offset: Int32
}

extension QueryDocsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_VcQueryDocsRequest
    func toProtobuf() throws -> Videoconference_V1_VcQueryDocsRequest {
        var request = ProtobufType()
        request.query = query
        request.limit = limit
        request.offset = offset
        request.source = .init(rawValue: source.rawValue) ?? .unknown
        var opt = ProtobufType.QueryOpts()
        if let spaceID = opts.meetingSpaceId {
            opt.meetingSpaceID = spaceID
        }
        if let thumbnail = opts.withThumbnail {
            opt.withThumbnail = thumbnail
        }
        if let supportMs = opts.onlySupportMs {
            opt.onlySupportMs = supportMs
        } else {
            opt.onlySupportMs = query.isEmpty
        }
        request.opts = opt
        return request
    }
}

extension QueryDocsResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_VcQueryDocsResponse
    init(pb: Videoconference_V1_VcQueryDocsResponse) throws {
        self.hasMore = pb.hasMore_p
        self.total = pb.total
        self.offset = pb.offset
        self.docs = pb.docs.map({ $0.vcType })
    }
}

typealias PBDocs = Videoconference_V1_VcDocs
extension PBDocs {
    var vcType: VcDocs {
        .init(docToken: docToken, docURL: docURL,
              docType: .init(rawValue: docType.rawValue) ?? .unknown,
              docSubType: .init(rawValue: docSubType.rawValue) ?? .unknown,
              docTitle: docTitle,
              isCrossTenant: isCrossTenant, ownerName: ownerName, ownerId: ownerID,
              status: .init(rawValue: status.rawValue) ?? .unknown,
              docTitleHighlight: docTitleHighlight, createTime: createTime, updateTime: updateTime, abstract: abstract,
              thumbnail: thumbnail.vcType, docLabelURL: docLabelURL,
              containerType: .init(rawValue: containerType.rawValue) ?? .space,
              iconMeta: iconMeta)
    }
}

extension QueryDocsRequest: CustomStringConvertible {
    public var description: String {
        String(name: "QueryDocsRequest", [
            "query.hash": query.hash,
            "limit": limit,
            "offset": offset,
            "source": source,
            "opts": opts
        ])
    }
}
