//
//  SyncedBlockService.swift
//  SKDoc
//
//  Created by lijuyou on 2023/8/8.
//

import SKFoundation
import SKUIKit
import SKCommon
import SKBrowser
import SKInfra
import EENavigator
import LarkWebViewContainer


class SyncedBlockService: BaseJSService {
    private var showReferencesCallback: APICallbackProtocol?
    private weak var currentSyncBlockVC: SyncBlockReferenceViewController?
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}
extension SyncedBlockService: JSServiceHandler {
    
    var handleServices: [DocsJSService] {
        return [.showSyncedBlockReferences]
    }
    
    func handle(params: [String : Any], serviceName: String) {
        spaceAssertionFailure()
    }
    
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        guard let hostDocsInfo = self.hostDocsInfo, let fromVC = self.registeredVC else {
            spaceAssertionFailure("invalid params")
            return
        }
        if serviceName == DocsJSService.showSyncedBlockReferences.rawValue {
            DocsLogger.info("showSyncedBlockReferences,show:\(!params.isEmpty)", component: LogComponents.syncBlock)
           
            guard !params.isEmpty, let showParam = try? CodableUtility.decode(ShowSyncedBlockReferencesParam.self, withJSONObject: params) else {
                spaceAssertionFailure("params is empty or decode ShowSyncedBlockReferencesParam failed")
                self.currentSyncBlockVC?.close()
                self.currentSyncBlockVC = nil
                return
            }
            
            if self.currentSyncBlockVC?.viewModel.config == showParam {
                DocsLogger.warning("already open samepage", component: LogComponents.syncBlock)
                return
            }
            
            let showBlock = { [weak self] in
                guard let self = self else { return }
                self.showReferencesCallback = callback
                let vc = SyncBlockReferenceViewController(docsInfo: hostDocsInfo, showParam: showParam)
                vc.delegate = self
                vc.modalPresentationStyle = .overCurrentContext
                let allow = self.model?.permissionConfig.checkCanCopy(for: .referenceDocument(objToken: showParam.docxSyncedBlockHostToken)) ?? false
                vc.setCaptureAllowed(allow)
                self.currentSyncBlockVC = vc
                self.model?.userResolver.navigator.present(vc, from: fromVC, animated: true)
            }
            if self.currentSyncBlockVC != nil {
                DocsLogger.info("close last syncblockVC", component: LogComponents.syncBlock)
                self.currentSyncBlockVC?.close(animated: false) {
                    showBlock()
                }
                self.currentSyncBlockVC = nil
            } else {
                showBlock()
            }
        }
    }
}

extension SyncedBlockService: SyncBlockReferenceVCDelegate {
    func syncBlock(vc: SyncBlockReferenceViewController, onMoreClick syncBlockToken: String) {
        DocsLogger.info("onMoreClick", component: LogComponents.syncBlock)
        model?.jsEngine.callFunction(DocsJSCallBack.syncBlockMoreMenuClick,
                                     params: ["moreId": "syncedBlockReferencesMore"],
                                     completion: nil)
    }
    
    func syncBlock(vc: SyncBlockReferenceViewController, onClose syncBlockToken: String) {
        self.showReferencesCallback?.callbackSuccess(param: ["closed": true])
    }
    
    func syncBlock(vc: SyncBlockReferenceViewController, onItemClick item: SyncBlockReferenceItem) {
        guard let url = URL(string: item.url) else {
            spaceAssertionFailure("invalid url")
            return
        }
        DocsLogger.info("oonItemClick", component: LogComponents.syncBlock)
        vc.close()
        self.navigator?.requiresOpen(url: url)
        
        DispatchQueue.global().async {
            var params = ["click": "block_custom_action",
                          "target": "none",
                          "object_block_data": item.objId.encryptToken]
            
            if !item.isCurrent {
                params["action_type"] = item.isSource ? "click_synced_source_reference_docs" : "click_synced_reference_source_docs"
                params["action_value"] = DocsUrlUtil.getFileToken(from: url)?.encryptToken ?? ""
            }
            DocsTracker.newLog(enumEvent: .docContentPageClick, parameters: params)
        }
    }
}
