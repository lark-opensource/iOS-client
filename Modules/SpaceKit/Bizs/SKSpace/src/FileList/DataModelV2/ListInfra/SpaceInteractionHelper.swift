//
//  SpaceInteractionHelper.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/23.
//

import Foundation
import SKCommon
import SKUIKit
import RxSwift
import RxRelay
import SKFoundation
import SKResource
import EENavigator
import UIKit
import SpaceInterface
import SKInfra
import SKWorkspace

extension SpaceEntry {
    var spaceItem: SpaceItem {
        return SpaceItem(objToken: objToken, objType: docsType)
    }
}

// 取代 DocsListInteractService，负责发起网络请求，完成请求后更新 SKDataManager 的逻辑
class SpaceInteractionHelper {

    private typealias API = SpaceNetworkAPI

    static let `default` = SpaceInteractionHelper(dataManager: SKDataManager.shared)
    private let disposeBag = DisposeBag()
    private let dataManager: SpaceInteractionHelperDataManager

    init(dataManager: SpaceInteractionHelperDataManager) {
        self.dataManager = dataManager
    }

    func update(isFavorites: Bool, item: SpaceItem) -> Completable {
        API.update(isFavorites: isFavorites, item: item)
            .do(onCompleted: { [self] in
                dataManager.updateFileStarValueInAllList(objToken: item.objToken, isStared: isFavorites)
            })
    }

    func update(isPin: Bool, item: SpaceItem) -> Completable {
        API.update(isPin: isPin, item: item)
            .do(onCompleted: { [self] in
                dataManager.updatePin(objToken: item.objToken, isPined: isPin)
                NotificationCenter.default.post(name: QuickAccessDataModel.quickAccessNeedUpdate, object: nil)
            })
    }

    func update(isSubscribe: Bool, subType: Int, item: SpaceItem) -> Completable {
        // 目前没有什么特别要处理的事情
        API.update(isSubscribe: isSubscribe, subType: subType, item: item)
    }

    func update(isHidden: Bool, folderToken: FileListDefine.NodeToken) -> Completable {
        API.update(isHidden: isHidden, folderToken: folderToken)
    }
    
    func setHiddenV2(isHidden: Bool, folderToken: FileListDefine.NodeToken) -> Completable {
        API.updateHiddenV2(isHidden: isHidden, folderToken: folderToken)
            .do(onCompleted: { [self] in
                dataManager.updateHiddenV2(objToken: folderToken, hidden: isHidden)
            })
    }

    func rename(objToken: String, with newName: String) -> Completable {
        API.rename(objToken: objToken, with: newName)
            .do(onCompleted: { [self] in
                dataManager.renameFile(objToken: objToken, newName: newName)
            })
    }

    func renameV2(isShortCut: Bool, objToken: String, nodeToken: String, newName: String) -> Completable {
        API.renameV2(nodeToken: nodeToken, with: newName)
            .do(onCompleted: { [self] in
                if isShortCut {
                    dataManager.renameFile(objToken: nodeToken, newName: newName)
                } else {
                    dataManager.rename(objToken: objToken, with: newName)
                }
            })
    }

    func move(nodeToken: FileListDefine.NodeToken, from srcFolder: FileListDefine.NodeToken, to destFolder: FileListDefine.NodeToken) -> Completable {
        API.move(nodeToken: nodeToken, to: destFolder)
            .do(onCompleted: { [self] in
                dataManager.moveFile(file: nodeToken, from: srcFolder, to: destFolder)
            })
    }

    func moveV2(nodeToken: FileListDefine.NodeToken, from srcFolder: FileListDefine.NodeToken?, to destFolder: FileListDefine.NodeToken) -> Completable {
        API.moveV2(nodeToken: nodeToken, to: destFolder)
            .do(onCompleted: { [self] in
                if let srcFolder = srcFolder, !srcFolder.isEmpty {
                    dataManager.moveFile(file: nodeToken, from: srcFolder, to: destFolder)
                } else {
                    dataManager.deletePersonFile(nodeToken: nodeToken)
                }
            })
    }

