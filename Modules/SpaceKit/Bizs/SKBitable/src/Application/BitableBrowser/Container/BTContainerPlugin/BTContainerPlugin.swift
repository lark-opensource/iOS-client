//
//  BTContainerPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import Foundation
import SKBrowser

protocol BTContainerPluginModelProtocol{
    var model: BTContainerModel { get }
    func didUpdateContainerSceneModel(containerSceneModel: ContainerSceneModel)
    func didUpdateViewContainerModel(viewContainerModel: BTViewContainerModel)
    func didUpdateBlockCatalogueModel(blockCatalogueModel: BlockCatalogueModel, baseContext: BaseContext)
    func didUpdateHeaderModel(headerModel: BaseHeaderModel)
}

protocol BTContainerPlugin: AnyObject, BTContainerPluginModelProtocol {
    var status: BTContainerStatus { get set }
    var openFileTraceId: String { get }
    
    func load(service: BTContainerService)          // 加载
    func unload()                                   // 卸载
    
    var view: UIView? { get }                       // 获取对应的 view
    
    func setupView(hostView: UIView)
    
    // 更新组件状态
    func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage)
    // 更新布局
    func remakeConstraints(status: BTContainerStatus)
}

