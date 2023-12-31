//
//  BTContainer+Model.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/19.
//

import SKFoundation

/// 当前容器级别的数据 Model
class BTContainerModel {
    fileprivate(set) var viewContainerModel: BTViewContainerModel?
    
    fileprivate(set) var containerSceneModel: ContainerSceneModel?
    
    fileprivate(set) var blockCatalogueModel: BlockCatalogueModel?
    
    fileprivate(set) var headerModel: BaseHeaderModel?
}

// 核心数据是否 Ready
extension BTContainerModel {
    /// 主框架核心数据是否 Ready， 包括
    /// 1. Header 是否有效
    /// 2. MainScene 和 ViewCatalogue 数据是否有效
    var isMainContainerReady: Bool {
        get {
            isHeaderReady && isViewContainerReady
        }
    }
    
    var isViewContainerReady: Bool {
        get {
            guard let sceneModel = containerSceneModel else {
                return false
            }
            guard let blockType = sceneModel.blockType else {
                return false
            }
            switch blockType {
            case .dashboard:
                return true
            case .linkedDocx:
                return true
            case .table:
                guard let viewContainerModel = viewContainerModel else {
                    return false
                }
                guard viewContainerModel.viewList?.isEmpty == false else {
                    return false
                }
                return true
            }
        }
    }
    
    var isHeaderReady: Bool {
        get {
            headerModel?.hasValidData() == true
        }
    }
}

extension BTContainer {
    
    func checkMainContainerReady() {
        if model.isMainContainerReady {
            // 从超时态恢复
            setContainerTimeout(containerTimeout: false)
        }
    }
    
    func updateViewContainerModel(viewContainerModel: BTViewContainerModel) {
        executeMain { [weak self] in
            guard let self = self else {
                return
            }
            DocsLogger.info("BTContainer.updateViewContainerModel")
            self.model.viewContainerModel = viewContainerModel
            self.checkMainContainerReady()
            self.plugins.values.forEach { plugin in
                plugin.didUpdateViewContainerModel(viewContainerModel: viewContainerModel)
            }
        }
    }
    
    func updateContainerSceneModel(containerSceneModel: ContainerSceneModel) {
        executeMain { [weak self] in
            guard let self = self else {
                return
            }
            if containerSceneModel == self.model.containerSceneModel {
                // 支持去重
                return
            }
            DocsLogger.info("BTContainer.updateViewContainerModel")
            self.model.containerSceneModel = containerSceneModel
            self.checkMainContainerReady()
            self.setSceneModel(sceneModel: containerSceneModel)    // 同步设置到 Status 中，动画依赖
            self.plugins.values.forEach { plugin in
                plugin.didUpdateContainerSceneModel(containerSceneModel: containerSceneModel)
            }
        }
    }
    
    func updateBlockCatalogueModel(blockCatalogueModel: BlockCatalogueModel, baseContext: BaseContext) {
        executeMain { [weak self] in
            guard let self = self else {
                return
            }
            if blockCatalogueModel.closePanel {
                // 关闭面板的指令
                DocsLogger.info("BTContainer.updateViewContainerModel.closePanel")
                self.setBlockCatalogueHidden(blockCatalogueHidden: true, animated: true)
                return
            }
            DocsLogger.info("BTContainer.updateViewContainerModel")
            self.model.blockCatalogueModel = blockCatalogueModel
            self.plugins.values.forEach { plugin in
                plugin.didUpdateBlockCatalogueModel(blockCatalogueModel: blockCatalogueModel, baseContext: baseContext)
            }
        }
    }
    
    func updateHeaderModel(headerModel: BaseHeaderModel) {
        executeMain { [weak self] in
            guard let self = self else {
                return
            }
            DocsLogger.info("BTContainer.updateHeaderModel")
            self.model.headerModel = headerModel
            self.checkMainContainerReady()
            self.plugins.values.forEach { plugin in
                plugin.didUpdateHeaderModel(headerModel: headerModel)
            }
        }
    }
}

fileprivate func executeMain(workItem: @escaping () -> Void) {
    if Thread.isMainThread {
        workItem()
    } else {
        DispatchQueue.main.async {
            workItem()
        }
    }
}
