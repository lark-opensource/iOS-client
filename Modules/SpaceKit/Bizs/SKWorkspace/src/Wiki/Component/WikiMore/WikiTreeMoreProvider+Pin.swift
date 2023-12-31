//
//  WikiTreeMoreProvider+Pin.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/3/14.
//

import Foundation
import SKResource
import SKFoundation
import SKCommon
import SpaceInterface

extension WikiMainTreeMoreProvider {
    func toggleExplorerPin(meta: WikiTreeNodeMeta) {
        confirmPin(meta: meta)
        WikiStatistic.clickWikiTreeMore(click: meta.isExplorerPin ? .removePin : .addPin,
                                        isFavorites: meta.isExplorerStar,
                                        target: DocsTracker.EventType.wikiTreeMoreView.rawValue,
                                        meta: meta)
    }
    
    
    private func confirmPin(meta: WikiTreeNodeMeta) {
        let addPin = !meta.isExplorerPin
        let wikiToken = meta.originWikiToken ?? meta.wikiToken
        var objToken: String = wikiToken
        var objType: DocsType = .wiki
        if meta.originIsExternal {
            //本体在space的wiki Shortcut取objToken和真实类型
            objToken = meta.objToken
            objType = meta.objType
        }
        interactionHelper
            .networkAPI
            .pinInExplorer(addPin: addPin, objToken: objToken, docsType: objType)
            .subscribe(onCompleted: { [weak self] in
                DocsLogger.info("wiki.tree.more: toggle explorer pin success")
                guard let self else { return }
                self.moreActionInput.accept(.toggleExplorerPin(meta: meta, setPin: addPin))
                if addPin {
                    if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                        self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.LarkCCM_NewCM_AddedToPin_Toast)))
                    } else {
                        self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_List_AddSuccessfully_QuickAccess)))
                    }
                    
                } else {
                    if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                        self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.LarkCCM_NewCM_RemovedFromPin_Toast)))
                    } else {
                        self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_List_RemoveSucccessfully)))
                    }
                    
                }
                // 同步shortcut和本体状态
                let notificationInfo: [String: Any] = ["targetToken": objToken, "objType": objType, "addPin": addPin, "spaceId": meta.spaceID]
                NotificationCenter.default.post(name: Notification.Name.Docs.WikiExplorerPinNode, object: nil, userInfo: notificationInfo)
                // 同步快速访问列表
                NotificationCenter.default.post(name: Notification.Name.Docs.quickAccessUpdate, object: nil)
            }, onError: { [weak self] error in
                DocsLogger.error("wiki.tree.more: toggle explorer pin failed", extraInfo: ["isAddPin": addPin], error: error)
                guard let self else { return }
                if (error as NSError).code == DocsNetworkError.Code.workspaceExceedLimited.rawValue {
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_List_AddStarOverLimit)))
                    return
                }
                if let docsError = error as? DocsNetworkError,
                    let message = docsError.code.errorMessage {
                    self.actionInput.accept(.showHUD(.failure(message)))
                    return
                }
                if addPin {
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_List_AddFailedRetry)))
                } else {
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_List_RemoveFaildRetry)))
                }
            })
            .disposed(by: disposeBag)
    }
}
