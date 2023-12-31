//
//  DocAPI.swift
//  Lark
//
//  Created by liuwanlin on 2018/3/1.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB

public struct DocsHistoryResult {
    public var docs: [RustPB.Space_Doc_V1_DocHistory]
    public var hasMore: Bool
    public var nextTime: Int64
    public var chattersDic: [String: Chatter]

    public init(docs: [RustPB.Space_Doc_V1_DocHistory], hasMore: Bool, nextTime: Int64, chattersDic: [String: Chatter]) {
        self.docs = docs
        self.hasMore = hasMore
        self.nextTime = nextTime
        self.chattersDic = chattersDic
    }
}

public struct GetDocByURLResult {
    public var docs: [String: RustPB.Basic_V1_Doc]
    public var invalidUrls: [String]
    public var noPermUrls: [String]

    public init(docs: [String: RustPB.Basic_V1_Doc], invalidUrls: [String], noPermUrls: [String]) {
        self.docs = docs
        self.invalidUrls = invalidUrls
        self.noPermUrls = noPermUrls
    }
}

public protocol DocAPI {
    func updatePermission(_ messageId2Permission: [String: Int], messageID: String) -> Observable<[String]>

    func getMessageDocPermissions(messageIds: [String]) -> Observable<[String: RustPB.Space_Doc_V1_GetMessageDocPermissionsResponse.PermissionListInfo]>

    /// CCM接入URL中台之后，Message上不再挂DocEntity信息，鉴权时title，权限等信息统一通过接口拉下来
    /// 与getMessageDocPermissions的区别是，getMessageDocPermissions只返回权限信息
    func pullMessageDocPermissions(messageIds: [String]) -> Observable<ServerPB_Messages_PullMessageDocPermsResponse>

    func createDocFeed(key: String, type: RustPB.Basic_V1_Doc.TypeEnum) -> Observable<RustPB.Basic_V1_DocFeed>

    func getDocsHistory(beginTime: Int64, count: Int64) -> Observable<DocsHistoryResult>

    func updateDocFeed(feedId: String, isRemind: Bool) -> Observable<Void>

    func getLocalDocFeeds(feedIds: [String]) -> [String: RustPB.Basic_V1_DocFeed]

    func fetchDocFeeds(feedIds: [String]) -> Observable<[String: RustPB.Basic_V1_DocFeed]>

    func updateDocMeRead(messageIds: [String], token: String, docType: RustPB.Basic_V1_Doc.TypeEnum) -> Observable<Void>

    func getDocByURL(urls: [String]) -> Observable<GetDocByURLResult>
}
public typealias DocAPIProvider = () -> DocAPI