    func add(objToken: FileListDefine.ObjToken, to destFolder: FileListDefine.NodeToken) -> Completable {
        API.add(objToken: objToken, to: destFolder)
    }


    func createShortCut(for item: SpaceItem, in destFolder: FileListDefine.NodeToken) -> Single<String> {
        createShortCut(objToken: item.objToken, objType: item.objType, folderToken: destFolder)
    }

    // 为测试用，增加一个 isReachable 参数
    func delete(item: SpaceItem, isReachable: Bool? = nil) -> Single<[String]?> {
        let isReachable = isReachable ?? DocsNetStateMonitor.shared.isReachable
        if item.objToken.isFakeToken, isReachable {
            // 仅在有网、尝试删除原文件时，才允许删除本地未同步成功的文档，防止丢数据
            let token = TokenStruct(token: item.objToken)
            dataManager.deleteFileByToken(token: token)
            return .just(nil)
        }

        return API.delete(item: item)
            .do(onSuccess: { [self] deletedTokens in
                if let deletedTokens = deletedTokens,
                   let fileEntry = dataManager.spaceEntry(objToken: item.objToken),
                   let parent = fileEntry.parent {
                    // 删除folders关系，删除nodes中的数据
                    deletedTokens.forEach { nodeToken in
                        dataManager.deleteFile(nodeToken: nodeToken, parent: parent)
                    }
                }
                // 删除fileData中的剩余数据和关系，然后更新所有的列表数据
                dataManager.deleteFileByToken(token: TokenStruct(token: item.objToken))
            })
    }

    func removeFromFolder(nodeToken: FileListDefine.NodeToken, folderToken: FileListDefine.ObjToken?) -> Single<[String]?> {
        API.removeFromFolder(nodeToken: nodeToken)
            .do(onSuccess: { [self] deletedTokens in
                if let deletedTokens = deletedTokens {
                    deletedTokens.forEach { nodeToken in
                        let parent: String
                        if let folderToken = folderToken {
                            parent = folderToken
                        } else {
                            // WARN: dataManager.spaceEntry(token:) 此方法无法通过 nodeToken 找到文档，原因是内部以 objToken 为 key 进行查找，理论上应该区分 nodeToken objToken 分开查询
                            // 不修就等 space 2.0 完全迁移完，2.0 没有此问题
                            guard let entry = dataManager.spaceEntry(token: TokenStruct(token: nodeToken)),
                                  let parentFromMemory = entry.parent else {
                                      return
                                  }
                            parent = parentFromMemory
                        }
                        dataManager.deleteFile(nodeToken: nodeToken, parent: parent)
                    }
                }
            })
    }

    func removeFromShareFileList(objToken: FileListDefine.ObjToken) -> Completable {
        API.removeFromShareWithMeList(objToken: objToken)
            .do(onCompleted: { [self] in
                // API 写的传 nodeToken，实际是 objToken
                dataManager.deleteShareWithMeFile(nodeToken: objToken)
            })
    }

    func deleteV2(objToken: FileListDefine.ObjToken,
                  nodeToken: FileListDefine.NodeToken,
                  type: DocsType,
                  isShortCut: Bool,
                  canApply: Bool) -> Single<SpaceNetworkAPI.DeleteResponse> {

        if objToken.isFakeToken, DocsNetStateMonitor.shared.isReachable {
            // 仅在有网、尝试删除原文件时，才允许删除本地未同步成功的文档，防止丢数据
            let token = TokenStruct(token: objToken, nodeType: isShortCut ? 1 : 0)
            dataManager.deleteFileByToken(token: token)
            return .just(.success)
        }

        return API.deleteV2(nodeToken: nodeToken, canApply: canApply)
            .do(onSuccess: { [self] response in
                // 非删除成功场景，不继续后续的删除流程
                guard case .success = response else { return }
                let tokenToDelete: String
                if isShortCut || type == .folder {
                    tokenToDelete = nodeToken
                } else {
                    tokenToDelete = objToken
                }
                let token = TokenStruct(token: tokenToDelete, nodeType: isShortCut ? 1 : 0)
                dataManager.deleteFileByToken(token: token)
            })
    }

