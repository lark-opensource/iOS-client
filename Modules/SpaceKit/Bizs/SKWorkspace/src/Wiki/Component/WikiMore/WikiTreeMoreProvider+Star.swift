//
//  WikiTreeMoreProvider+Star.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
//

import Foundation
import RxSwift
import SKFoundation
import SKResource
import SKCommon
import UniverseDesignToast
import SpaceInterface
import SKInfra
import SKWorkspace

// MARK: wiki clip
extension WikiMainTreeMoreProvider {
    private func toggleClipStatisticReport(meta: WikiTreeNodeMeta, hasClip: Bool) {
        if hasClip {
            WikiStatistic.unstar(wikiToken: meta.wikiToken,
                                 fileType: meta.objType.name,
                                 refType: meta.isShortcut ? .shortcut : .original)
        } else {
            WikiStatistic.star(wikiToken: meta.wikiToken,
                               fileType: meta.objType.name,
                               refType: meta.isShortcut ? .shortcut : .original)
        }
        let pagesNum = self.childCountProvider?(meta.wikiToken) ?? 0
        WikiStatistic.clickWikiTreeMoreStar(click: hasClip ? .unclipWiki : .clipWiki,
                                            isFavorites: hasClip,
                                            pagesNum: pagesNum,
                                            meta: meta)
    }

    func toggleClip(meta: WikiTreeNodeMeta, setClip: Bool) {
        toggleClipStatisticReport(meta: meta, hasClip: !setClip)
        networkAPI.setStarNode(spaceId: meta.spaceID, wikiToken: meta.wikiToken, isAdd: setClip)
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                let tip = setClip
                ? BundleI18n.SKResource.CreationMobile_Wiki_PageClipped_Toast
                : BundleI18n.SKResource.CreationMobile_Wiki_PageUnclipped_Toast
                self.actionInput.accept(.showHUD(.success(tip)))
                self.moreActionInput.accept(.toggleClip(meta: meta, setClip: setClip))
                if setClip {
                    NotificationCenter.default.post(name: Notification.Name.Docs.wikiStarNode, object: meta.wikiToken)
                } else {
                    NotificationCenter.default.post(name: Notification.Name.Docs.wikiUnStarNode, object: meta.wikiToken)
                }
            } onError: { [weak self] error in
                DocsLogger.error("toggle wiki clip status failed", error: error)
                let tip = setClip
                ? BundleI18n.SKResource.CreationMobile_Wiki_FailedToClip_Toast
                : BundleI18n.SKResource.CreationMobile_Wiki_FailedToUnClip_Toast
                self?.actionInput.accept(.showHUD(.failure(tip)))
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - Explorer Star
extension WikiMainTreeMoreProvider {
    func toggleExplorerStar(meta: WikiTreeNodeMeta, setStar: Bool) {
        let wikiToken = meta.originWikiToken ?? meta.wikiToken
        let objToken: String
        let objType: DocsType
        if meta.originIsExternal {
            objToken = meta.objToken
            objType = meta.objType
        } else {
            objToken = wikiToken
            objType = .wiki
        }
        networkAPI.starInExplorer(objToken: objToken, objType: objType, isAdd: setStar)
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                self.moreActionInput.accept(.toggleExplorerStar(meta: meta, setStar: setStar))
                let notificationInfo = [
                    "objType": DocsType.wiki,
                    "objToken": wikiToken,
                    "addStar": setStar,
                    "spaceId": meta.spaceID
                ]
                NotificationCenter.default.post(name: Notification.Name.Docs.wikiExplorerStarNode, object: nil, userInfo: notificationInfo)
                if setStar {
                    self.showWikiFavoriteSuccess()
                } else {
                    self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.CreationMobile_Wiki_Favorites_CanceledFavorites_Toast)))
                }
            } onError: { [weak self] error in
                DocsLogger.error("toggle explorer star failed", error: error)
                let tip = setStar
                ? BundleI18n.SKResource.Doc_Wiki_StarFail
                : BundleI18n.SKResource.Doc_Wiki_UnstarFail
                self?.actionInput.accept(.showHUD(.failure(tip)))
            }
            .disposed(by: disposeBag)
    }

    private func showWikiFavoriteSuccess() {
        let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Wiki_AddtoFav_GoToButton,
                                               displayType: .horizontal)
        let config = UDToastConfig(toastType: .success,
                                   text: BundleI18n.SKResource.CreationMobile_Wiki_Favorites_AddedFavorites_Toast,
                                   operation: operation)
        actionInput.accept(.showHUD(.custom(config: config, operationCallback: { [weak self] _ in
            guard let self = self else { return }
            
            self.actionInput.accept(.pushURL(DocsUrlUtil.spaceFavoriteList))
        })))
    }
}
