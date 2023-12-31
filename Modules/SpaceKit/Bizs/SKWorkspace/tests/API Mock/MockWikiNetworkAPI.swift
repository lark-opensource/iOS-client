//
//  WikiNetworkAPI+Mock.swift
//  SKWikiV2_Tests
//
//  Created by Weston Wu on 2022/6/23.
//

import Foundation
import SKCommon
import OHHTTPStubs
import SwiftyJSON
@testable import SKWorkspace
import SpaceInterface
import RxSwift
import SpaceInterface
import SKInfra

class MockWikiNetworkAPI: WikiTreeNetworkAPI {

    static func mock(path: String, jsonFile: String) {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(path)
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile(jsonFile, MockWikiNetworkAPI.self)!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
    }

    static func mock(path: String, data: [String: Any] = [:], code: Int = 0, message: String = "Success") {
        mock(path: path, json: [
            "code": code,
            "msg": message,
            "data": data
        ])
    }

    static func mock(path: String, json: [String: Any]) {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(path)
        }, response: { _ in
            HTTPStubsResponse(jsonObject: json,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
    }

    // 以下的几个方法子类可以按需重写
    enum MockNetworkError: Error {
        case mockNotImplement
        case expectError
    }

    func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
        .error(MockNetworkError.mockNotImplement)
    }

    func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
        .error(MockNetworkError.mockNotImplement)
    }

    func loadFavoriteList(spaceID: String) -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
        .error(MockNetworkError.mockNotImplement)
    }

    func getNodeMetaInfo(wikiToken: String) -> Single<WikiServerNode> {
        .error(MockNetworkError.mockNotImplement)
    }

    func batchGetNodeMetaInfo(wikiTokens: [String]) -> Single<[WikiServerNode]> {
        .error(MockNetworkError.mockNotImplement)
    }

    func createNode(spaceID: String,
                    parentWikiToken: String,
                    template: TemplateModel?,
                    objType: DocsType,
                    synergyUUID: String?) -> Single<WikiServerNode> {
        .error(MockNetworkError.mockNotImplement)
    }

    func createShortcut(spaceID: String,
                        parentWikiToken: String,
                        originWikiToken: String,
                        title: String?,
                        synergyUUID: String?) -> Single<WikiServerNode> {
        .error(MockNetworkError.mockNotImplement)
    }

    func deleteNode(_ wikiToken: String,
                    spaceId: String,
                    canApply: Bool,
                    synergyUUID: String?) -> Maybe<WikiAuthorizedUserInfo> {
        .error(MockNetworkError.mockNotImplement)
    }

    func applyDelete(wikiMeta: WikiMeta,
                     isSingleDelete: Bool,
                     reason: String?,
                     reviewerID: String) -> Completable {
        .error(MockNetworkError.mockNotImplement)
    }

    // 移动
    func moveNode(sourceMeta: WikiMeta,
                  originParent: String,
                  targetMeta: WikiMeta,
                  synergyUUID: String?) -> Single<Double> {
        .error(MockNetworkError.mockNotImplement)
    }
    // 收藏
    func setStarNode(spaceId: String,
                     wikiToken: String,
                     isAdd: Bool) -> Single<Bool> {
        .error(MockNetworkError.mockNotImplement)
    }
    // 节点权限
    func getNodePermission(spaceId: String,
                           wikiToken: String) -> Single<WikiTreeNodePermission> {
        .error(MockNetworkError.mockNotImplement)
    }
    // 空间权限
    func getSpacePermission(spaceId: String) -> Single<WikiSpacePermission> {
        .error(MockNetworkError.mockNotImplement)
    }

    func update(newTitle: String, wikiToken: String) -> Completable {
        .error(MockNetworkError.mockNotImplement)
    }

    func getWikiObjInfo(wikiToken: String) -> Single<(WikiObjInfo, String?)> {
        .error(MockNetworkError.mockNotImplement)
    }

    func starInExplorer(objToken: String, objType: DocsType, isAdd: Bool) -> Single<Void> {
        .error(MockNetworkError.mockNotImplement)
    }

    // 获取申请移动的审批人信息
    func getMoveNodeAuthorizedUserInfo(wikiToken: String, spaceID: String) -> Single<WikiAuthorizedUserInfo> {
        .error(MockNetworkError.mockNotImplement)
    }

    func applyMoveToWiki(sourceMeta: WikiMeta,
                         currentParentWikiToken: String,
                         targetMeta: WikiMeta,
                         reason: String?,
                         authorizedUserID: String) -> Single<Void> {
        .error(MockNetworkError.mockNotImplement)
    }
    // 申请移动节点到 space
    func applyMoveToSpace(wikiToken: String,
                          location: WikiMoveToSpaceLocation,
                          reason: String?,
                          authorizedUserID: String) -> Single<Void> {
        .error(MockNetworkError.mockNotImplement)
    }

    // 发起移动到 space 操作
    func moveToSpace(wikiToken: String,
                     location: WikiMoveToSpaceLocation,
                     synergyUUID: String?) -> Single<WikiObjInfo.SpaceInfo> {
        .error(MockNetworkError.mockNotImplement)
    }

    func copyWikiNode(sourceMeta: WikiMeta,
                      objType: DocsType,
                      targetMeta: WikiMeta,
                      title: String,
                      synergyUUID: String?) -> Single<(WikiServerNode, URL)> {
        .error(MockNetworkError.mockNotImplement)
    }

    // 返回 objToken 和 URL
    func copyWikiToSpace(sourceSpaceID: String, sourceWikiToken: String, objType: DocsType, title: String, folderToken: String) -> Single<(String, URL)> {
        .error(MockNetworkError.mockNotImplement)
    }

    // 返回 nodeToken 和 URL
    func shortcutWikiToSpace(objToken: String, objType: DocsType, folderToken: String) -> Single<(String, URL)> {
        .error(MockNetworkError.mockNotImplement)
    }

    func rxGetCoupleSpaceInfo(firstSpaceId: String, secondSpaceId: String) -> Observable<(WikiSpace, WikiSpace)> {
        .error(MockNetworkError.mockNotImplement)
    }
    
    
    func getStarWikiSpaces(lastLabel: String?) -> RxSwift.Single<WorkSpaceInfo> {
        .error(MockNetworkError.mockNotImplement)
    }
    
    func getWikiFilter() -> RxSwift.Single<WikiFilterList> {
        .error(MockNetworkError.mockNotImplement)
    }
    // wikispace list接口
    func rxGetWikiSpacesV2(lastLabel: String, size: Int, type: Int?, classId: String?) -> RxSwift.Single<WorkSpaceInfo> {
        .error(MockNetworkError.mockNotImplement)
    }
    
    func pinInExplorer(addPin: Bool, objToken: String, docsType: DocsType) -> RxSwift.Completable {
        .error(MockNetworkError.mockNotImplement)
    }
    
    func getStarWikiSpaceTreeList() -> RxSwift.Single<(SKWorkspace.WikiTreeRelation, [SKWorkspace.WikiTreeNodeMeta])> {
        .error(MockNetworkError.mockNotImplement)
    }
    
    func loadPinDocumentList() -> RxSwift.Single<(SKWorkspace.WikiTreeRelation, [SKWorkspace.WikiTreeNodeMeta])> {
        .error(MockNetworkError.mockNotImplement)
    }
}

