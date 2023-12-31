//
//  SpaceNetworkAPI+Mock.swift
//  SKSpace_Tests
//
//  Created by Weston Wu on 2022/6/9.
//

import Foundation
import SKCommon
import OHHTTPStubs
import SwiftyJSON
import SKInfra

enum MockNetworkResponse: String {
    // code: 0 成功
    case plainSuccess = "plain-success.json"
    // code: 4 无权限
    case noPermission = "no-permission.json"
    // code: 900021001 密钥删除
    case secretKeyDeleted = "secret-key-deleted.json"
    // code: 900004230 数据迁移中，内容被锁定
    case dataLockedForMigration = "data-locked-for-migration.json"
    // code: 900004510 合规-同品牌的跨租户跨Geo
    case unavailableForCrossTenantGeo = "unavailable-for-cross-tenant-geo.json"
    // code: 900004511 合规-跨品牌不允许
    case unavailableForCrossBrand = "unavailable-for-cross-brand.json"
    // 创建副本成功
    case createShortcutSuccess = "create-shortcut-success.json"
    // 最近列表
    case recentListSuccess = "recent-list-success.json"
    case recentListFailed = "space-list-failed.json"
    case recentListDelete = "recent-delete-file.json"
    // 共享文件夹列表
    case sharefolderListSuccess = "share-folder-success.json"
    
}

class MockSpaceNetworkAPI {

    static func mock(path: String, jsonFile: String) {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(path)
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("JSON/" + jsonFile, MockSpaceNetworkAPI.self)!,
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

    static func mockRename<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.rename, jsonFile: type.rawValue)
    }

    static func mockRenameV2<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.renameV2, jsonFile: type.rawValue)
    }

    static func mockRenameSheet<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.renameSheet, jsonFile: type.rawValue)
    }

    static func mockRenameBitable<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.renameBitable, jsonFile: type.rawValue)
    }
    
    static func mockRenameSlides<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.renameSlides, jsonFile: type.rawValue)
    }

    static func mockMove<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.move, jsonFile: type.rawValue)
    }

    static func mockMoveV2<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.moveV2, jsonFile: type.rawValue)
    }

    static func mockCreateShortCut<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.addShortCutTo, jsonFile: type.rawValue)
    }

    static func mockAddTo<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.addTo, jsonFile: type.rawValue)
    }

    static func mockDelete<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.deleteByObjToken, jsonFile: type.rawValue)
    }

    // 返回删除成功的 objTokens
    static func mockDelete(successTokens: [String]) {
        mock(path: OpenAPI.APIPath.deleteByObjToken, data: ["success_token": successTokens])
    }

    static func mockRemoveFromFolder<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.deleteFileInFolderByToken, jsonFile: type.rawValue)
    }

    // 返回删除成功的 nodeToken
    static func mockRemoveFromFolder(successTokens: [String]) {
        mock(path: OpenAPI.APIPath.deleteFileInFolderByToken, data: ["success_token": successTokens])
    }

    static func mockRemoveFromShareWithMeList<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.deleteShareWithMeListFileByObjToken, jsonFile: type.rawValue)
    }

    static func mockDeleteV2Item<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.deleteInDoc, jsonFile: type.rawValue)
    }

    // 需要全部成功、权限部分失败、非权限失败3种
    enum DeleteV2Response: String {
        case allSuccess = "plain-success.json"
        case partialFailed = "delete-v2-partial-failed.json"
        case needApproval = "delete-v2-need-review.json"
    }
    static func mockDeleteV2<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.deleteV2, jsonFile: type.rawValue)
    }

    // 两个一起 mock
    static func mockUpdateFavorites<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.addFavorites, jsonFile: type.rawValue)
        mock(path: OpenAPI.APIPath.removeFavorites, jsonFile: type.rawValue)
    }

    static func mockUpdateIsSubscribe<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.addSubscribe, jsonFile: type.rawValue)
        mock(path: OpenAPI.APIPath.removeSubscribe, jsonFile: type.rawValue)
    }

    static func mockUpdateIsPin<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.addPins, jsonFile: type.rawValue)
        mock(path: OpenAPI.APIPath.removePins, jsonFile: type.rawValue)
    }

    static func mockUpdateIsHidden<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.hideShareFolder, jsonFile: type.rawValue)
        mock(path: OpenAPI.APIPath.showShareFolder, jsonFile: type.rawValue)
    }

    static func mockUpdateIsHiddenV2<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.hideShareFolderV2, jsonFile: type.rawValue)
        mock(path: OpenAPI.APIPath.showShareFolderV2, jsonFile: type.rawValue)
    }

    static func mockUpdateSecLabel<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.updateSecLabel, jsonFile: type.rawValue)
    }
    
    static func mockRecentList<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.recentUpdate, jsonFile: type.rawValue)
    }

    static func mockSubordinateRecentList<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.subordinateRecentList, jsonFile: type.rawValue)
    }
    
    static func mockRecentListDeleteFile<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.deleteRecentFileByObjTokenV2, jsonFile: type.rawValue)
    }
    
    static func mockShareFolderList<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.newShareFolderV2, jsonFile: type.rawValue)
    }
    
    static func mockFavoritesList<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.getFavoritesV2, jsonFile: type.rawValue)
    }
    
    static func mockMyFolderList<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.folderDetail, jsonFile: type.rawValue)
    }

    static func mockApplyDelete<T: RawRepresentable>(type: T) where T.RawValue == String {
        mock(path: OpenAPI.APIPath.spaceApplyDelete, jsonFile: type.rawValue)
    }
}
