//
//  OPGadgetComponentLoadTaskDelegate.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/9.
//

import Foundation
import OPSDK
import TTMicroApp

class OPGadgetComponentLoadTaskInput: OPTaskInput {
    
    let containerContext: OPContainerContext
    
    weak var task: BDPTask?
    
    weak var common: BDPCommon?
    
    weak var router: OPGadgetContainerRouterProtocol?
 
    required init(
        containerContext: OPContainerContext,
        router: OPGadgetContainerRouterProtocol) {
        self.containerContext = containerContext
        self.router = router
        super.init()
    }
}

class OPGadgetComponentLoadTaskOutput: OPTaskOutput {
    
}

protocol OPGadgetComponentLoadTaskDelegate: AnyObject {
    
    /// 开始加载 Compoennt
    func componentLoadStart(task: OPGadgetComponentLoadTask, component: OPComponentProtocol, jsPtah: String)
    
}

extension OPGadgetComponentLoadTaskDelegate {
    
    public func componentLoadStart(task: OPGadgetComponentLoadTask, component: OPComponentProtocol) {}
    
}

