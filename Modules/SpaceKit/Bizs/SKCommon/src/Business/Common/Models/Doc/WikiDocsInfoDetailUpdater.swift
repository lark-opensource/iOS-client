//
//  WikiDocsInfoDetailUpdater.swift
//  SKCommon
//
//  Created by Weston Wu on 2020/10/15.
//

import Foundation
import RxSwift
import SKFoundation
import SwiftyJSON
import SKInfra

public final class WikiDocsInfoDetailUpdater: DocsInfoDetailUpdater {

//    0
//    private struct WikiMeta {
//        let isStared: Bool
//        let isPined: Bool
//        let url: String?
//    }

    private(set) public var isRequesting: Bool = false
    private var metaUpdator = WikiMetaUpdator()

    public init() {}

    public func updateDetail(for docsInfo: DocsInfo, headers: [String: String]) -> Single<Void> {
        guard !isRequesting else {
            spaceAssertionFailure("another update request is in progress, check isRequesting flag before calling this method")
            return .error(DocsInfoDetailError.redundantRequest)
        }
        guard let wikiToken = docsInfo.wikiInfo?.wikiToken,
              let spaceId = docsInfo.wikiInfo?.spaceId else {
            return .error(DocsInfoDetailError.wikiTokenNotFound)
        }
        isRequesting = true
        let docsDetailRequest = DocsInfoDetailHelper.fetchDetail(token: docsInfo.objToken, type: docsInfo.type, headers: headers)
        let wikiMetaRequest = fetchWikiMetaV2(with: wikiToken, spaceId: spaceId)

        return Single.zip(docsDetailRequest, wikiMetaRequest)
            .do(onDispose: { [weak self] in
                self?.isRequesting = false
            })
            .map { (docsDetail, wikiNodeState) -> Void in
                let docsType = docsDetail.type
                guard !docsType.isUnknownType else {
                    throw DocsInfoDetailError.typeUnsupport
                }
                let detailInfo = docsDetail.detailInfo
                let wikiShareUrl = docsInfo.shareUrl
                DocsInfoDetailHelper.update(docsInfo: docsInfo, detailInfo: detailInfo, needUpdateStar: false)
                // wiki url会被上面update接口覆盖成docs url，需要还原回来
                docsInfo.shareUrl = wikiShareUrl
                // wiki 在 space 中的收藏/快速访问状态以 meta 中的数据为准
                docsInfo.stared = wikiNodeState.isExplorerStar
                docsInfo.pined = wikiNodeState.isExplorerPin
                docsInfo.wikiInfo?.wikiNodeState = wikiNodeState
                docsInfo.ownerType = singleContainerOwnerTypeValue
            }
    }

    func fetchWikiMetaV2(with wikiToken: String,
                         spaceId: String) -> Single<WikiInfo.WikiNodeState> {
        return metaUpdator.fetchWikiMetaV2(with: wikiToken, spaceId: spaceId)
    }
}

// Docs和Drive复用获取wikimeta
public final class WikiMetaUpdator {
    public init() { }