extension MockWikiNetworkAPI {

    static func mockGetWikiSpacesV2(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.getAllWikiSpaceV2New, jsonFile: path.fullPath)
    }

    static func mockGetRecentWikiEntities(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.getRecentVisitWikiV2, jsonFile: path.fullPath)
    }

    static func mockGetNodeMeta(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiNodeTypeV2, jsonFile: path.fullPath)
    }

    static func mockReportBrowser(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiBrowserReport, jsonFile: path.fullPath)
    }

    static func mockGetSpace(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetSpaceInfoV2, jsonFile: path.fullPath)
    }

    static func mockGetWikiMembers(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetMembers, jsonFile: path.fullPath)
    }

    static func mockGetNodeInfo(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.getWikiInfoV2, jsonFile: path.fullPath)
    }

    static func mockBatchGetNodeInfo(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiBatchGetWikiInfoV2, jsonFile: path.fullPath)
    }

    static func mockGetTreeInfo(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetRelationV2, jsonFile: path.fullPath)
    }

    static func mockGetChildren(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetChildV2, jsonFile: path.fullPath)
    }

    static func mockCreateNode(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiAddRelationV2, jsonFile: path.fullPath)
    }

    static func mockDeleteNode(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiDeleteNodeV2, jsonFile: path.fullPath)
    }

    static func mockMoveNode(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiMoveNodeV2, jsonFile: path.fullPath)
    }

    static func mockGetSpacePermission(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetSpacePermission, jsonFile: path.fullPath)
    }

    static func mockStarSpace(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiStarSpaceV2, jsonFile: path.fullPath)
        mock(path: OpenAPI.APIPath.wikiUnstarSpaceV2, jsonFile: path.fullPath)
    }

    static func mockStarNode(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiStarNode, jsonFile: path.fullPath)
        mock(path: OpenAPI.APIPath.wikiUnStarNode, jsonFile: path.fullPath)
    }

    static func mockGetFavoriteList(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetStarList, jsonFile: path.fullPath)
    }

    static func mockGetNodePermission(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetNodePermission, jsonFile: path.fullPath)
    }

    static func mockUpdateTitle(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiUpdateTitle, jsonFile: path.fullPath)
    }

    static func mockGetWikiObjInfo(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetObjInfo, jsonFile: path.fullPath)
    }

    static func mockStarInSpace(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.addFavorites, jsonFile: path.fullPath)
        mock(path: OpenAPI.APIPath.removeFavorites, jsonFile: path.fullPath)
    }

    static func mockGetMoveNodeAuthorizedUserInfo(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiGetMoveNodeAuthorizedUserInfo, jsonFile: path.fullPath)
    }

    static func mockApplyMoveToWiki(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiApplyMoveNode, jsonFile: path.fullPath)
    }

    static func mockApplyMoveToSpace(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiApplyMoveToSpace, jsonFile: path.fullPath)
    }

    static func mockStartMoveToSpace(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiStartMoveToSpace, jsonFile: path.fullPath)
    }

    static func mockCheckMoveToSpaceStatus(path: PathRepresentable) {
        mock(path: OpenAPI.APIPath.wikiCheckMoveToSpaceStatus, jsonFile: path.fullPath)
    }
}
