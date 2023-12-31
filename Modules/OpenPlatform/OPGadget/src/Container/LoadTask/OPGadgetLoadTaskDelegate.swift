//
//  OPGadgetLoadTaskDelegate.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/9.
//

import Foundation
import OPSDK
import TTMicroApp

public final class OPGadgetLoadTaskInput: OPTaskInput {
    
    let containerContext: OPContainerContext
        
    weak var router: OPGadgetContainerRouterProtocol?
            
    required init(
        containerContext: OPContainerContext,
        router: OPGadgetContainerRouterProtocol) {
        self.containerContext = containerContext
        self.router = router
        super.init()
    }
}

public final class OPGadgetLoadTaskOutput: OPTaskOutput {
    
    var shouldRemovePkg: Bool = false
    
    var model: BDPModel?
    
    var common: BDPCommon?
    
    var task: BDPTask?
    
}

public protocol OPGadgetLoadTaskDelegate: AnyObject {
    
    /// 开始加载 Compoennt
    func componentLoadStart(task: OPGadgetLoadTask, component: OPComponentProtocol, jsPtah: String)
    
    /// 包读取器准备就绪
    func onMetaLoadSuccess(model: BDPModel)
    
    /// BDPTask 任务初始化完成
    func didTaskSetuped(uniqueID: BDPUniqueID, task: BDPTask, common: BDPCommon)
    
    /// 包下载失败
    func onPackageLoadFailed(error: OPError)
}

extension OPGadgetLoadTaskDelegate {
    
    public func componentLoadStart(
        task: OPGadgetLoadTask,
        component: OPComponentProtocol) {}
    
    func onMetaLoadSuccess(model: BDPModel) {}
    
    func onPackageLoadFailed(error: OPError) {}
    
}
