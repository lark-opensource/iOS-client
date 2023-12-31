//
//  OPBlockComponentLoadTaskDelegate.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/11.
//

import Foundation
import OPSDK

class OPBlockComponentLoadTaskInput: OPTaskInput {
    
    let containerContext: OPContainerContext
    
    let router: OPRouterProtocol
 
    required init(
        containerContext: OPContainerContext,
        router: OPRouterProtocol) {
        self.containerContext = containerContext
        self.router = router
        super.init()
    }
}

class OPBlockComponentLoadTaskOutput: OPTaskOutput {
    
}

protocol OPBlockComponentLoadTaskDelegate: AnyObject {
    
    /// 开始加载 Compoennt
    func componentLoadStart(task: OPBlockComponentLoadTask, component: OPComponentProtocol, jsPtah: String)
    
}

extension OPBlockComponentLoadTaskDelegate {
    
    func componentLoadStart(task: OPBlockComponentLoadTask, component: OPComponentProtocol) {}
    
}
