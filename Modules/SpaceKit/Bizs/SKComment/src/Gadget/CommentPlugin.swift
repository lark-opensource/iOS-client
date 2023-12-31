//
//  CommentPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/6.
//  

import SKFoundation
import LarkOpenAPIModel
import SKCommon
import SKInfra

class CommentPlugin {

    // MARK: - private
    
    lazy var jsServiceManager = GadgetJSServicesManager()
    
    lazy var offlineSyncManager: DocsOfflineSyncManager? = DocsContainer.shared.resolve(DocsOfflineSyncManager.self)
    
    public init() {
        self.registerRN()
    }
    
    func update(context: OpenAPIContext) {
        self.jsServiceManager.update(context: context)
    }
}

// MARK: - private func

extension CommentPlugin {
    
    
    private func registerRN() {
        guard RNManager.manager.hadStarSetUp == false else {
            DocsLogger.info("registerRN RNManager hadStarSetUp", component: LogComponents.gadgetComment)
            return
        }
        guard let offlineSyncManager = offlineSyncManager else {
            DocsLogger.error("registerRN offlineSyncManager is nil", component: LogComponents.gadgetComment)
            return
        }
        RNManager.manager.loadBundle()
        RNManager.manager.registerRnEvent(eventNames: [.rnGetData,
                                                       .rnSetData,
                                                       .logger,
                                                       .batchLogger,
                                                       .showQuotaDialog,
                                                       .rnStatistics],
                                          handler: offlineSyncManager)
    }
}
