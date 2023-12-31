//
//  WikiNetworkManager.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/23.
//
// disable-lint: magic number

import Foundation
import SwiftyJSON
import RxSwift
import SKCommon
import SKUIKit
import SKFoundation
import Alamofire
import SKResource
import SpaceInterface
import SKInfra

public struct WikiTreeData {
    public var mainRootToken: String
    public var metaStorage: [String: WikiTreeNodeMeta]
    public var relation: WikiTreeRelation

    public var spaceInfo: WikiSpace?
    public var userSpacePermission: WikiUserSpacePermission?
}

// 服务端返回的原始数据结构，方便拆分为端上使用的原始数据结构
// 部分返回单个节点信息的场景也会使用
public struct WikiServerNode: Equatable {
    public let meta: WikiTreeNodeMeta
    public let sortID: Double
    public let parent: String
    
    public init(meta: WikiTreeNodeMeta, sortID: Double, parent: String) {
        self.meta = meta
        self.sortID = sortID
        self.parent = parent
    }
}

// 协同更新wiki节点data
public struct WikiTreeUpdateData {
    public var wikiToken: String
    public var title: String?
    public var iconInfo: String?
    public init(wikiToken: String, title: String? = nil, iconInfo: String? = nil) {
        self.wikiToken = wikiToken
        self.title = title
        self.iconInfo = iconInfo
    }
}

extension WikiServerNode: Decodable {
    private enum CodingKeys: String, CodingKey {
        case parent = "parent_wiki_token"
        case sortID = "sort_id"
    }

    public init(from decoder: Decoder) throws {
        meta = try WikiTreeNodeMeta(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parent = try container.decode(String.self, forKey: .parent)
        sortID = try container.decode(Double.self, forKey: .sortID)
    }
}

public enum PinDocumentType {
    case space(entry: SpaceEntry)
    case wiki(meta: WikiTreeNodeMeta)
}

public protocol WikiTreeNetworkAPI {

    typealias NodeChildren = WikiTreeRelation.NodeChildren

    func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData>

    func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])>

    func loadFavoriteList(spaceID: String) -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])>

    func getNodeMetaInfo(wikiToken: String) -> Single<WikiServerNode>
    
    func batchGetNodeMetaInfo(wikiTokens: [String]) -> Single<[WikiServerNode]>

    func createNode(spaceID: String,
                    parentWikiToken: String,
                    template: TemplateModel?,
                    objType: DocsType,
                    synergyUUID: String?) -> Single<WikiServerNode>

    func createShortcut(spaceID: String,
                        parentWikiToken: String,
                        originWikiToken: String,
                        title: String?,
                        synergyUUID: String?) -> Single<WikiServerNode>
    // 删除
    func deleteNode(_ wikiToken: String,
                    spaceId: String,
                    canApply: Bool,
                    synergyUUID: String?) -> Maybe<WikiAuthorizedUserInfo>
    // 申请删除
    func applyDelete(wikiMeta: WikiMeta,
                     isSingleDelete: Bool,
                     reason: String?,
                     reviewerID: String) -> Completable

    // 移动
    func moveNode(sourceMeta: WikiMeta,
                  originParent: String,
                  targetMeta: WikiMeta,
                  synergyUUID: String?) -> Single<Double>
    // 收藏
    func setStarNode(spaceId: String,
                     wikiToken: String,
                     isAdd: Bool) -> Single<Bool>
    // 节点权限
    func getNodePermission(spaceId: String,
                           wikiToken: String) -> Single<WikiTreeNodePermission>
    // 空间权限
    func getSpacePermission(spaceId: String) -> Single<WikiSpacePermission>

    func update(newTitle: String, wikiToken: String) -> Completable

    func getWikiObjInfo(wikiToken: String) -> Single<(WikiObjInfo, String?)>

    func starInExplorer(objToken: String, objType: DocsType, isAdd: Bool) -> Single<Void>

    // 获取申请移动的审批人信息
    func getMoveNodeAuthorizedUserInfo(wikiToken: String, spaceID: String) -> Single<WikiAuthorizedUserInfo>

    func applyMoveToWiki(sourceMeta: WikiMeta,
                         currentParentWikiToken: String,
                         targetMeta: WikiMeta,
                         reason: String?,
                         authorizedUserID: String) -> Single<Void>
    // 申请移动节点到 space
    func applyMoveToSpace(wikiToken: String,
                          location: WikiMoveToSpaceLocation,
                          reason: String?,
                          authorizedUserID: String) -> Single<Void>

    // 发起移动到 space 操作
    func moveToSpace(wikiToken: String,
                     location: WikiMoveToSpaceLocation,
                     synergyUUID: String?) -> Single<WikiObjInfo.SpaceInfo>

    func copyWikiNode(sourceMeta: WikiMeta,
                      objType: DocsType,
                      targetMeta: WikiMeta,
                      title: String,
                      synergyUUID: String?) -> Single<(WikiServerNode, URL)>

    // 返回 objToken 和 URL
    func copyWikiToSpace(sourceSpaceID: String, sourceWikiToken: String, objType: DocsType, title: String, folderToken: String) -> Single<(String, URL)>

    // 返回 nodeToken 和 URL
    func shortcutWikiToSpace(objToken: String, objType: DocsType, folderToken: String) -> Single<(String, URL)>

    func rxGetCoupleSpaceInfo(firstSpaceId: String, secondSpaceId: String) -> Observable<(WikiSpace, WikiSpace)>
    func getStarWikiSpaces(lastLabel: String?) -> Single<WorkSpaceInfo>
    func getWikiFilter() -> Single<WikiFilterList>
    /// 获取所有wiki知识库
    func rxGetWikiSpacesV2(lastLabel: String, size: Int, type: Int?, classId: String?) -> Single<WorkSpaceInfo>
    // 添加到快速访问
    func pinInExplorer(addPin: Bool, objToken: String, docsType: DocsType) -> Completable
    
    func getStarWikiSpaceTreeList() -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])>
    // 首页置顶树列表
    func loadPinDocumentList() -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])>
    // 首页分享树列表
    func loadShareList() -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])>
}

public typealias WikiObjInfo = WikiNetworkManager.WikiObjInfo
public typealias WikiAuthorizedUserInfo = AuthorizedUserInfo
public typealias WikiMoveToSpaceLocation = WikiNetworkManager.MoveToSpaceLocation

// swiftlint:disable type_body_length file_length
public final class WikiNetworkManager: NSObject, WikiTreeNetworkAPI {

    public static let shared = WikiNetworkManager()

