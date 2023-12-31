//
//  SearchUsersAndChatsResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_SearchUsersAndChatsRequest
public struct SearchUsersAndChatsRequest {
    public static let command: NetworkCommand = .rust(.searchUsersAndChats)
    public typealias Response = SearchUsersAndChatsResponse
    public init(query: String, offset: Int, count: Int, queryType: QueryType) {
        self.query = query
        self.offset = offset
        self.count = count
        self.queryType = queryType
    }

    /// 查询字符串
    public var query: String

    /// 查询开始序号
    public var offset: Int

    /// 期望查询条数
    public var count: Int

    public var queryType: QueryType

    public enum QueryType: Int {
        case unknown // = 0
        case searchForShareCard // = 1
        case searchForJoinLimit // = 2
    }
}

/// Videoconference_V1_SearchUsersAndChatsResponse
public struct SearchUsersAndChatsResponse: Equatable {

    public var items: [UserAndCardItem]

    public var hasMore: Bool

    public var totalCount: Int64

    public var searchKey: String

    public struct UserAndCardItem: Equatable {

        public var id: String

        public var idType: IDType

        public var name: String

        public var imageKey: String

        public var desc: String

        public var isExternal: Bool

        public var hitTerms: [String]

        public var subtitleHitTerms: [String]

        public var userInfo: UserInfo?

        public var chatInfo: ChatInfo?

        public var roomInfo: RoomInfo?

        public var relationTagWhenRing: CollaborationRelationTag?
    }

    public enum IDType: Int, Hashable {
        case user // = 0
        case chat // = 1
        case room // = 2
    }

    public struct UserInfo: Equatable {

        /// 用户状态
        public var workStatus: User.WorkStatus

        /// 勿扰模式结束时间
        public var zenModeEndTime: Int64

        /// 是否有权限
        public var hasPermission: Bool

        /// 协作权限级别
        public var collaborationType: LarkUserCollaborationType

        /// 自定义个人状态，start_time升序
        public var customStatuses: [User.CustomStatus]
    }

    public struct ChatInfo: Equatable {
        public var memberCount: Int64
    }

    public struct RoomInfo: Equatable {
    }
}

extension SearchUsersAndChatsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SearchUsersAndChatsRequest
    func toProtobuf() throws -> Videoconference_V1_SearchUsersAndChatsRequest {
        var request = ProtobufType()
        request.query = query
        request.offset = Int32(offset)
        request.count = Int32(count)
        request.queryType = ProtobufType.QueryType.init(rawValue: queryType.rawValue) ?? .unknown
        request.needQueryOuterTanant = true
        return request
    }
}

extension SearchUsersAndChatsResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SearchUsersAndChatsResponse
    init(pb: Videoconference_V1_SearchUsersAndChatsResponse) throws {
        self.items = pb.items.map({ $0.vcType })
        self.hasMore = pb.hasMore_p
        self.totalCount = pb.totalCount
        self.searchKey = pb.searchKey
    }
}

private typealias PBSearchUsersAndChatsResponse = SearchUsersAndChatsResponse.ProtobufType
private extension PBSearchUsersAndChatsResponse.UserAndCardItem {
    var vcType: SearchUsersAndChatsResponse.UserAndCardItem {
        .init(id: id, idType: .init(rawValue: idType.rawValue) ?? .user, name: name, imageKey: imageKey, desc: desc, isExternal: isExternal,
              hitTerms: hitTerms, subtitleHitTerms: subtitleHitTerms,
              userInfo: hasUserInfo ? userInfo.vcType : nil,
              chatInfo: hasChatInfo ? chatInfo.vcType : nil,
              roomInfo: hasRoomInfo ? roomInfo.vcType : nil,
              relationTagWhenRing: hasRelationTagWhenRing ? relationTagWhenRing.vcType : nil )
    }
}

private extension PBSearchUsersAndChatsResponse.UserInfo {
    var vcType: SearchUsersAndChatsResponse.UserInfo {
        .init(workStatus: descriptionFlag.vcType, zenModeEndTime: zenModeEndTime, hasPermission: hasPermission_p,
              collaborationType: .init(rawValue: collaborationType.rawValue) ?? .default,
              customStatuses: customStatuses)
    }
}

private extension PBSearchUsersAndChatsResponse.ChatInfo {
    var vcType: SearchUsersAndChatsResponse.ChatInfo {
        .init(memberCount: memberCount)
    }
}

private extension PBSearchUsersAndChatsResponse.RoomInfo {
    var vcType: SearchUsersAndChatsResponse.RoomInfo {
        .init()
    }
}

private extension PBSearchUsersAndChatsResponse.UserWorkStatusType {
    var vcType: User.WorkStatus {
        switch self {
        case .onMeeting:
            return .meeting
        case .onLeave:
            return .leave
        case .onBusiness:
            return .business
        default:
            return .default
        }
    }
}

extension SearchUsersAndChatsRequest: CustomStringConvertible {
    public var description: String {
        String(name: "SearchUsersAndChatsRequest", [
            "query.hash": query.hash,
            "offset": offset,
            "count": count,
            "queryType": queryType
        ])
    }
}
