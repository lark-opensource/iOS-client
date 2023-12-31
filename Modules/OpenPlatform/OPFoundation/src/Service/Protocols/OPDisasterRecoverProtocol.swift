//
//  OPDisasterRecoverProtocol.swift
//  OPFoundation
//
//  Created by justin on 2023/2/16.
//

import Foundation


/// 容灾恢复框架对外接口，主要获取当前容灾状态
@objc public protocol OPDisasterRecoverProtocol : BDPBasePluginDelegate {
    
    /// 是否有容灾任务在执行
    /// - Returns: true / false
    @objc func isDRRunning() -> Bool
    
}
