//
//  OPBlockLoadTaskDelegate.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/11.
//

import Foundation
import OPSDK
import OPBlockInterface

class OPBlockLoadTaskInput: OPTaskInput {
    
    let containerContext: OPContainerContext
        
    let router: OPRouterProtocol
    
    let serviceContainer: OPBlockServiceContainer
            
    required init(
        containerContext: OPContainerContext,
        router: OPRouterProtocol,
        serviceContainer: OPBlockServiceContainer) {
            self.containerContext = containerContext
            self.router = router
            self.serviceContainer = serviceContainer
            super.init()
    }
}

class OPBlockLoadTaskOutput: OPTaskOutput {
    
}

protocol OPBlockLoadTaskDelegate: AnyObject {
    
    /// 开始加载 Compoennt
    func componentLoadStart(task: OPBlockLoadTask, component: OPComponentProtocol, jsPtah: String)
    
    /// 包读取器准备就绪
    func packageReaderReady(packageReader: OPPackageReaderProtocol)
    
    /// 配置准备就绪
    func configReady(projectConfig: OPBlockProjectConfig, blockConfig: OPBlockConfig)

    /// meta加载成功
    func metaLoadSuccess(meta: OPBizMetaProtocol)
    
    /// 包更新完成
    func bundleUpdateSuccess(info: OPBlockUpdateInfo)
}

extension OPBlockLoadTaskDelegate {
    
    func componentLoadStart(
        task: OPBlockLoadTask,
        component: OPComponentProtocol,
        creatorConfig: OPBlockCreatorConfig) {}
    
}
