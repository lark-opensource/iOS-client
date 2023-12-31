//
//  CollaboratorSearchAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/11/24.
//

import Foundation
import SKFoundation
import RxSwift
import Swinject

public struct CollaboratorSearchResponse {

    public enum PagingInfo {
        case noMore
        case hasMore(pageToken: Any)
    }

    public let collaborators: [Collaborator]
    public let pagingInfo: PagingInfo

    public init(collaborators: [Collaborator], pagingInfo: PagingInfo) {
        self.collaborators = collaborators
        self.pagingInfo = pagingInfo
    }
}

public struct CollaboratorSearchRequest {
    public let query: String
    // 有三种含义：nil 代表第一页，String 代表新 API 返回的 pageToken，Int 表示旧 API 返回的 offset
    public let pageToken: Any?
    public let count: Int
    public let objToken: String?
    public let objTypeValue: Int?
    public let shouldSearchOrganzation: Bool
    public let shouldSearchUserGroup: Bool
}

public protocol CollaboratorSearchAPI {
    func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse>
}

public struct LegacyCollaboratorSearchAPI: CollaboratorSearchAPI {

    public init() {}

    public func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
        DocsLogger.info("start search collaborator using legacy API")
        let nextOffset = request.pageToken as? Int ?? 0
        let context = CollaboratorCandidatesRequestContext(query: request.query,
                                                           offset: nextOffset,
                                                           count: request.count,
                                                           docsTypeValue: request.objTypeValue,
                                                           objToken: request.objToken,
                                                           shouldSearchOrganization: request.shouldSearchOrganzation,
                                                           shouldSearchUserGroup: request.shouldSearchUserGroup)
        return PermissionManager.searchCollaboratorCandidatesRequest(context: context)
    }
}
