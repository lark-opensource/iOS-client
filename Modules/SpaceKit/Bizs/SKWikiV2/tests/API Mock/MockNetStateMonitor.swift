//
//  MockNetStateMonitor.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/6/15.
//

import Foundation
import SKFoundation

class MockNetworkStatusMonitor: SKNetStatusService {
    var accessType: NetworkType = NetworkType.wifi
    var isReachable: Bool = true
    private var block: NetStatusCallback?
    // 触发网络状态变化
    func changeTo(networkType: NetworkType, reachable: Bool) {
        isReachable = reachable
        accessType = networkType
        block?(networkType, reachable)
    }
    func addObserver(_ observer: AnyObject, _ block: @escaping NetStatusCallback) {
        self.block = block
    }
}
