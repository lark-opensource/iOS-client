//
//  OPGadgetDRUtil.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/22.
//

import Foundation
import LKCommonsLogging
import ECOProbe

/// swift 封装 ``NSRecursiveLock``
internal final class OPGadgetDRRecursiveLock {
    private let lock = NSRecursiveLock()
    
    func sync(action: ()-> Void) {
        lock.lock()
        defer { lock.unlock() }
        action()
    }
}

final public class OPGadgetDRLog {
    public static let logger = Logger.oplog(OPGadgetDRLog.self, category: "DisasterRecover")

}

final class OPGadgetDRMonitor {
    
    /// 容灾任务日志
    /// - Parameters:
    ///   - state: 容灾执行状态
    ///   - scene: 触发场景
    ///   - params: 容灾相关参数
    class func monitorEvent(state: Int, params:[String:Any]?, totalTime: Int64 = 0){
        OPMonitor("op_gadget_disaster_recover")
            .addCategoryValue("state",state)
            .addCategoryValue("totalTime", totalTime)
            .addMap(params)
            .flush()
    }
}
