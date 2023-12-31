//
//  RelationTagRequest.swift
//  ByteViewNetwork
//
//  Created by admin on 2022/11/25.
//

import Foundation
import ServerPB

// MARK: RelationTag
/// 获取"人"维度标签 VC_MGET_RELATION_TAG = 89315
/// ServerPB_Videochat_VCMGetRelationTagRequest
public struct GetRelationTagRequest {
    public typealias Response = GetRelationTagResponse
    public static let command: NetworkCommand = .server(.vcMgetRelationTag)

    public var users: [VCRelationTag.User]

    public init(users: [VCRelationTag.User]) {
        self.users = users
    }
}

extension GetRelationTagRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_VCMGetRelationTagRequest
    func toProtobuf() throws -> ServerPB_Videochat_VCMGetRelationTagRequest {
        var request = ProtobufType()
        request.users = users.map { $0.serverPbType }
        return request
    }
}

/// ServerPB_Videochat_VCMGetRelationTagResponse
public struct GetRelationTagResponse {
    public var relationTags: [VCRelationTag]
}

extension GetRelationTagResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_VCMGetRelationTagResponse
    init(pb: ServerPB_Videochat_VCMGetRelationTagResponse) throws {
        self.relationTags = pb.relationTags.map { $0.vcType }
    }
}

// MARK: CollaborationTargetTenantInfo
/// PULL_COLLABORATION_TARGET_TENANT_INFO = 805; // 获取建联租户信息
/// ServerPB_Collaboration_PullCollaborationTargetTenantInfoRequest
public struct GetTargetTenantInfoRequest {
    public typealias Response = GetTargetTenantInfoResponse
    public static let command: NetworkCommand = .server(.pullCollaborationTargetTenantInfo)

    public init(targetTenantIds: [Int64]) {
        self.targetTenantIds = targetTenantIds
    }

    public var targetTenantIds: [Int64]
}

extension GetTargetTenantInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Collaboration_PullCollaborationTargetTenantInfoRequest
    func toProtobuf() throws -> ServerPB_Collaboration_PullCollaborationTargetTenantInfoRequest {
        var request = ProtobufType()
        request.targetTenantIds = targetTenantIds
        return request
    }
}

/// ServerPB_Collaboration_PullCollaborationTargetTenantInfoResponse
public struct GetTargetTenantInfoResponse {
    /// 全局标签
    public var globalTag: RelationI18nText?
    /// 目标租户信息
    public var targetTenantInfos: [Int64: TargetTenantInfo] = [:]
}

extension GetTargetTenantInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Collaboration_PullCollaborationTargetTenantInfoResponse
    init(pb: ServerPB_Collaboration_PullCollaborationTargetTenantInfoResponse) throws {
        if pb.hasGlobalTag {
            globalTag = pb.globalTag.vcType
        }
        targetTenantInfos = pb.targetTenantInfos.mapValues { $0.vcType }
    }
}
