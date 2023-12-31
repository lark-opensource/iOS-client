//
//  SpaceManagementAPI.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/6/15.
//

import Foundation
import UIKit
import RxSwift

// 对 DataModel 的抽象, More 面板的实现依赖 Space 提供管理能力
public protocol SpaceManagementAPI {
    
    func addStar(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?)
    func removeStar(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?)

    func addPin(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?)
    func removePin(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?)

    func addSubscribe(fileMeta: SpaceMeta, subType: Int, completion: ((Error?) -> Void)?)
    func removeSubscribe(fileMeta: SpaceMeta, subType: Int, completion: ((Error?) -> Void)?)

    func delete(objToken: String, docType: DocsType, completion: ((Error?) -> Void)?)
    
    // 实为单容器改造后从V2文档内应该使用的删除方法，考虑改个名字, 可能有需要申请删除场景
    func deleteInDoc(objToken: String, docType: DocsType, canApply: Bool) -> Maybe<AuthorizedUserInfo>
    // 申请删除文档
    func applyDelete(meta: SpaceMeta, reviewerID: String, reason: String?) -> Completable

    @available(*, deprecated, message: "Space opt: bitable do not specialize，bitable realize by yourself ")
    func renameBitable(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?)

    @available(*, deprecated, message: "Space opt:  sheet do not specialize，sheet realize by yourself")
    func renameSheet(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?)
    
    func renameSlides(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?)

    func update(isFavorites: Bool, objToken: String, docType: DocsType) -> Single<Void>

    func createShortCut(objToken: String, objType: DocsType, folderToken: String) -> Single<String>

    func copyToWiki(objToken: String, objType: DocsType, location: WikiPickerLocation, title: String, needAsync: Bool) -> Single<String>

    func getParentFolderToken(objToken: String, objType: DocsType) -> Single<String>

    func shortcutToWiki(objToken: String, objType: DocsType, title: String, location: WikiPickerLocation) -> Single<String>

    // space 1.0 移动文档
    func move(nodeToken: String, from srcFolder: String, to destFolder: String) -> Completable

    // space 2.0 移动文档
    func moveV2(nodeToken: String, from srcFolder: String?, to destFolder: String) -> Completable

    // space 移动到 wiki
    func moveToWiki(item: SpaceMeta, nodeToken: String, parentToken: String?, location: WikiPickerLocation) -> Single<MoveToWikiStatus>

    // 所在父文件夹是否共享文件夹
    func isParentFolderShareFolder(token: String, nodeType: Int) -> Bool
}

public enum MoveToWikiStatus: Equatable {
    case moving
    case succeed(wikiToken: String)
    case failed(code: Int) // 参考 https://bytedance.feishu.cn/wiki/wikcncboa0JWnPEFvzLxTvQJURA
}