    public static let dataQueue = DispatchQueue(label: "com.wiki.networkQueueScheduler")
    public static let dataQueueScheduler = SerialDispatchQueueScheduler(queue: dataQueue, internalSerialQueueName: "wiki-catalog-data-queue")

    /// 获取所有wiki知识库
    /// - Parameter completion: 请求回调
    public func getWikiSpacesV2(lastLabel: String,
                         size: Int,
                         type: Int?,
                         classId: String?,
                         completion: @escaping (Swift.Result<WorkSpaceInfo, Error>) -> Void) -> DocsRequest<JSON> {
        var params: [String: Any] = ["size": size, "last_label": lastLabel]
        if let type = type {
            params["type"] = type
        }
        if let classId {
            params["space_class_id"] = classId
        }
        let getWikiSpacesRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getAllWikiSpaceV2New,
                                                     params: params)
            .set(method: .GET)
        getWikiSpacesRequest.start() { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    completion(.failure(WikiError.invalidDataError))
                    return
            }
            if code != 0 {
                completion(.failure(WikiError.serverError(code: code)))
                return
            }
            let spacesData = json["data"]["spaces"].arrayValue
            let decoder = JSONDecoder()
            let spaces: [WikiSpace] = spacesData.compactMap { json in
                guard let data = try? json.rawData() else { return nil }
                return try? decoder.decode(WikiSpace.self, from: data)
            }
            let lastLabel = json["data"]["last_label"].stringValue
            let hasMore = json["data"]["has_more"].boolValue
            completion(.success(WorkSpaceInfo(spaces: spaces, lastLabel: lastLabel, hasMore: hasMore)))
        }
        return getWikiSpacesRequest
    }
    
    public func rxGetWikiSpacesV2(lastLabel: String, size: Int, type: Int?, classId: String?) -> Single<WorkSpaceInfo> {
        var params: [String: Any] = ["size": size, "last_label": lastLabel]
        if let type = type {
            params["type"] = type
        }
        if let classId {
            params["space_class_id"] = classId
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getAllWikiSpaceV2New, params: params).set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let json, let code = json["code"].int else {
                    throw WikiError.invalidDataError
                }
                if code != 0 {
                    throw WikiError.serverError(code: code)
                }
                let spacesData = json["data"]["spaces"].arrayValue
                let decoder = JSONDecoder()
                let spaces: [WikiSpace] = spacesData.compactMap { json in
                    guard let data = try? json.rawData() else { return nil }
                    return try? decoder.decode(WikiSpace.self, from: data)
                }
                let lastLabel = json["data"]["last_label"].stringValue
                let hasMore = json["data"]["has_more"].boolValue
                return WorkSpaceInfo(spaces: spaces, lastLabel: lastLabel, hasMore: hasMore)
            }
    }
    
    public func reportBrowser(wikiToken: String) -> Observable<()> {
        return RxDocsRequest<JSON>().request(OpenAPI.APIPath.wikiBrowserReport,
                                             params: ["token": wikiToken],
                                             method: .POST,
                                             encoding: .jsonEncodeDefault)
            .flatMap { (result) -> Observable<()> in
                guard let json = result,
                    let code = json["code"].int else {
                        return .error(WikiError.dataParseError)
                }
                return .just(())
            }
    }


    public func getSpace(spaceId: String) -> Observable<WikiSpace> {
        let params: [String: Any] = ["space_id": spaceId]
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.wikiGetSpaceInfoV2,
                     params: params,
                     method: .GET,
                     callbackQueue: Self.dataQueue)
            .flatMap { (json) -> Observable<WikiSpace> in
                guard let json = json else {
                    return .error(WikiError.dataParseError)
                }
                do {
                    let spaceInfoData = try json["data"][spaceId].rawData()
                    let decoder = JSONDecoder()
                    var spaceInfoMeta = try decoder.decode(WikiSpace.self, from: spaceInfoData)
                    spaceInfoMeta.spaceId = spaceId
                    return Observable<WikiSpace>.just(spaceInfoMeta)
                } catch {
                    DocsLogger.warning("Failed to parse space info data", error: error)
                    return Observable<WikiSpace>.error(error)
                }
            }
    }

    public func getSpaceMembers(spaceID: String) -> Single<[WikiMember]> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetMembers, params: ["space_id": spaceID])
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
        
        return request.rxStart()
            .map { json -> [WikiMember] in
                guard let json,
                      let membersJSON = json["data"]["members"].array else {
                    throw WikiError.dataParseError
                }
                let decoder = JSONDecoder()
                let members = membersJSON.compactMap { (memberJSON) -> WikiMember? in
                    do {
                        let memberData = try memberJSON.rawData()
                        var member = try decoder.decode(WikiMember.self, from: memberData)
                        member.aliasInfo = UserAliasInfo(json: memberJSON["display_name"])
                        return member
                    } catch {
                        DocsLogger.error("failed to parse wiki member in space info", error: error)
                        return nil
                    }
                }
                return members
            }
    }
    
    public func getSpaceDetail(spaceID: String) -> Single<WikiSpaceInfo.Meta> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetSpaceInfoV2, params: ["space_id": spaceID])
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
        
        return request.rxStart()
            .map { json -> WikiSpaceInfo.Meta in
                guard let json else {
                    throw WikiError.dataParseError
                }
                let spaceData = try json["data"][spaceID].rawData()
                let decoder = JSONDecoder()
                let spaceMeta = try decoder.decode(WikiSpaceInfo.Meta.self, from: spaceData)
                return spaceMeta
            }
    }
    
    // 获取空间信息（含成员信息）https://yapi.bytedance.net/project/3194/interface/api/1051710
    public func getSpaceInfo(spaceID: String) -> Single<WikiSpaceInfo> {
        let members = getSpaceMembers(spaceID: spaceID)
        let spaceMeta = getSpaceDetail(spaceID: spaceID)
        return Single.zip(members, spaceMeta)
            .map { members, spaceMeta -> WikiSpaceInfo in
                WikiSpaceInfo(meta: spaceMeta, members: members)
            }
    }

    // 获取2个空间信息
    public func rxGetCoupleSpaceInfo(firstSpaceId: String, secondSpaceId: String) -> Observable<(WikiSpace, WikiSpace)> {
        return Observable.zip(getSpace(spaceId: firstSpaceId), getSpace(spaceId: secondSpaceId)) { space1, space2 in
            return (space1, space2)
        }
    }
    
    public func createNode(spaceID: String, parentWikiToken: String, template:TemplateModel? = nil, objType: DocsType, synergyUUID: String?) -> Single<WikiServerNode> {
        WorkspaceManagementAPI.Wiki.createNode(location: (spaceID, parentWikiToken),
                                               objType: objType,
                                               templateToken: template?.objToken, //模板创建场景
                                               templateSource: template?.templateSource,
                                               synergyUUID: synergyUUID)
        .observeOn(Self.dataQueueScheduler)
        .map { json in
            let data = try json.rawData()
            let decoder = JSONDecoder()
            let node = try decoder.decode(WikiServerNode.self, from: data)
            return node
        }
    }
    
    public func createShortcut(spaceID: String, parentWikiToken: String, originWikiToken: String, title: String?, synergyUUID: String?) -> Single<WikiServerNode> {
        WorkspaceManagementAPI.Wiki.shortcutToWiki(sourceWikiToken: originWikiToken,
                                                   targetWikiToken: parentWikiToken,
                                                   targetSpaceID: spaceID,
                                                   title: title,
                                                   synergyUUID: synergyUUID)
        .observeOn(Self.dataQueueScheduler)
        .map { json in
            let data = try json.rawData()
            let decoder = JSONDecoder()
            let node = try decoder.decode(WikiServerNode.self, from: data)
            return node
        }
    }

    /// 删除节点
    /// - Parameter node: 删除的节点信息
    public func deleteNode(_ wikiToken: String,
                           spaceId: String,
                           canApply: Bool,
                           synergyUUID: String? = nil) -> Maybe<WikiAuthorizedUserInfo> {
        var params: [String: Any] = [
            "space_id": spaceId,
            "wiki_token": wikiToken,
            "auto_delete_mode": 2,
            "apply": canApply ? 1 : 0
        ]
        if let uuid = synergyUUID {
            params["synergy_uuid"] = uuid
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiDeleteNodeV2, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxResponse()
            .observeOn(Self.dataQueueScheduler)
            .compactMap { json, error in
                guard let json,
                      let code = json["code"].int else {
                    throw WikiError.dataParseError
                }
                switch code {
                case 0:
                    return nil
                case WikiErrorCode.operationNeedApply.rawValue:
                    let data = json["data"]
                    guard let userID = data["reviewer"].string else {
                        DocsLogger.error("missing required field for delete reviewer")
                        throw WikiError.dataParseError
                    }
                    let userData = data["users"][userID]
                    guard let userName = userData["name"].string else {
                        DocsLogger.error("missing required field for delete reviewer")
                        throw WikiError.dataParseError
                    }
                    let aliasInfo = UserAliasInfo(json: userData["display_name"])
                    return WikiAuthorizedUserInfo(userID: userID, userName: userName, i18nNames: [:], aliasInfo: aliasInfo)
                default:
                    if let error {
                        throw error
                    }
                    throw WikiError.serverError(code: code)
                }
            }
    }

    // 申请删除
    public func applyDelete(wikiMeta: WikiMeta,
                            isSingleDelete: Bool,
                            reason: String?,
                            reviewerID: String) -> Completable {
        WikiMoreAPI.applyDelete(wikiMeta: wikiMeta, isSingleDelete: isSingleDelete, reason: reason, reviewerID: reviewerID)
    }

    /// 移动节点
    /// - Parameters:
    ///   - node: 移动节点
    ///   - newNode: 目标节点
    /// - Returns: 是否移动成功，sortId
    public func moveNode(sourceMeta: WikiMeta,
                  originParent: String,
                  targetMeta: WikiMeta,
                  synergyUUID: String? = nil) -> Single<Double> {
        var params: [String: Any] = ["old_space_id": sourceMeta.spaceID,
                                     "new_space_id": targetMeta.spaceID,
                                     "old_parent_wiki_token": originParent,
                                     "new_parent_wiki_token": targetMeta.wikiToken,
                                     "wiki_token": sourceMeta.wikiToken,
                                     "to_last": true]
        if let uuid = synergyUUID {
            params["synergy_uuid"] = uuid
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiMoveNodeV2, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { result in
                guard let result = result, result["code"] == 0 else {
                    DocsLogger.warning("wikiMoveRelation 接口数据解析错误")
                    throw WikiError.dataParseError
                }
                let sortId = result["data"]["sort_id"].doubleValue
                return sortId
            }
    }

    // MARK: - Tree
    public func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
        var params: [String: Any] = [
            "space_id": spaceID,
            "with_space": true,
            "with_perm": needPermission,
            "expand_shortcut": true,
            "need_shared": true]
        if let initialWikiToken = initialWikiToken {
            params["wiki_token"] = initialWikiToken
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetRelationV2, params: params)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    DocsLogger.error("json found nil")
                    throw WikiError.dataParseError
                }
                return try Self.parseTreeInfo(data: data, spaceID: spaceID, needPermission: needPermission)
            }
    }

    static func parseTreeInfo(data: JSON, spaceID: String, needPermission: Bool) throws -> WikiTreeData {
        var treeData = try parseTreeData(treeData: data["tree"], spaceID: spaceID)
        // parse space info
        do {
            let spaceData = try data["space"].rawData()
            let decoder = JSONDecoder()
            if let rootTokenKey = WikiSpace.rootTokenCodingKey {
                decoder.userInfo[rootTokenKey] = treeData.mainRootToken
            }
            var space = try decoder.decode(WikiSpace.self, from: spaceData)
            space.spaceId = spaceID
            treeData.spaceInfo = space
            let rootToken = treeData.mainRootToken
            let spaceName = space.spaceName
            if var mainRootMeta = treeData.metaStorage[rootToken] {
                // 这里主动将 mainRootNode 的 title 修改为 space 名字
                // 在新首页多space共存场景，依赖 title 展示 spaceName
                // 在普通wiki目录树上，根节点标题不依赖 title
                mainRootMeta.title = spaceName
                treeData.metaStorage[rootToken] = mainRootMeta
            }
        } catch {
            DocsLogger.error("parse space info failed", error: error)
        }
        // parse space permission if need
        if needPermission {
            do {
                let permissionData = try data["user_space_perm"].rawData()
                let decoder = JSONDecoder()
                let spacePermission = try decoder.decode(WikiUserSpacePermission.self,
                                                         from: permissionData)
                treeData.userSpacePermission = spacePermission
            } catch {
                DocsLogger.error("parse space permission failed", error: error)
            }
        }
        return treeData
    }

    static func parseTreeData(treeData: JSON, spaceID: String) throws -> WikiTreeData {
        guard let nodesData = treeData["nodes"].dictionary,
              let childMapData = treeData["child_map"].dictionaryObject as? [String: [String]],
              let rootToken = treeData["root_token"].string else {
            DocsLogger.error("get_wiki_relation 数据解析错误")
            throw WikiError.dataParseError
        }
        // 游离树根节点
        let sharedTokens = treeData["shared"].arrayObject as? [String] ?? []
        var nodes: [String: WikiTreeNodeMeta] = [:]
        var sortIDMap: [String: Double] = [:]
        var parentMap: [String: String] = [:]

        // 解析 serverNode，同时更新 parentMap
        nodesData.values.forEach { nodeJSON in
            do {
                let data = try nodeJSON.rawData()
                let decoder = JSONDecoder()
                let node = try decoder.decode(WikiServerNode.self, from: data)
                let token = node.meta.wikiToken
                nodes[token] = node.meta
                parentMap[token] = node.parent
                sortIDMap[token] = node.sortID
                // 针对游离树一级节点做一些特殊处理
                if sharedTokens.contains(token) {
                    parentMap[token] = WikiTreeNodeMeta.sharedRootToken
                }
            } catch {
                DocsLogger.error("parse node json failed", error: error)
            }
        }
        // 处理与我分享游离树
        if !sharedTokens.isEmpty {
            let sharedRootNode = WikiTreeNodeMeta.createSharedRoot(spaceID: spaceID)
            nodes[sharedRootNode.wikiToken] = sharedRootNode
        }

        func convertToNodeChildren(token: String) -> NodeChildren? {
            guard let sortID = sortIDMap[token] else {
                DocsLogger.warning("sortID not found for token in childMap")
                return nil
            }
            return NodeChildren(wikiToken: token, sortID: sortID)
        }
        // 解析 childMap
        var childMap: [String: [NodeChildren]] = [:]
        childMapData.forEach { parentToken, childTokens in
            guard let meta = nodes[parentToken] else { return }
            // 这里跳过 shortcut 的 children
            if meta.isShortcut { return }
            let children = childTokens.compactMap(convertToNodeChildren(token:)).sorted(by: <)
            childMap[parentToken] = children
        }
        // 游离树场景为mainRoot赋空数组，防止展开时发送请求报错
        if nodes[rootToken] == nil {
            let mainRootNode = WikiTreeNodeMeta.createMainRoot(rootToken: rootToken, spaceID: spaceID)
            nodes[rootToken] = mainRootNode
        }
        // 开启互联网访问场景，若知识库是空库，后端返回的 childMap 没有 rootToken 的数据，导致节点内容全部为空，这里主动修正为空数组
        if childMap[rootToken] == nil {
            childMap[rootToken] = []
        }
        // childMap 中不包含游离根节点的父子关系，这里补充上
        if !sharedTokens.isEmpty {
            childMap[WikiTreeNodeMeta.sharedRootToken] = sharedTokens.compactMap(convertToNodeChildren(token:)).sorted(by: <)
        }

        let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childMap)
        return WikiTreeData(mainRootToken: rootToken,
                            metaStorage: nodes,
                            relation: relation)
    }

    public func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetChildV2,
                                        params: [
                                            "space_id": spaceID,
                                            "wiki_token": wikiToken,
                                            "expand_shortcut": true
                                        ])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    DocsLogger.error("get_wiki_child 接口解析失败")
                    throw WikiError.dataParseError
                }
                return try Self.parseGetChild(data: data, wikiToken: wikiToken)
            }
    }

    static func parseGetChild(data: JSON, wikiToken: String) throws -> ([NodeChildren], [WikiTreeNodeMeta]) {
        guard let childrenData = data[wikiToken].array else {
            DocsLogger.error("get_wiki_child 接口解析失败")
            throw WikiError.dataParseError
        }
        var nodes: [WikiTreeNodeMeta] = []
        var children: [NodeChildren] = []
        childrenData.forEach { nodeJSON in
            do {
                let data = try nodeJSON.rawData()
                let decoder = JSONDecoder()
                let node = try decoder.decode(WikiServerNode.self, from: data)
                let token = node.meta.wikiToken
                nodes.append(node.meta)
                children.append(NodeChildren(wikiToken: token, sortID: node.sortID))
            } catch {
                DocsLogger.error("parse node json failed", error: error)
            }
        }
        children.sort { $0.sortID < $1.sortID }
        return (children, nodes)
    }

    public func loadFavoriteList(spaceID: String) -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetStarList,
                                        params: [
                                            "space_id": spaceID,
                                            "expand_shortcut": true
                                        ])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    DocsLogger.error("get_star_list 接口 json 解析错误")
                    throw WikiError.dataParseError
                }
                return try Self.parseFavoriteList(data: data)
            }
    }

    static func parseFavoriteList(data: JSON) throws -> (WikiTreeRelation, [WikiTreeNodeMeta]) {
        let favoriteData = data["favorite_node_list"]
        guard let tokenList = favoriteData["root_list"].arrayObject as? [String],
              let nodesData = favoriteData["nodes"].dictionary else {
            DocsLogger.error("get_star_list 接口 data 解析错误")
            throw WikiError.dataParseError
        }
        // 保存后端返回的 parent
        var parentMap: [String: String] = [:]
        var children: [NodeChildren] = []
        var nodes: [WikiTreeNodeMeta] = []
        for (index, token) in tokenList.enumerated() {
            guard let nodeJSON = nodesData[token] else {
                DocsLogger.warning("node info not found", extraInfo: ["token": DocsTracker.encrypt(id: token)])
                continue
            }
            do {
                let nodeData = try nodeJSON.rawData()
                let decoder = JSONDecoder()
                let node = try decoder.decode(WikiServerNode.self, from: nodeData)
                nodes.append(node.meta)
                // 这里取到的 sortID 特指在收藏列表里的排序，与节点自身的 sortID 不同
                // 注意这里没有使用后端返回的 sortID，原因是收藏列表的排序与目录树相反，sortID 大的在前，与 relation 内的排序相反
                // 考虑到收藏列表的 sortID 目前没有实际的应用，这里暂时按照顺序重新计算 sortID，保证小的在前
                children.append(NodeChildren(wikiToken: token, sortID: Double(index * 10)))
                // 这里的 parent 是真实 parent，需要记录，避免存入 DB 时覆盖了正确的数据
                parentMap[node.meta.wikiToken] = node.parent
            } catch {
                DocsLogger.warning("get_star_list 存在 node 解析失败", error: error)
            }
        }
        let relation = WikiTreeRelation(nodeParentMap: parentMap,
                                        nodeChildrenMap: [
                                            WikiTreeNodeMeta.favoriteRootToken: children
                                        ])
        return (relation, nodes)
    }

    public func getSpacePermission(spaceId: String) -> Single<WikiSpacePermission> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetSpacePermission,
                                        params: ["space_id": spaceId])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { result in
                guard let data = try result?["data"][spaceId].rawData() else {
                    spaceAssertionFailure("can not parse node perm")
                    throw WikiError.dataParseError
                }
                do {
                    let perm = try JSONDecoder().decode(WikiSpacePermission.self, from: data)
                    return perm
                } catch {
                    spaceAssertionFailure("can not parse node perm\(error)")
                    throw WikiError.dataParseError
                }
            }
    }

    public func getNodeMetaInfo(wikiToken: String) -> Single<WikiServerNode> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getWikiInfoV2,
                                        params: [
                                            "wiki_token": wikiToken,
                                            "expand_shortcut": true,
                                            "with_deleted": true
                                        ])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let json = json else {
                    throw WikiError.dataParseError
                }
                let data = try json["data"].rawData()
                let decoder = JSONDecoder()
                let node = try decoder.decode(WikiServerNode.self, from: data)
                return node
            }
    }

    // 批量获取树节点信息，用于批量协同添加场景
    public func batchGetNodeMetaInfo(wikiTokens: [String]) -> Single<[WikiServerNode]> {
        let query = "?" + wikiTokens.map { "wiki_tokens=\($0)" }.joined(separator: "&")
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiBatchGetWikiInfoV2 + query, params: nil)
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { result in
                guard let json = result,
                      let nodesJSON = json["data"]["entities"]["nodes"].dictionary?.values else {
                          DocsLogger.error("m_get_node_info 接口解析错误")
                          throw WikiError.dataParseError
                      }
                let decoder = JSONDecoder()
                let nodes = nodesJSON.compactMap { nodeJSON -> WikiServerNode? in
                    guard let dataString = nodeJSON.rawString(),
                          let data = dataString.data(using: .utf8) else {
                              return nil
                          }
                    do {
                        let node = try decoder.decode(WikiServerNode.self, from: data)
                        return node
                    } catch {
                        DocsLogger.error("m_get_node_info 数据解析错误", error: error)
                        return nil
                    }
                }
                return nodes
            }
    }

    /// 收藏 or 取消收藏知识库
    /// - Parameter spaceID: 知识库 ID
    /// - Parameter isAdd: 是否添加收藏
    /// - Returns: onNext返回是否收藏的状态
    public func setStarSpaceV2(spaceID: String, isAdd: Bool) -> Observable<Bool> {
        let path = isAdd ? OpenAPI.APIPath.wikiStarSpaceV2 : OpenAPI.APIPath.wikiUnstarSpaceV2
        return RxDocsRequest<JSON>().request(path,
                                             params: ["space_id": spaceID],
                                             method: .POST,
                                             encoding: .jsonEncodeDefault,
                                             needVerifyData: true,
                                             callbackQueue: Self.dataQueue)
            .flatMap { (result) -> Observable<Bool> in

                guard let json = result,
                    let code = json["code"].int else {
                        return Observable<Bool>.error(WikiError.dataParseError)
                }
                if code != 0 {
                    return Observable<Bool>.error(WikiError.serverError(code: code))
                }
                guard let result = json["data"]["is_success"].bool, result else {
                    return Observable<Bool>.error(WikiError.dataParseError)
                }
                return Observable<Bool>.just(isAdd)
            }
    }

    /// 收藏 or 取消收藏节点
    /// - Parameters:
    ///   - spaceId: 该节点spaceid
    ///   - wikiToken: 该节点wikiToken
    ///   - isAdd: 是否收藏
    /// - Returns: onNext返回是否收藏的状态
    public func setStarNode(spaceId: String,
                            wikiToken: String,
                            isAdd: Bool) -> Single<Bool> {
        let path = isAdd ? OpenAPI.APIPath.wikiStarNode : OpenAPI.APIPath.wikiUnStarNode
        let request = DocsRequest<JSON>(path: path, params: ["space_id": spaceId, "wiki_token": wikiToken])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { result in
                guard let json = result,
                    let code = json["code"].int else {
                        throw WikiError.dataParseError
                }
                if code != 0 {
                    throw WikiError.serverError(code: code)
                }
                guard let result = json["data"]["is_success"].bool, result else {
                    throw WikiError.dataParseError
                }
                return isAdd
            }
    }

    public func getNodePermission(spaceId: String,
                                  wikiToken: String) -> Single<WikiTreeNodePermission> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetNodePermission,
                                        params: ["space_id": spaceId, "wiki_token": wikiToken])
            .set(method: .GET)
            .set(needVerifyData: true)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { result in
                guard let data = try result?["data"].rawData() else {
                    spaceAssertionFailure("can not parse node perm")
                    throw WikiError.dataParseError
                }
                do {
                    let perm = try JSONDecoder().decode(WikiTreeNodePermission.self, from: data)
                    return perm
                } catch {
                    spaceAssertionFailure("can not parse node perm\(error)")
                    throw WikiError.dataParseError
                }
            }
    }

    // 查询 wikiToken 是否在 space 内
    public enum WikiObjInfo {
        public struct SpaceInfo {
            public let wikiToken: String
            public let objToken: String
            public let docsType: DocsType
            public let url: URL
        }
        case inWiki(meta: WikiNodeMeta)
        case inSpace(info: SpaceInfo)
    }

    // 返回 objInfo 和 logID
    public func getWikiObjInfo(wikiToken: String) -> Single<(WikiObjInfo, String?)> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetObjInfo, params: ["wiki_token": wikiToken,
                                                                                       "with_deleted": true])
            .set(method: .GET)
        return request.rxStartWithLogID()
            .observeOn(Self.dataQueueScheduler)
            .map { json, logID in
                guard let data = json?["data"] else {
                    throw WikiError.dataParseError
                }
                guard let isWiki = data["is_wiki"].bool,
                      let objToken = data["obj_token"].string,
                      let objTypeValue = data["obj_type"].int else {
                    DocsLogger.error("missing required field")
                    throw WikiError.dataParseError
                }
                let docType = DocsType(rawValue: objTypeValue)
                if isWiki {
                    guard let spaceID = data["space_id"].string else {
                        DocsLogger.error("invalid space_id field")
                        throw WikiError.dataParseError
                    }
                    let meta = WikiNodeMeta(wikiToken: wikiToken,
                                            objToken: objToken,
                                            docsType: docType,
                                            spaceID: spaceID)
                    return (.inWiki(meta: meta), logID)
                } else {
                    guard let url = data["obj_url"].url else {
                        DocsLogger.error("invalid obj_url field")
                        throw WikiError.dataParseError
                    }
                    let info = WikiObjInfo.SpaceInfo(wikiToken: wikiToken,
                                                     objToken: objToken,
                                                     docsType: docType,
                                                     url: url)
                    return (.inSpace(info: info), logID)
                }
            }
    }

    public func starInExplorer(objToken: String, objType: DocsType, isAdd: Bool) -> Single<Void> {
        return DocsContainer.shared.resolve(SpaceManagementAPI.self)!.update(isFavorites: isAdd, objToken: objToken, docType: objType)
    }

    public func getMoveNodeAuthorizedUserInfo(wikiToken: String, spaceID: String) -> Single<WikiAuthorizedUserInfo> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiGetMoveNodeAuthorizedUserInfo,
                                        params: [
                                            "wiki_token": wikiToken,
                                            "space_id": spaceID
                                        ])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json -> WikiAuthorizedUserInfo in
                guard let data = json?["data"] else {
                    throw WikiError.dataParseError
                }
                guard let userID = data["id"].string,
                      let userName = data["name"].string,
                      let i18nNames = data["i18n_names"].dictionaryObject as? [String: String] else {
                    DocsLogger.error("missing required field")
                    throw WikiError.dataParseError
                }
                let aliasInfo = UserAliasInfo(json: data["display_name"])
                return WikiAuthorizedUserInfo(userID: userID, userName: userName, i18nNames: i18nNames, aliasInfo: aliasInfo)
            }
    }

    public func applyMoveToWiki(sourceMeta: WikiMeta,
                                currentParentWikiToken: String,
                                targetMeta: WikiMeta,
                                reason: String?,
                                authorizedUserID: String) -> Single<Void> {
        var params: [String: Any] = [
            "old_space_id": sourceMeta.spaceID,
            "new_space_id": targetMeta.spaceID,
            "old_parent_wiki_token": currentParentWikiToken,
            "new_parent_wiki_token": targetMeta.wikiToken,
            "wiki_token": sourceMeta.wikiToken,
            "to_last": true,
            "authorized_userId": authorizedUserID
        ]
        if let reason = reason, !reason.isEmpty {
            params["reason"] = reason
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiApplyMoveNode, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { _ in
                return
            }
    }

    public func applyMoveToSpace(wikiToken: String,
                                 location: MoveToSpaceLocation,
                                 reason: String?,
                                 authorizedUserID: String) -> Single<Void> {
        var params: [String: Any] = [
            "wiki_token": wikiToken,
            "authorized_user_id": authorizedUserID
        ]
        if let reason = reason, !reason.isEmpty {
            params["reason"] = reason
        }
        switch location {
        case .ownerSpace:
            params["move_to_owner_space"] = true
        case let .folder(folderToken):
            params["space_folder_token"] = folderToken
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiApplyMoveToSpace,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { _ in
                return
            }
    }

    public enum MoveToSpaceLocation {
        case ownerSpace
        case folder(folderToken: String)
    }

    // 发起 + 轮询复合接口
    public func moveToSpace(wikiToken: String,
                     location: MoveToSpaceLocation,
                     synergyUUID: String? = nil) -> Single<WikiObjInfo.SpaceInfo> {
        Self.startMoveToSpace(wikiToken: wikiToken,
                              location: location,
                              synergyUUID: synergyUUID)
        .flatMap { taskID -> Single<WikiObjInfo.SpaceInfo> in
            return Self.pollingMoveToSpaceStatus(wikiToken: wikiToken, taskID: taskID, delayMS: 1000)
        }
        .timeout(.seconds(30), scheduler: MainScheduler.instance)
    }

    private static func pollingMoveToSpaceStatus(wikiToken: String, taskID: String, delayMS: Int) -> Single<WikiObjInfo.SpaceInfo> {
        Self.checkMoveToSpaceStatus(taskID: taskID)
            .flatMap { status -> Single<WikiObjInfo.SpaceInfo> in
                switch status {
                case .moving:
                    // 延迟后再请求，并延长后续请求的延迟
                    return Self.pollingMoveToSpaceStatus(wikiToken: wikiToken, taskID: taskID, delayMS: delayMS + 500)
                        .delaySubscription(.milliseconds(delayMS), scheduler: MainScheduler.instance)
                case let .succeed(objToken, objType, spaceURL):
                    return .just(WikiObjInfo.SpaceInfo(wikiToken: wikiToken, objToken: objToken, docsType: objType, url: spaceURL))
                case .failed:
                    // 非预期失败
                    throw WikiError.invalidWikiError
                }
            }
    }

    private static func startMoveToSpace(wikiToken: String,
                                         location: MoveToSpaceLocation,
                                         synergyUUID: String? = nil) -> Single<String> {
        var params: [String: Any] = [
            "wiki_token": wikiToken
        ]
        switch location {
        case .ownerSpace:
            params["move_to_owner_space"] = true
        case let .folder(folderToken):
            params["space_folder_token"] = folderToken
        }
        if let synergyUUID = synergyUUID {
            params["synergy_uuid"] = synergyUUID
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiStartMoveToSpace,
                                        params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    throw WikiError.dataParseError
                }
                guard let taskID = data["task_id"].string else {
                    DocsLogger.error("missing required field")
                    throw WikiError.dataParseError
                }
                return taskID
            }
    }

    enum MoveToSpaceStatus {
        case moving
        case succeed(objToken: String, objType: DocsType, spaceURL: URL)
        case failed
    }
    private static func checkMoveToSpaceStatus(taskID: String) -> Single<MoveToSpaceStatus> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiCheckMoveToSpaceStatus,
                                        params: ["task_id": taskID])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    throw WikiError.dataParseError
                }
                guard let status = data["status"].int else {
                    DocsLogger.error("missing required field")
                    throw WikiError.dataParseError
                }
                switch status {
                case 1:
                    return .moving
                case 3:
                    return .failed
                case 2:
                    guard let objTypeValue = data["obj_type"].int,
                          let objToken = data["obj_token"].string,
                          let spaceURL = data["url"].url else {
                        DocsLogger.error("missing required field")
                        throw WikiError.dataParseError
                    }
                    return .succeed(objToken: objToken, objType: DocsType(rawValue: objTypeValue), spaceURL: spaceURL)
                default:
                    spaceAssertionFailure("unknown status code: \(status) when check move to space status")
                    return .failed
                }
            }
    }

    public func copyWikiNode(sourceMeta: WikiMeta,
                             objType: DocsType,
                             targetMeta: WikiMeta,
                             title: String,
                             synergyUUID: String?) -> Single<(WikiServerNode, URL)> {
        let needAsync = objType == .sheet
        return WorkspaceManagementAPI.Wiki.copyToWiki(sourceMeta: sourceMeta,
                                                      targetMeta: targetMeta,
                                                      title: title,
                                                      needAsync: needAsync,
                                                      synergyUUID: synergyUUID)
        .map { json, url in
            let data = try json.rawData()
            let decoder = JSONDecoder()
            let node = try decoder.decode(WikiServerNode.self, from: data)
            return (node, url)
        }
    }

    public func copyWikiToSpace(sourceSpaceID: String, sourceWikiToken: String, objType: DocsType, title: String, folderToken: String) -> Single<(String, URL)> {
        let needAsync = objType == .sheet
        return WorkspaceManagementAPI.Wiki.copyToSpace(sourceWikiToken: sourceWikiToken,
                                                       sourceSpaceID: sourceSpaceID,
                                                       title: title,
                                                       folderToken: folderToken,
                                                       needAsync: needAsync)
    }

    public func shortcutWikiToSpace(objToken: String, objType: DocsType, folderToken: String) -> Single<(String, URL)> {
        WorkspaceManagementAPI.Wiki.shortcutToSpace(objToken: objToken,
                                                    objType: objType,
                                                    folderToken: folderToken)
    }

    public func update(newTitle: String, wikiToken: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiUpdateTitle, params: ["wiki_token": wikiToken, "name": newTitle])
            .set(method: .POST)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { data -> Void in
                guard let code = data?["code"].int else {
                    throw WikiError.dataParseError
                }
                guard code == 0 else {
                    throw WikiError.serverError(code: code)
                }
            }
            .asCompletable()
    }
    
    public func getStarWikiSpaces(lastLabel: String? = nil) -> Single<WorkSpaceInfo> {
        var params: [String: Any] = ["size": 100]
        if let lastLabel {
            params["last_label"] = lastLabel
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getStarWikiSpace, params: params).set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let json, let code = json["code"].int else {
                    throw WikiError.invalidDataError
                }
                guard code == 0 else {
                    throw WikiError.serverError(code: code)
                }
                
                let spaceData = json["data"]["spaces"].arrayValue
                let decoder = JSONDecoder()
                let spaces: [WikiSpace] = spaceData.compactMap { json in
                    guard let data = try? json.rawData() else { return nil }
                    return try? decoder.decode(WikiSpace.self, from: data)
                }
                let lastLabel = json["data"]["last_label"].stringValue
                let hasMore = json["data"]["has_more"].boolValue
                return WorkSpaceInfo(spaces: spaces, lastLabel: lastLabel, hasMore: hasMore)
            }
    }
    
    public func getWikiFilter() -> Single<WikiFilterList> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiFilterList, params: ["need_filter": true]).set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let json, let code = json["code"].int else {
                    throw WikiError.invalidDataError
                }
                guard code == 0 else {
                    throw WikiError.serverError(code: code)
                }
                
                let classData = json["data"]["class_list"].arrayValue
                let decoder = JSONDecoder()
                let filters: [WikiFilter] = classData.compactMap { json in
                    guard let data = try? json.rawData() else { return nil }
                    return try? decoder.decode(WikiFilter.self, from: data)
                }
                return WikiFilterList(filters: filters)
            }
    }
    
    public func getWikiLibrarySpaceId() -> Single<String> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiLibrarySpaceId, params: nil).set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let json, let code = json["code"].int else {
                    throw WikiError.invalidDataError
                }
                
                guard code == 0 else {
                    throw WikiError.serverError(code: code)
                }
                guard let spaceId = json["data"]["space_id"].string else {
                    throw WikiError.dataParseError
                }
                return spaceId
            }
    }
    
    // 创建我的文档库
    public func createMyLibrary(uniqID: String) -> Single<String> {
        // uniq_id: 客户端传随机字符串，保证每次不同，后端根据uniq_id判断请求是否是同一个
        // space_type: 知识库空间类型 0团队 1个人 2文档库
        // name: 创建的文档库名称，客户端传任意字符串，后端会自己生成名称
        let params: [String: Any] = ["uniq_id": uniqID,
                                     "space_type": 2,
                                     "name": "My_Library"]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.createWikiMyLibrary, params: params).set(method: .POST)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .flatMap { [weak self] json in
                guard let self, let json, let async = json["data"]["async"].bool else {
                    throw WikiError.invalidDataError
                }
                // 不管异步还是同步，只要创建成功就立即返回spaceId
                if let spaceId = json["data"]["space"]["space_id"].string {
                    return .just(spaceId)
                }
                // 异步走异步流程
                if async {
                    return self.asyncCreateMyLibrary(params: params, delayMS: 1000)
                } else {
                    throw WikiError.invalidWikiError
                }
            }
            .timeout(30, scheduler: MainScheduler.instance)
    }
    
    private enum CreateLibraryStatus {
        case creating
        case succeed(spaceId: String)
        case failed
    }
    
    private func asyncCreateMyLibrary(params: [String: Any], delayMS: Int) -> Single<String> {
        pollingCreateLibraryStatus(params: params)
            .flatMap { [weak self] status in
                guard let self else {
                    return .never()
                }
                switch status {
                case .creating:
                    return self.asyncCreateMyLibrary(params: params, delayMS: delayMS + 500)
                        .delaySubscription(.milliseconds(delayMS), scheduler: MainScheduler.instance)
                case .succeed(let spaceId):
                    return .just(spaceId)
                case .failed:
                    // 非预期失败
                    DocsLogger.error("[wiki]: check create my library status failed")
                    throw WikiError.invalidWikiError
                }
            }
    }
    
    private func pollingCreateLibraryStatus(params: [String: Any]) -> Single<CreateLibraryStatus> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.createWikiMyLibrary, params: params).set(method: .POST)
        return request.rxStart()
            .map { json in
                guard let data = json?["data"] else {
                    throw WikiError.dataParseError
                }
                guard let status = data["task_status"].int else {
                    throw WikiError.dataParseError
                }
                switch status {
                case 1:
                    return .creating
                case 2:
                    guard let spaceId = data["space"]["space_id"].string else {
                        throw WikiError.dataParseError
                    }
                    return .succeed(spaceId: spaceId)
                case 3:
                    return .failed
                default:
                    spaceAssertionFailure("unknown status code: \(status) when check create my library status")
                    DocsLogger.error("unknown status code: \(status) when check create my library status")
                    return .failed
                }
            }
    }
    
    public func pinInExplorer(addPin: Bool, objToken: String, docsType: DocsType) -> Completable {
        let path = addPin ? OpenAPI.APIPath.addPins : OpenAPI.APIPath.removePins
        var params: [String: Any] = ["token": objToken, "type": docsType.rawValue]
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable, addPin {
            params["pin_to_first"] = true
        }
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .POST)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let json, let code = json["code"].int else {
                    throw WikiError.invalidDataError
                }
                guard code == 0 else {
                    throw WikiError.serverError(code: code)
                }
            }.asCompletable()
    }
    
    public func getStarWikiSpaceTreeList() -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
        return getStarWikiSpaces()
            .observeOn(Self.dataQueueScheduler)
            .map { spaceInfo in
                // 置顶知识库最多展示40个
                let spaces = spaceInfo.spaces.prefix(40)
                // 无知识库时隐藏置顶-知识库整部分，因此不构造虚拟根节点，直接返回空数据
                if spaces.isEmpty {
                    return (WikiTreeRelation(), [])
                }
                
                var relation = WikiTreeRelation()
                let favoriteWikiSpaceRoot = WikiTreeNodeMeta.createMutilTreeRoot()
                relation.setup(rootToken: favoriteWikiSpaceRoot.wikiToken)
                
                var metas = [WikiTreeNodeMeta]()
                
                for (index, space) in spaces.enumerated() {
                    // 将space列表空间转化为wikiMeta，与虚拟节点构建父子关系
                    var meta = WikiTreeNodeMeta(wikiToken: space.rootToken,
                                                spaceID: space.spaceID,
                                                objToken: "",
                                                objType: .unknownDefaultType,
                                                title: space.spaceName,
                                                hasChild: true,
                                                secretKeyDeleted: false,
                                                isExplorerStar: false,
                                                nodeType: .mainRoot,
                                                originDeletedFlag: 0,
                                                isExplorerPin: false,
                                                iconInfo: space.iconInfo?.infoString ?? "", 
                                                url: nil)
                    meta.wikiSpaceIconType = space.iconInfo?.iconType
                    metas.append(meta)
                    relation.insert(wikiToken: meta.wikiToken, sortID: Double(index), parentToken: WikiTreeNodeMeta.mutilTreeRootToken)
                }
                // 存DB
                WikiStorage.shared.update(spaces: Array(spaces))
                return (relation, metas)
            }
    }
    
    public func loadPinDocumentList() -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getPinDocumentList, params: ["filter_folder": true]).set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    throw WikiError.invalidDataError
                }
                
               
                return try Self.parseNewTabList(data: data, spaceId: WikiTreeNodeMeta.clipDocumentSpaceID, rootToken: WikiTreeNodeMeta.clipDocumentRootToken)
            }
    }
    
    public func loadShareList() -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
        let params: [String: Any] = [
            "length": 10,
            "rank": 9,
            "asc": false,
            "forbidden_obj_type": DocsType.folder.rawValue
        ]
        
        var path = OpenAPI.APIPath.getNewTabShareList
        for (index, value) in params.enumerated() {
            if index == 0 {
                path += "?\(value.key)=\(value.value)"
            } else {
                path += "&\(value.key)=\(value.value)"
            }
        }
        
        let objTypeArray: [DocsType] = [.doc, .docX, .sheet, .bitable, .mindnote, .slides, .file]
        objTypeArray.forEach {
            path += "&obj_type=\($0.rawValue)"
        }
        
        let request = DocsRequest<JSON>(path: path, params: nil).set(method: .GET)
        return request.rxStart()
            .observeOn(Self.dataQueueScheduler)
            .map { json in
                guard let data = json?["data"] else {
                    throw WikiError.invalidDataError
                }
                return try Self.parseNewTabList(data: data, spaceId: WikiTreeNodeMeta.homeSharedSpaceID, rootToken: WikiTreeNodeMeta.homeSharedRootToken)
            }
    }
    
    private static func parseNewTabList(data: JSON, spaceId: String, rootToken: String) throws -> (WikiTreeRelation, [WikiTreeNodeMeta]) {
        guard let nodeList = data["node_list"].arrayObject as? [String] else {
            // node_list字段为null, 返回空数据
            return (WikiTreeRelation(), [])
        }
        guard let nodeMap = data["entities"]["nodes"].dictionary,
              let spaceMap = data["entities"]["space"].dictionary else {
            throw WikiError.dataParseError
        }
        
        var parentMap: [String: String] = [:]
        var children: [NodeChildren] = []
        var metas: [WikiTreeNodeMeta] = []
        for (index, token) in nodeList.enumerated() {
            do {
                if let nodeJson = nodeMap[token],
                   let parentToken = nodeJson["parent_wiki_token"].string,
                   let nodeData = try? nodeJson.rawData() {
                    let meta = try JSONDecoder().decode(WikiTreeNodeMeta.self, from: nodeData)
                    children.append(NodeChildren(wikiToken: token, sortID: Double(index)))
                    parentMap[meta.wikiToken] = parentToken
                    metas.append(meta)
                } else if let spaceEntryJson = spaceMap[token],
                          let typeRaw = spaceEntryJson["type"].int,
                          let objToken = spaceEntryJson["obj_token"].string {
                    children.append(NodeChildren(wikiToken: token, sortID: Double(index)))
                    let nodeToken = data["token"].string ?? ""
                    let entry = SpaceEntryFactory.createEntry(type: DocsType(rawValue: typeRaw), nodeToken: nodeToken, objToken: objToken)
                    entry.updatePropertiesFrom(spaceEntryJson)
                    let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)!
                    dataCenterAPI.insert(entries: [entry])
                    // space文档的父节点假定为虚拟的根节点
                    parentMap[entry.objToken] = rootToken
                    // 将spaceEntry转换为wiki目录树数据类型，兼容复用目录树
                    var meta = WikiTreeNodeMeta(wikiToken: token,
                                                spaceID: spaceId,
                                                objToken: token,
                                                objType: entry.docsType,
                                                title: entry.name,
                                                hasChild: false,
                                                secretKeyDeleted: entry.secretKeyDelete ?? false,
                                                isExplorerStar: entry.stared,
                                                nodeType: .normal,
                                                originDeletedFlag: entry.deleteFlag ?? 0,
                                                isExplorerPin: entry.stared,
                                                iconInfo: entry.iconInfo ?? "", 
                                                url: entry.url.absoluteString)
                    meta.setNodeLocation(location: .space(file: entry))
                    if let ownerId = entry.ownerID {
                        meta.detailInfo = WikiTreeNodeDetailInfo(ownerId: ownerId)
                    }
                    metas.append(meta)
                }
            } catch {
                DocsLogger.error("prase pin document data error")
            }
        }
        let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: [rootToken: children])
        return (relation, metas)
    }
}
