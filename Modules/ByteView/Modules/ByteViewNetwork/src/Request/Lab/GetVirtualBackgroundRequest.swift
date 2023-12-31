//
//  GetVirtualBackgroundRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public enum MaterialBizType: Int {
    case unknownBizType = 0
    /// 个人虚拟背景
    case bizCustom = 1
    /// 日程会议统一虚拟背景
    case bizCalendar = 2
    /// webinar舞台
    case bizWebinarStage = 3

}

/// Videoconference_V1_GetVcVirtualBackgroundRequest
public struct GetVirtualBackgroundRequest {
    public static let command: NetworkCommand = .rust(.getVcVirtualBackground)
    public typealias Response = GetVirtualBackgroundResponse

    public init(sets: [VirtualBackground], fromLocal: Bool = true) {
        self.sets = sets
        self.fromLocal = fromLocal
    }

    public var sets: [VirtualBackground]
    public var fromLocal: Bool
    public var bizType: MaterialBizType?

    public struct VirtualBackground: CustomStringConvertible {
        public init(name: String, url: String) {
            self.name = name
            self.url = url
        }

        public var name: String

        public var url: String

        public var source: VirtualBackgroundInfo.MaterialSource?

        public var portraitURL: String?

        public var description: String {
            "VirtualBackground \(name), \(source)"
        }
    }
}

/// 虚拟背景
/// - PUSH_VC_VIRTUAL_BACKGROUND = 89346
/// - Videoconference_V1_GetVcVirtualBackgroundResponse
public struct GetVirtualBackgroundResponse {

    ///推送的类型
    public var type: TypeEnum

    public var infos: [VirtualBackgroundInfo]

    /// Videoconference_V1_BackgroundType
    public enum TypeEnum: Int, Hashable {

        /// infos为全量
        case all // = 0

        /// infos为新增
        case add // = 1

        /// FileStatus更新
        case update // = 2

        /// 删除部分infos
        case delete // = 3

        /// pc同步旧背景部分出错
        case hasSyncFailer // = 4

        /// pc同步旧背景数据超出限制数量
        case hasCountLimit // = 5
    }

    public var bizType: MaterialBizType?
}

extension GetVirtualBackgroundResponse: CustomStringConvertible {

    public var description: String {
        return String(indent: "GetVirtualBackgroundResponse",
                      "type: \(type)",
                      "info: \(infos.first)")
    }
}

extension GetVirtualBackgroundRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVcVirtualBackgroundRequest
    func toProtobuf() throws -> Videoconference_V1_GetVcVirtualBackgroundRequest {
        var request = ProtobufType()
        request.sets = sets.map({ $0.pbType })
        request.fromLocal = fromLocal
        if let bizType = self.bizType,
           let rustBizType = Videoconference_V1_VCMaterialBizType(rawValue: bizType.rawValue) {
            request.bizType = rustBizType
        }
        return request
    }
}

extension GetVirtualBackgroundResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVcVirtualBackgroundResponse
    init(pb: Videoconference_V1_GetVcVirtualBackgroundResponse) throws {
        self.type = .init(rawValue: pb.type.rawValue) ?? .all
        self.infos = pb.infos.map({ $0.vcType })
        if pb.hasBizType {
            self.bizType = .init(rawValue: pb.bizType.rawValue)
        }
    }
}

private extension GetVirtualBackgroundRequest.VirtualBackground {
    var pbType: GetVirtualBackgroundRequest.ProtobufType.VirtualBackground {
        var bg = GetVirtualBackgroundRequest.ProtobufType.VirtualBackground()
        bg.name = name
        bg.url = url
        if let source = source {
            bg.source = .init(rawValue: source.rawValue) ?? .unknownSource
        }
        if let portraitURL = portraitURL {
            bg.portraitURL = portraitURL
        }
        return bg
    }
}