    func applyDelete(meta: SpaceMeta, reviewerID: String, reason: String?) -> Completable {
        API.applyDelete(meta: meta, reviewerID: reviewerID, reason: reason)
    }

    func updateSecLabel(wikiToken: String?, token: String, type: Int, label: SecretLevelLabel, reason: String) -> Completable {
        API.updateSecLabel(token: token, type: type, id: label.id, reason: reason)
            .do(onCompleted: { [self] in
                dataManager.updateSecurity(objToken: wikiToken ?? token, newSecurityName: label.name)
            })
    }

    func updateSecLabel(wikiToken: String?, token: String, name: String) {
        dataManager.updateSecurity(objToken: wikiToken ?? token, newSecurityName: name)
    }
}

extension SpaceInteractionHelper: SpaceManagementAPI {
    
    
    func addStar(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?) {
        update(isFavorites: true, item: fileMeta)
            .subscribe {
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func removeStar(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?) {
        update(isFavorites: false, item: fileMeta)
            .subscribe {
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func update(isFavorites: Bool, objToken: String, docType: DocsType) -> Single<Void> {
        let item = SpaceItem(objToken: objToken, objType: docType)
        let updateEvent = update(isFavorites: isFavorites, item: item)
        return Single.create { observer in
            return updateEvent.subscribe {
                observer(.success(()))
            } onError: { error in
                observer(.error(error))
            }
        }
    }

    func addPin(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?) {
        update(isPin: true, item: fileMeta)
            .subscribe {
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func removePin(fileMeta: SpaceMeta, completion: ((Error?) -> Void)?) {
        update(isPin: false, item: fileMeta)
            .subscribe {
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func addSubscribe(fileMeta: SpaceMeta, subType: Int = 0, completion: ((Error?) -> Void)?) {
        addSubscribe(fileMeta: fileMeta,
                     forceUnreachable: false,
                     subType: subType,
                     completion: completion)
    }

    /// more 面板订阅接口接口
    /// - Parameters:
    ///   - subType: 默认0是文档订阅， 1 位评论更新订阅
    // 如果是WIKI，上层需要确认构建为wiki类型的SpaceMeta
    func addSubscribe(fileMeta: SpaceMeta, forceUnreachable: Bool, subType: Int = 0, completion: ((Error?) -> Void)?) {
        guard !forceUnreachable && DocsNetStateMonitor.shared.isReachable else {
            // TODO: 应该在调用层先判断好网络
            let error = NSError(domain: "docs.spacekit.unReachable", code: -1, userInfo: ["errorMsg": BundleI18n.SKResource.Doc_List_AddFailedRetry])
            completion?(error)
            return
        }
        
        update(isSubscribe: true, subType: subType, item: fileMeta)
            .subscribe {
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }
    
    // 如果是WIKI，上层需要确认构建为wiki类型的SpaceMeta
    func removeSubscribe(fileMeta: SpaceMeta, subType: Int = 0, completion: ((Error?) -> Void)?) {
        removeSubscribe(fileMeta: fileMeta,
                        forceUnreachable: false,
                        subType: subType,
                        completion: completion)
    }

    /// more 面板订阅取消订阅接口
    /// - Parameters:
    ///   - subType: 默认0是文档订阅， 1 位评论更新订阅
    func removeSubscribe(fileMeta: SpaceMeta, forceUnreachable: Bool, subType: Int = 0, completion: ((Error?) -> Void)?) {
        guard !forceUnreachable && DocsNetStateMonitor.shared.isReachable else {
            // TODO: 应该在调用层先判断好网络
            let error = NSError(domain: "docs.spacekit.unReachable", code: -1, userInfo: ["errorMsg": BundleI18n.SKResource.Doc_List_RemoveFaildRetry])
            completion?(error)
            return
        }
        update(isSubscribe: false, subType: subType, item: fileMeta)
            .subscribe {
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func delete(objToken: String, docType: DocsType, completion: ((Error?) -> Void)?) {
        let item = SpaceItem(objToken: objToken, objType: docType)
        delete(item: item)
            .subscribe { _ in
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func deleteInDoc(objToken: String, docType: DocsType, canApply: Bool) -> Maybe<AuthorizedUserInfo> {
        let item = SpaceItem(objToken: objToken, objType: docType)
        // Maybe 不能直接用 do(onCompleted:)， 无法区分 success 和 complete 场景，所以包一层
        return .create { observer in
            API.deleteV2(item: item, canApply: canApply)
                .subscribe { reviewerInfo in
                    observer(.success(reviewerInfo))
                } onError: { error in
                    observer(.error(error))
                } onCompleted: { [weak self] in
                    self?.dataManager.deleteFileByToken(token: TokenStruct(token: objToken))
                    observer(.completed)
                }
        }
    }

    @available(*, deprecated, message: "Space opt: Space 不对 bitable 做特化逻辑，需要 bitable 自己实现")
    func renameBitable(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?) {
        API.renameBitable(objToken: objToken, with: newName)
            .subscribe { [self] in
                dataManager.renameFile(objToken: wikiToken ?? objToken, newName: newName)
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    @available(*, deprecated, message: "Space opt: Space 不对 sheet 做特化逻辑，需要 sheet 自己实现")
    func renameSheet(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?) {
        API.renameSheet(objToken: objToken, with: newName)
            .subscribe { [self] in
                dataManager.renameFile(objToken: wikiToken ?? objToken, newName: newName)
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }
    
    func renameSlides(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?) {
        API.renameSlides(objToken: objToken, with: newName)
            .subscribe { [self] in
                dataManager.renameFile(objToken: wikiToken ?? objToken, newName: newName)
                completion?(nil)
            } onError: { error in
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    func createShortCut(objToken: String, objType: DocsType, folderToken: FileListDefine.NodeToken) -> Single<String> {
        WorkspaceManagementAPI.Space.shortcutToSpace(objToken: objToken, objType: objType, folderToken: folderToken)
    }
    /// space文档创建副本到space
    func copyToSpace(request: WorkspaceManagementAPI.Space.CopyToSpaceRequest, picker: UIViewController) -> Single<URL> {
        WorkspaceManagementAPI.Space.copyToSpace(request: request, router: picker as? DocsCreateViewControllerRouter)
    }
    /// wiki文档创建副本到space
    func copyToSpace(sourceWikiToken: String, spaceId: String, folderToken: String, title: String, needAsync: Bool) -> Single<URL> {
        WorkspaceManagementAPI.Wiki.copyToSpace(sourceWikiToken: sourceWikiToken,
                                                sourceSpaceID: spaceId,
                                                title: title,
                                                folderToken: folderToken,
                                                needAsync: needAsync)
            .map { $1 }
    }
    /// space文档创建副本到wiki
    func copyToWiki(objToken: String, objType: DocsType, location: WikiPickerLocation, title: String, needAsync: Bool) -> Single<String> {
        WorkspaceManagementAPI.Space.copyToWiki(objToken: objToken, objType: objType, location: location, title: title, needAsync: needAsync)
            .map { $1 }
    }
    /// wiki文档创建副本到wiki
    func copyToWiki(sourceMeta: WikiMeta, targetMeta: WikiMeta, title: String, needAsync: Bool) -> Single<String> {
        WorkspaceManagementAPI.Wiki.copyToWiki(sourceMeta: sourceMeta, targetMeta: targetMeta, title: title, needAsync: needAsync, synergyUUID: nil)
            .map { (data, _) in
                guard let token = data["wiki_token"].string else {
                    DocsLogger.error("crate wiki copy to wiki error: can not get wiki token")
                    throw DocsNetworkError.invalidData
                }
                return token
            }
    }

    func getParentFolderToken(objToken: String, objType: DocsType) -> Single<String> {
        getParentFolderToken(item: SpaceItem(objToken: objToken, objType: objType))
    }

    func getParentFolderToken(item: SpaceItem) -> Single<String> {
        API.getParentFolderToken(item: item)
    }

    func getMoveReviewer(nodeToken: String?, item: SpaceItem?, targetToken: String) -> Maybe<AuthorizedUserInfo> {
        WorkspaceManagementAPI.Space.getMoveReviewer(nodeToken: nodeToken, item: item, targetToken: targetToken)
    }

    func applyMoveToSpace(nodeToken: String, targetToken: String?, reviewerID: String, comment: String?) -> Completable {
        WorkspaceManagementAPI.Space.applyMoveToSpace(nodeToken: nodeToken, targetToken: targetToken, reviewerID: reviewerID, comment: comment)
    }

    func applyMoveToWiki(item: SpaceItem, location: WikiPickerLocation, reviewerID: String, comment: String?) -> Completable {
        WorkspaceManagementAPI.Space.applyMoveToWiki(item: item, location: location, reviewerID: reviewerID, comment: comment)
    }

    func moveToWiki(item: SpaceItem, nodeToken: String, parentToken: FileListDefine.NodeToken?, location: WikiPickerLocation) -> Single<MoveToWikiStatus> {
        return WorkspaceManagementAPI.Space.moveToWiki(item: item, location: location)
            .do(onSuccess: { [self] status in
                guard case let .succeed(wikiToken) = status else { return }
                if let parentToken, !parentToken.isEmpty {
                    dataManager.deleteFile(nodeToken: nodeToken, parent: parentToken)
                } else {
                    dataManager.deletePersonFile(nodeToken: nodeToken)
                }
                DispatchQueue.main.async {
                    DocsLogger.info("update cross route table after space move to wiki success")
                    let record = WorkspaceCrossRouteRecord(wikiToken: wikiToken, objToken: item.objToken, objType: item.objType, inWiki: true, logID: nil)
                    DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)?.set(record: record)
                }
            })
    }

    func isParentFolderShareFolder(token: String, nodeType: Int) -> Bool {
        if let parentEntry = SKDataManager.shared.spaceEntry(token: TokenStruct(token: token, nodeType: nodeType)),
           let parentFolder = parentEntry as? FolderEntry,
           parentFolder.isShareFolder {
            return true
        }
        return false
    }

    func checkWikiCreatePermission(location: WikiPickerLocation) -> Single<Bool> {
        WorkspaceCrossNetworkAPI.checkWikiCreatePermission(location: location)
    }
    /// space创建shortcut到wiki
    func shortcutToWiki(objToken: String, objType: DocsType, title: String, location: WikiPickerLocation) -> Single<String> {
        WorkspaceManagementAPI.Space.shortcutToWiki(objToken: objToken, objType: objType, title: title, location: location).map { $0.0 }
    }
    /// wiki创建shortcut到space
    func shortcutToSpace(item: SpaceItem, folderToken: String) -> Single<String> {
        WorkspaceManagementAPI.Wiki.shortcutToSpace(objToken: item.objToken, objType: item.objType, folderToken: folderToken).map { $0.0 }
    }
    /// wiki创建shorcut到wiki
    func shortcutToWiki(sourceWikiMeta: WikiMeta, targetWikiMeta: WikiMeta, title: String) -> Single<String> {
        WorkspaceManagementAPI.Wiki.shortcutToWiki(sourceWikiToken: sourceWikiMeta.wikiToken,
                                                   targetWikiToken: targetWikiMeta.wikiToken,
                                                   targetSpaceID: targetWikiMeta.spaceID,
                                                   title: title,
                                                   synergyUUID: nil)
        .map { data in
            guard let wikiToken = data["wiki_token"].string else {
                throw DocsNetworkError.invalidData
            }
            return wikiToken
        }
    }
    
}
