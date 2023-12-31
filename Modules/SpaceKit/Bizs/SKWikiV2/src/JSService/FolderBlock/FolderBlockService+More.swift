//
//  FolderBlockService+More.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/7/27.
//

import Foundation
import SKWorkspace
import SKFoundation
import SpaceInterface
import SKCommon
import EENavigator
import RxSwift
import LarkUIKit
import SKUIKit
import UniverseDesignToast
import UniverseDesignDialog


// MARK: More面板相关

extension FolderBlockService {
    
    private var toastDisplayView: UIView {
        guard let window = ui?.hostView.window else {
            spaceAssertionFailure("folder.block.service: can not get window")
            return ui?.hostView ?? UIView()
        }
        return window
    }

    func handleShowMorePanel(params: [String: Any]) {
        guard let treeNode = params["treeNode"] as? [String: Any],
              let pointX = params["x"] as? Double,
              let pointY = params["y"] as? Double else {
            morePanelSourceReact = nil
            return
        }
        
        guard let wikiNodeMeta = praseWikiTreeNode(params: treeNode), let sourceView = ui?.editorView else {
            return
        }
        let originPoint = CGPoint(x: pointX, y: pointY)
        let point = sourceView.convert(originPoint, to: sourceView)
        let sourceRect = CGRect(origin: point, size: .zero)
        morePanelSourceReact = sourceRect
        
        let moreProviderConfig = WikiTreeMoreDataProviderConfig(sourceView: sourceView, shouldShowCopyToCurrent: true)
        let dataProvider = WikiTreeMoreDataProvider(meta: wikiNodeMeta,
                                                    config: moreProviderConfig,
                                                    spaceInfo: nil,
                                                    permission: nil,
                                                    clipChecker: nil)
        dataProvider.handler = moreProvider
        let moreVM = MoreViewModel(dataProvider: dataProvider, docsInfo: wikiNodeMeta.transform())
        let moreVC = MoreViewControllerV2(viewModel: moreVM)
        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            moreVC.modalPresentationStyle = .popover
            moreVC.popoverPresentationController?.sourceView = sourceView
            moreVC.popoverPresentationController?.sourceRect = sourceRect
            moreVC.popoverPresentationController?.permittedArrowDirections = .any
            navigator?.presentViewController(moreVC, animated: true, completion: nil)
        } else {
            let isInVCFollow = self.model?.browserInfo.docsInfo?.isInVideoConference ?? false
            if isInVCFollow {
                moreVC.modalPresentationStyle = .overFullScreen
            }
            navigator?.presentViewController(moreVC, animated: true, completion: nil)
        }
        
    }
    
    func setupWikiTreeMorePorviderAction() {
        moreProvider.actionSignal
            .emit(onNext: {[weak self] action in
                self?.handleWikiTreeAction(action)
            })
            .disposed(by: disposeBag)
        
        moreProvider.parentProvider = { [weak self] childToken in
            return self?.parentTokenMap[childToken]
        }
    }
    
    private func handleWikiTreeAction(_ action: WikiTreeViewAction) {
        switch action {
        case let .present(provider, popoverConfig):
            guard let view = ui?.editorView else {
                return
            }
            let controller = provider(view)
            popoverConfig?(controller)
            if let morePanelSourceReact {
                controller.popoverPresentationController?.sourceView = view
                controller.popoverPresentationController?.sourceRect = morePanelSourceReact
            }
            
            guard let fromVC = navigator?.presentedVC ?? navigator?.currentBrowserVC else {
                return
            }
            Navigator.shared.present(controller, from: fromVC, completion: {
                if let dialog = controller as? UDDialog,
                   dialog.customMode == .input {
                    dialog.textField.becomeFirstResponder()
                }
            })
        case let .dismiss(controller):
            controller?.dismiss(animated: true)
        case let .push(controller):
            navigator?.pushViewController(controller)
        case let .pushURL(url):
            guard let fromVC = navigator?.currentBrowserVC else {
                return
            }
            navigator?.presentedVC?.dismiss(animated: true)
            Navigator.shared.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: fromVC, animated: true)
        case let .showHUD(subAction):
            handleHUDAction(action: subAction)
        case .hideHUD:
            UDToast.removeToast(on: toastDisplayView)
        case let .customAction(compeletion):
            compeletion(navigator?.currentBrowserVC)
        case .scrollTo, .reloadSectionHeader, .simulateClickState, .showLoading, .showErrorPage:
            return
        }
    }
    
    private func handleHUDAction(action: WikiTreeViewAction.HUDAction) {
        switch action {
        case let .customLoading(text):
            UDToast.showLoading(with: text, on: toastDisplayView, disableUserInteraction: true)
        case let .failure(text):
            UDToast.showFailure(with: text, on: toastDisplayView)
        case let .success(text):
            UDToast.showSuccess(with: text, on: toastDisplayView)
        case let .tips(text):
            UDToast.showTips(with: text, on: toastDisplayView)
        case let .custom(config, operationCallback):
            UDToast.showToast(with: config, on: toastDisplayView) { [weak self] buttonText in
                guard let self else {
                    return
                }
                UDToast.removeToast(on: self.toastDisplayView)
                operationCallback?(buttonText)
            }
        }
    }
    
    private func praseWikiTreeNode(params: [String: Any]) -> WikiTreeNodeMeta? {
        guard let spaceId = params["spaceId"] as? String,
              let wikiToken = params["wikiToken"] as? String,
              let objToken = params["objToken"] as? String,
              let objType = params["objType"] as? Int,
              let nodeTypeRawvalue = params["wikiNodeType"] as? Int,
              let title = params["title"] as? String,
              let hasChild = params["hasChild"] as? Bool,
              let secretKeyDeleted = params["secretKeyDelete"] as? Bool,
              let isExplorerStar = params["isExplorerStar"] as? Bool,
              let isExplorerPin = params["isExplorerPin"] as? Bool,
              let entityDeleted = params["entityDeleteFlag"] as? Int,
              let originIsExternal = params["originIsExternal"] as? Bool,
              let detailInfoStr = params["detailInfo"] as? String,
              let parentToken = params["parentWikiToken"] as? String  else {
            DocsLogger.error("folder block more service lacks params")
            return nil
        }
        var nodeType: WikiTreeNodeMeta.NodeType = .normal
        switch nodeTypeRawvalue {
        case 0:
            nodeType = .normal
        case 1:
            if originIsExternal {
                nodeType = .shortcut(location: .external)
            } else {
                if let originWikiToken = params["originWikiToken"] as? String,
                   let originSpaceId = params["originSpaceId"] as? String {
                    nodeType = .shortcut(location: .inWiki(wikiToken: originWikiToken, spaceID: originSpaceId))
                } else {
                    spaceAssertionFailure("folder block more: shortcut mush has origin info")
                }
            }
        default:
            spaceAssertionFailure("folder block more: has not other node type in the scene")
        }
        let url = params["url"] as? String
        var wikiTreeNode = WikiTreeNodeMeta(wikiToken: wikiToken,
                                            spaceID: spaceId,
                                            objToken: objToken,
                                            objType: DocsType(rawValue: objType),
                                            title: title,
                                            hasChild: hasChild,
                                            secretKeyDeleted: secretKeyDeleted,
                                            isExplorerStar: isExplorerStar,
                                            nodeType: nodeType,
                                            originDeletedFlag: entityDeleted,
                                            isExplorerPin: isExplorerPin,
                                            iconInfo: "", 
                                            url: url)
        if let data = detailInfoStr.data(using: .utf8),
           let detailInfo = try? JSONDecoder().decode(WikiTreeNodeDetailInfo.self, from: data) {
            wikiTreeNode.detailInfo = detailInfo
        } else {
            DocsLogger.warning("folder block more: failed to decode details info of wiki meta")
        }
        
        //更新节点的parent
        parentTokenMap[wikiToken] = parentToken
        
        return wikiTreeNode
    }
}
