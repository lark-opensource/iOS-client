//
//  BTContainerBasePlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import Foundation
import SKBrowser
import SKFoundation

class BTContainerBasePlugin: NSObject, BTContainerPlugin {
    
    weak var service: BTContainerService?
    
    var status: BTContainerStatus
    
    var openFileTraceId: String {
        return service?.browserViewController?.fileConfig?.getOpenFileTraceId() ?? ""
    }
    
    var model: BTContainerModel {
        return service?.model ?? BTContainerModel()
    }
    
    var lastRemakeStatus: BTContainerStatus?
    
    private lazy var pluginName: String = {
        return type(of: self).description()
    }()
    
    required init(status: BTContainerStatus) {
        self.status = status
        super.init()
        
        DocsLogger.info("\(pluginName).init(\(status.statusVersion))")
    }
    
    func load(service: BTContainerService) {
        DocsLogger.info("\(pluginName).load")
        self.service = service
    }
    
    func unload() {
        DocsLogger.info("\(pluginName).unload")
    }
    
    var view: UIView? {
        get {
            return nil
        }
    }
    
    func setupView(hostView: UIView) {
        DocsLogger.info("\(pluginName).setupView")
    }
    
    func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        if stage == .finalStage {
            status = new
            DocsLogger.info("\(pluginName).updateStatus(\(status.statusVersion)) from \(old?.statusVersion ?? -1)")
        }
    }
    
    func remakeConstraints(status: BTContainerStatus) {
        DocsLogger.info("\(pluginName).remakeConstraints(\(status.statusVersion) current:\(self.status.statusVersion)")
        lastRemakeStatus = status
    }
    
    func didUpdateContainerSceneModel(containerSceneModel: ContainerSceneModel) {}
    func didUpdateViewContainerModel(viewContainerModel: BTViewContainerModel) {}
    func didUpdateBlockCatalogueModel(blockCatalogueModel: BlockCatalogueModel, baseContext: BaseContext) {}
    func didUpdateHeaderModel(headerModel: BaseHeaderModel) {}
}
