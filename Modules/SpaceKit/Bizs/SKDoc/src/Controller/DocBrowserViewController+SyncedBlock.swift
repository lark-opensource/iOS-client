//
//  DocBrowserViewController+SyncedBlock.swift
//  SKDoc
//
//  Created by liujinwei on 2023/11/6.
//  


import Foundation
import SKFoundation
import SKCommon

extension DocBrowserViewController: SyncedBlockSeparatePage {
    
    public func setup(delegate: SyncedBlockContainerDelegate) {
        self.syncedBlockContainer = delegate
        if !UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled {
            //独立授权fg未命中时无权限依旧跳回源文档
            self.setupSyncedBlockPermissionMoniter()
        }
    }
    
    private func setupSyncedBlockPermissionMoniter() {
        self.editor.permissionConfig.getPermissionService(for: .hostDocument)?.onPermissionUpdated.subscribe(onNext: { [weak self] response in
            switch response {
            case .noPermission(let code, _):
                guard let docsInfo = self?.docsInfo else { return }
                switch code {
                case .entityDeleted, .unknown(_):
                    DocsLogger.info("synced block has been deleted, no need to back source doc", component: LogComponents.syncBlock)
                default:
                    //无权限时跳回源文档
                    DocsLogger.info("synced block has no permission, back to source doc", component: LogComponents.syncBlock)
                    self?.syncedBlockContainer?.backToOriginDocIfNeed(token: docsInfo.token, type: docsInfo.type)
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }

}