    private func fetchWikiSpaceData(spaceID: String) -> Single<Data?> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetSpaceInfoV2,
                                        params: ["space_id": spaceID])
            .set(method: .GET)
        return request.rxStart().map { json in
            guard let json else { throw DocsNetworkError.invalidData }
            let spaceData = try json["data"][spaceID].rawData()
            return spaceData
        }
        // 弱依赖，失败不影响其他两个请求的数据正常返回
        .catchErrorJustReturn(nil)
    }
    public func fetchWikiMetaV2(with wikiToken: String,
                                spaceId: String) -> Single<WikiInfo.WikiNodeState> {
        let permissionRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetNodePermission,
                                                  params: ["space_id": spaceId, "wiki_token": wikiToken])
            .set(method: .GET)
            .rxStart()
            .do(onSuccess: { json in
                DocsLogger.info("wiki container get node [\(wikiToken.suffix(6))] perm success \(json ?? "")")
            }, onError: { error in
                DocsLogger.error("wiki container get node [\(wikiToken.suffix(6))] perm fail \(error)")
            })

        let wikiInfoRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getWikiInfoV2,
                                                params: [
                                                    "wiki_token": wikiToken,
                                                    "need_star": true,
                                                    "expand_shortcut": true,
                                                    "with_deleted": true
                                                ])
            .set(method: .GET)
            .rxStart()
            .do(onSuccess: { _ in
                DocsLogger.info("wiki container get nodeInfo [\(wikiToken.suffix(6))] success")
            }, onError: { error in
                DocsLogger.error("wiki container get nodeInfo [\(wikiToken.suffix(6))] fail \(error)")
            })

        return Single.zip(permissionRequest, wikiInfoRequest)
            .map { permJson, nodeJson -> WikiInfo.WikiNodeState in
                // permJson
                if let canStar = permJson?["data"]["can_star"].bool,
                   let canDelete = permJson?["data"]["can_delete"].bool,
                   var canCopy = permJson?["data"]["can_clone"].bool,
                   var canShortcut = permJson?["data"]["can_add_shortcut"].bool,
                   let showMove = permJson?["data"]["show_move"].bool,
                   let isLocked = permJson?["data"]["is_locked"].bool,
                   // nodeJson
                   let isStar = nodeJson?["data"]["is_star"].bool,
                   let isExplorerStar = nodeJson?["data"]["is_explorer_star"].bool,
                   let isExplorerPin = nodeJson?["data"]["is_explorer_pin"].bool,
                   let hasChild = nodeJson?["data"]["has_child"].bool {
                    DocsLogger.info("get WikiNodeState")
                    let showDelete = permJson?["data"]["show_delete"].bool ?? false
                    let showSingleDelete = permJson?["data"]["show_single_delete"].bool ?? false
                    let parentIsRoot = permJson?["data"]["parent"]["root"].bool ?? false
                    let parentMovePermission = permJson?["data"]["parent"]["can_move_from"].bool ?? false
                    let nodeMovePermission = permJson?["data"]["node"]["can_be_moved"].bool ?? false
                    let canMove = permJson?["data"]["can_move"].bool ?? false

                    let isShortcut = nodeJson?["data"]["wiki_node_type"].int == 1
                    let shortcutWikiToken = nodeJson?["data"]["origin_wiki_token"].string
                    let shortcutSpaceID = nodeJson?["data"]["origin_space_id"].string
                    let parentWikiToken = nodeJson?["data"]["parent_wiki_token"].string
                    let url = nodeJson?["data"]["url"].string

                    var originIsExternal = false
                    if isShortcut {
                        canCopy = permJson?["data"]["origin_can_clone"].bool ?? false
                        canShortcut = permJson?["data"]["origin_can_add_shortcut"].bool ?? false
                        originIsExternal = nodeJson?["data"]["origin_is_external"].bool ?? false
                    }
                    return WikiInfo.WikiNodeState(canStar: canStar,
                                                  canDelete: canDelete,
                                                  showDelete: showDelete,
                                                  showSingleDelete: showSingleDelete,
                                                  canCopy: canCopy,
                                                  canMove: canMove,
                                                  isLocked: isLocked,
                                                  canShortcut: canShortcut,
                                                  isStar: isStar,
                                                  isExplorerStar: isExplorerStar,
                                                  isExplorerPin: isExplorerPin,
                                                  isShortcut: isShortcut,
                                                  hasChild: hasChild,
                                                  parentIsRoot: parentIsRoot,
                                                  nodeMovePermission: nodeMovePermission,
                                                  parentMovePermission: parentMovePermission,
                                                  shortcutWikiToken: shortcutWikiToken,
                                                  shortcutSpaceID: shortcutSpaceID,
                                                  parentWikiToken: parentWikiToken,
                                                  originIsExternal: originIsExternal,
                                                  showMove: showMove,
                                                  url: url)

                } else {
                    DocsLogger.info("get WikiNodeState parse error")
                    return WikiInfo.WikiNodeState(canStar: false,
                                                  canDelete: false,
                                                  canCopy: false,
                                                  canShortcut: false,
                                                  isStar: false,
                                                  isExplorerStar: false,
                                                  isExplorerPin: false,
                                                  isShortcut: false,
                                                  shortcutWikiToken: nil,
                                                  shortcutSpaceID: nil,
                                                  parentWikiToken: nil,
                                                  originIsExternal: false,
                                                  showMove: false)
                }
            }
    }
}
