//
//  WikiTreeMoreActionHandler.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/9/26.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import LarkEMM
import SKInfra

protocol WikiMoreProvider: MoreDataProvider {
    var handler: WikiTreeMoreActionHandler? { get set }
}

public protocol WikiTreeMoreActionHandler: AnyObject {
    // 收藏到space
    func starInSpaceTarget(with meta: WikiTreeNodeMeta)
    // 置顶
    func clipTarget(with meta: WikiTreeNodeMeta, setClip: Bool)
    // 创建shortcut
    func shortcutTarget(with meta: WikiTreeNodeMeta, originName: String?, inClipSection: Bool)
    // 创建副本
    func copyTarget(with meta: WikiTreeNodeMeta, showCopyToCurrent: Bool, originName: String?, inClipSection: Bool)
    // 移动到
    func moveTarget(with meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool)
    // 删除
    func deleteTarget(with meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool, sourceView: UIView)
    // 移除到space
    func removeToSpaceTarget(with meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool)
    // 复制链接
    func copyLink(with meta: WikiTreeNodeMeta)
    // 重命名
    func rename(with meta: WikiTreeNodeMeta)
    // 下载
    func downloadHandle(with meta: WikiTreeNodeMeta, fileInfo: [String: Any]?)
    // 快速访问
    func pinInSpaceTarget(with meta: WikiTreeNodeMeta)
    // 离线使用
    func offlineAccess(with meta: WikiTreeNodeMeta)

    func disableHandle(reason: String)
}

extension WikiMainTreeMoreProvider: WikiTreeMoreActionHandler {
    public func starInSpaceTarget(with meta: WikiTreeNodeMeta) {
        let isStar = meta.isExplorerStar
        toggleExplorerStar(meta: meta, setStar: !isStar)
    }
    
    public func clipTarget(with meta: WikiTreeNodeMeta, setClip: Bool) {
        toggleClip(meta: meta, setClip: setClip)
    }
    
    public func shortcutTarget(with meta: WikiTreeNodeMeta, originName: String?, inClipSection: Bool) {
        didClickShortcut(meta: meta, originName: originName, inClipSection: inClipSection)
    }
    
    public func copyTarget(with meta: WikiTreeNodeMeta, showCopyToCurrent: Bool, originName: String?, inClipSection: Bool) {
        didClickCopy(meta: meta, showCopyToCurrent: showCopyToCurrent, originName: originName, isClip: inClipSection)
    }
    
    public func moveTarget(with meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool) {
        didClickMoveTarget(meta: meta, permission: permission, isClip: inClipSection)
    }
    
    public func deleteTarget(with meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool, sourceView: UIView) {
        didClickDelete(meta: meta, permission: permission, inClipSection: inClipSection, sourceView: sourceView)
    }
    
    public func removeToSpaceTarget(with meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool) {
        didClickRemoveToSpace(meta: meta, permission: permission, inClipSection: inClipSection)
    }
    
    public func copyLink(with meta: WikiTreeNodeMeta) {
        var sharedUrl = meta.url
        if sharedUrl.isEmpty { //复制wiki没有源url，才本地构建一个链接
            sharedUrl = DocsUrlUtil.url(type: .wiki, token: meta.wikiToken).absoluteString
        }
        SCPasteboard.generalPasteboard().string = sharedUrl
        actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_Facade_CopyLinkSuccessfully)))
    }
    
    public func rename(with meta: WikiTreeNodeMeta) {
        renameHandler(meta: meta)
    }
    
    public func downloadHandle(with meta: WikiTreeNodeMeta, fileInfo: [String: Any]?) {
        guard let fileInfo = fileInfo else {
            spaceAssertionFailure("enable wiki more download item, should not go here")
            disableHandle(reason: BundleI18n.SKResource.Doc_Facade_OperateFailed)
            DocsLogger.error("wiki-tree-more: can not get the drive file info in download item")
            return
        }
        actionInput.accept(.customAction(compeletion: { [weak self] fromVC in
            guard let fromVC = fromVC else {
                self?.disableHandle(reason: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                DocsLogger.error("wiki-tree-more: can not get the fromVC in download item")
                return
            }
            DocsContainer.shared.resolve(DriveVCFactoryType.self)?.saveToLocal(data: fileInfo,
                                                                               fileToken: meta.objToken,
                                                                               mountNodeToken: "",
                                                                               mountPoint: "wiki",
                                                                               fromVC: fromVC,
                                                                               previewFrom: .wiki)
        }))
    }
    
    public func pinInSpaceTarget(with meta: WikiTreeNodeMeta) {
        toggleExplorerPin(meta: meta)
    }
    
    public func offlineAccess(with meta: WikiTreeNodeMeta) {
        toggleOfflineAccess(meta: meta)
    }

    public func disableHandle(reason: String) {
        guard !reason.isEmpty else {
            return
        }
        actionInput.accept(.showHUD(.failure(reason)))
    }
}
