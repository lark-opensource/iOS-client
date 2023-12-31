//
//  WikiContainerViewController+Version.swift
//  SKWikiV2
//
//  Created by GuoXinyi on 2022/9/13.
//

import SKCommon
import SKResource
import SKFoundation
import UniverseDesignIcon
import EENavigator
import SKBrowser
import SpaceInterface

extension WikiContainerViewController: VersionParentVCProtocol {
    
    func needRequestVersionToken(token: String, type: DocsType, version: String) -> Bool {
        return !DocsVersionManager.shared.hasVersionToken(token: token, type: type, version: version)
    }
    
    func loadVersionInfo(token: String, type: DocsType, version: String, result: @escaping (Bool, WikiErrorCode?) -> Void) {
        DocsLogger.info("[wiki] load version")
        DocsVersionManager.shared.getVersionTokenWith(token: token, type: type, version: version, needRequest: true) { [weak self] (vToken, _, _, errCode) in
            guard self != nil else { return }
            guard vToken != nil else {
                if errCode == WikiErrorCode.versionNotPermission.rawValue ||
                   errCode == WikiErrorCode.versionEditionIdForbidden.rawValue ||
                    errCode == VersionErrorCode.versionEditionIdLengthErr.rawValue {
                    self?.viewModel.updateVersion(version: "", from: nil)
                    result(true, nil)
                } else if errCode != WikiErrorCode.versionNotFound.rawValue,
                          errCode != WikiErrorCode.sourceNotFound.rawValue,
                          errCode != WikiErrorCode.sourceDelete.rawValue {
                    result(false, .versionTokenOtherFail)
                } else {
                    DocsVersionManager.shared.deleteAllVersionData(type: type, token: token)
                    result(false, WikiErrorCode(rawValue: errCode) ?? .versionTokenOtherFail)
                }
                return
            }
            result(true, nil)
        }
    }
    
    public func didChangeVersionTo(item: SKCommon.DocsVersionItemData, from: FromSource?) {
        let (wikiInfo, wikitreeInfo) = self.viewModel.updateVersion(version: item.version, from: from)
        handleViewState(state: .success(displayInfo: wikiInfo, treeInfo: wikitreeInfo))
    }
    
    public func didClickPrimaryButton() {
        guard let rootVC = self.navigationController else { return }
        if var components = URLComponents(string: self.viewModel.wikiURL.absoluteString) {
            components.query = nil // 移除所有参数
            let finalUrl = components.string
            if finalUrl != nil, let sourceURL = URL(string: finalUrl!) {
                userResolver.navigator.push(sourceURL, from: rootVC)
            }
        }
    }

}
