//
//  OPGadgetDRTask.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/17.
//

import Foundation
import Dispatch

/// 容灾Task执行完成回调，module模块可以感知任务执行完成状态
protocol OPGadgetDRTaskLifecycle: AnyObject {
     func taskDidFinished(_ curTask: OPGadgetDRTask)
}

/// 小程序容灾任务基础类
class OPGadgetDRTask : NSObject {
    
    weak var taskDelegate : OPGadgetDRTaskLifecycle?
    var taskConfig : OPGadgetDRConfig?
    init(_ drModule : OPGadgetDRTaskLifecycle?) {
        self.taskDelegate = drModule
        super.init()
    }
    
    func execute(config: OPGadgetDRConfig?) {
        self.taskConfig = config
        
    }
    
    func finishedTask() {
        self.taskDelegate?.taskDidFinished(self)
    }
}
