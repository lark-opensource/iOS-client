//
//  WikiTreeMoreProvider+Copy.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
//

import Foundation
import RxSwift
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import LarkUIKit
import UIKit
import SKInfra
import SpaceInterface

// 创建副本操作
extension WikiMainTreeMoreProvider {

    private typealias CopyContext = WikiInteractionHandler.CopyContext
    private typealias CopyLocation = WikiInteractionHandler.CopyPickerLocation

    func didClickCopy(meta: WikiTreeNodeMeta, showCopyToCurrent: Bool, originName: String?, isClip: Bool) {
        WikiStatistic.clickWikiTreeMore(click: .copyTo,
                                        isFavorites: isClip,
                                        target: DocsTracker.EventType.wikiFileLocationSelectView.rawValue,
                                        meta: meta)
        let parentToken = parentProvider?(meta.wikiToken)
        let context = CopyContext(meta: meta, parentToken: parentToken, originName: originName)
        
        let picker = interactionHelper.makeCopyPicker(context: context,
                                                      triggerLocation: .wikiTree,
                                                      allowCopyToSpace: SettingConfig.singleContainerEnable,
                                                      allowCopyToCurrentLocation: showCopyToCurrent) { [weak self] picker, location in
            self?.confirmCopyTo(meta: meta,
                                context: context,
                                location: location,
                                picker: picker)
        }
        actionInput.accept(.present(provider: { _ in
            picker
        }))
    }

    private func confirmCopyTo(meta: WikiTreeNodeMeta,
                               context: CopyContext,
                               location: CopyLocation,
                               picker: UIViewController) {
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast)))
        interactionHelper.confirmCopyTo(location: location, context: context, picker: picker)
            .subscribe { [weak self] response in
                guard let self = self else { return }
                switch response.node {
                case let .space(url):
                    self.actionInput.accept(.hideHUD)
                    self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_CreateSuccessfully_Toast)))
                    self.actionInput.accept(.pushURL(url))
                case let .wiki(node, url):
                    self.handleCopyComplete(newWikiNode: node, url: url, location: response.location, picker: picker)
                }
                let targetSpaceID = location.getTargetSpaceID(currentSpaceID: meta.spaceID)
                WikiStatistic.clickFileLocationSelect(targetSpaceId: targetSpaceID,
                                                      fileId: response.statistic.objToken,
                                                      fileType: response.statistic.objType.name,
                                                      filePageToken: response.statistic.pageToken,
                                                      viewTitle: .shortcutTo,
                                                      originSpaceId: meta.spaceID,
                                                      originWikiToken: meta.wikiToken,
                                                      isShortcut: meta.isShortcut,
                                                      triggerLocation: .wikiTree,
                                                      targetModule: location.targetModule,
                                                      targetFolderType: location.targetFolderType)
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                self.actionInput.accept(.showHUD(.failure(self.parseCopyMessage(from: error, location: location))))
            }
            .disposed(by: disposeBag)
    }

    // 创建 wiki copy 后，需要处理树协同逻辑
    private func handleCopyComplete(newWikiNode: WikiServerNode,
                                    url: URL,
                                    location: WorkspacePickerLocation,
                                    picker: UIViewController) {
        moreActionInput.accept(.copy(newNode: newWikiNode))
        actionInput.accept(.hideHUD)
        if newWikiNode.meta.objType == .sheet {
            // sheet文档创建副本有时延问题，创建成功后不直接打开
            picker.dismiss(animated: true)
            let operaiton = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Doc_Facade_MakeCopySucceed_open_btn)
            let tips = BundleI18n.SKResource.Doc_Facade_MakeCopySucceed
            let config = UDToastConfig(toastType: .success, text: tips, operation: operaiton, delay: 4)
            actionInput.accept(.showHUD(.custom(config: config, operationCallback: { [weak self] _ in
                self?.actionInput.accept(.pushURL(url))
            })))
        } else {
            actionInput.accept(.showHUD(.success(BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_CreateSuccessfully_Toast)))
            actionInput.accept(.pushURL(url))
        }
    }

    private func parseCopyMessage(from error: Error, location: CopyLocation) -> String {
        if let networkError = error as? DocsNetworkError {
            if networkError.code == .forbidden {
                // 特化文案
                switch location {
                case .currentLocation:
                    return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                case let .pick(location):
                    switch location {
                    case .wikiNode:
                        return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                    case .folder:
                        return BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantCopy_Tooltip
                    }
                }
            } else if let message = networkError.code.errorMessage {
                return message
            } else if let wikiErrorCode = WikiErrorCode(rawValue: networkError.code.rawValue) {
                return wikiErrorCode.makeCopyErrorDescription
            } else {
                return BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_UnableToCreate_Toast
            }
        } else if case let WikiError.serverError(code) = error,
                  let wikiErrorCode = WikiErrorCode(rawValue: code) {
            return wikiErrorCode.makeCopyErrorDescription
        } else if let wikiErrorCode = WikiErrorCode(rawValue: (error as NSError).code) {
            return wikiErrorCode.makeCopyErrorDescription
        } else {
            return BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_UnableToCreate_Toast
        }
    }
}
