//
//  OpenJSWorkerQueue.swift
//  TTMicroApp
//
//  Created by yi on 2021/7/8.
//
// worker的节点队列

import Foundation
import OPFoundation
import LarkSetting

@objcMembers
public final class OpenJSWorkerQueue: NSObject {

    // 父worker
    public weak var sourceWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)?
    // worker根节点
    public weak var rootWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)?
    // 一个worker允许派生的最大个数
    private var maxCount = 1
    // worker子节点
    private(set) var works: [String: OPSeperateJSRuntimeProtocol] = [:]

    public func maxWorkerCount() -> Int {
        return maxCount
    }

    public func workersCount() -> Int {
        return works.count
    }

    public func addWorker(worker: OPSeperateJSRuntimeProtocol, workerID: String) {
        if works[workerID] == nil {
            works[workerID] = worker
        }
    }

    public func getWorker(workerID: String) -> OPSeperateJSRuntimeProtocol?  {
        return works[workerID]
    }

    // 从队列移除worker
    public func terminateWorker(workerID: String) {
        if let worker = works[workerID] {
            worker.terminate()
        }
        works.removeValue(forKey: workerID)
    }

    deinit {
        for item in works {
            if let worker = works[item.key] {
                worker.terminate()
            }
        }
        if(FeatureGatingManager.shared.featureGatingValue(with: "openplatform.gadget.evade_jscore_deadlock")) {
            var tmp_workers = works
            DispatchQueue.global().async {
                tmp_workers.removeAll()
            }
        } else {
            works.removeAll()
        }
    }

}
