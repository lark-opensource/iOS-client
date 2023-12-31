//
//  RustDocAPI.swift
//  Lark-Rust
//
//  Created by liuwanlin on 2018/3/1.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import ServerPB
import LarkSDKInterface
import LarkModel

final class RustDocAPI: LarkAPI, DocAPI {

    func getDocsHistory(beginTime: Int64, count: Int64) -> Observable<DocsHistoryResult> {
        var request = GetDocsHistoryRequest()
        request.beginTime = beginTime
        request.count = count
        return self.client.sendAsyncRequest(request, transform: { (response: GetDocsHistoryResponse) -> DocsHistoryResult in
            let chattersDic: [String: LarkModel.Chatter] = response.entity.chatters.mapValues({ (chatter) -> LarkModel.Chatter in
                return LarkModel.Chatter.transform(pb: chatter)
            })
            return DocsHistoryResult(
                docs: response.docs,
                hasMore: response.hasMore_p,
                nextTime: response.nextTime,
                chattersDic: chattersDic)
        }).subscribeOn(scheduler)
    }

    func updatePermission(_ messageId2Permission: [String: Int], messageID: String) -> Observable<[String]> {
        var request = UpdateDocPermissionRequest()
        request.pairs = messageId2Permission.map({ (arg0) -> UpdateDocPermissionRequest.Pair in
            let (key, value) = arg0
            var pair = UpdateDocPermissionRequest.Pair()
            pair.token = key
            pair.messageID = messageID
            UpdateDocPermissionRequest.Permission(rawValue: value).flatMap { pair.perm = $0 }
            return pair
        })
        return self.client.sendAsyncRequest(request, transform: { (response: UpdateDocPermissionResponse) -> [String] in
            return response.successMessageIds
        }).subscribeOn(scheduler)
    }

    func getMessageDocPermissions(messageIds: [String]) -> Observable<[String: RustPB.Space_Doc_V1_GetMessageDocPermissionsResponse.PermissionListInfo]> {
        var reuqest = GetMessageDocPermissionsRequest()
        reuqest.messageIds = messageIds

        return self.client.sendAsyncRequest(reuqest) { (response: GetMessageDocPermissionsResponse) -> [String: RustPB.Space_Doc_V1_GetMessageDocPermissionsResponse.PermissionListInfo] in
            return response.messageID2PermissionListInfo
        }.subscribeOn(scheduler)
    }

    func pullMessageDocPermissions(messageIds: [String]) -> Observable<ServerPB_Messages_PullMessageDocPermsResponse> {
        var request = ServerPB_Messages_PullMessageDocPermsRequest()
        request.messageIds = messageIds
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .pullMessageDocPerms)
    }

    func createDocFeed(key: String, type: RustPB.Basic_V1_Doc.TypeEnum) -> Observable<RustPB.Basic_V1_DocFeed> {
        var request = CreateDocFeedRequest()
        request.key = key
        request.type = type
        return self.client.sendAsyncRequest(request) { (res: CreateDocFeedResponse) -> RustPB.Basic_V1_DocFeed in
            return res.entity.docFeeds.values.first ?? .init()
        }.subscribeOn(scheduler)
    }

    func updateDocFeed(feedId: String, isRemind: Bool) -> Observable<Void> {
        var request = UpdateDocFeedRequest()
        request.docFeedID = feedId
        request.isRemind = isRemind
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getLocalDocFeeds(feedIds: [String]) -> [String: RustPB.Basic_V1_DocFeed] {
        var request = MGetDocFeedsRequest()
        request.ids = feedIds
        let ret: [String: RustPB.Basic_V1_DocFeed]
        do {
            ret = try self.client.sendSyncRequest(request) { (res: MGetDocFeedsResponse) -> [String: RustPB.Basic_V1_DocFeed] in
                return res.entity.docFeeds
            }
        } catch {
            ret = [:]
        }
        return ret
    }

    func fetchDocFeeds(feedIds: [String]) -> Observable<[String: RustPB.Basic_V1_DocFeed]> {
        var request = MGetDocFeedsRequest()
        request.ids = feedIds
        return self.client.sendAsyncRequest(request) { (res: MGetDocFeedsResponse) -> [String: RustPB.Basic_V1_DocFeed] in
            return res.entity.docFeeds
        }.subscribeOn(scheduler)
    }

    func updateDocMeRead(messageIds: [String], token: String, docType: RustPB.Basic_V1_Doc.TypeEnum) -> Observable<Void> {
        var request = UpdateDocMeReadRequest()
        request.messageIds = messageIds
        request.token = token
        request.docType = docType
        return self.client.sendAsyncRequest(request)
    }

    func getDocByURL(urls: [String]) -> Observable<GetDocByURLResult> {
        var request = GetDocByURLsRequest()
        request.urls = urls
        return self.client.sendAsyncRequest(request, transform: { (res: GetDocByURLsResponse) -> GetDocByURLResult in
            return GetDocByURLResult(docs: res.docs, invalidUrls: res.invalidUrls, noPermUrls: res.noPermUrls)
        }).subscribeOn(scheduler)
    }
}
