//
//  NetworkMonitor.swift
//  DocsNetwork
//
//  Created by weidong fu on 30/11/2017.
//
//  Included OSS: Terra
//  Copyright (c) 2019 DATree <aobaoaini@gmail.com>
//  spdx license identifier: MIT

import Foundation
import CoreTelephony
import SystemConfiguration
import Reachability

private var managerKey: Void?

public final class DocsNetStateMonitor: SKNetStatusService {
    public var observers: NSHashTable<AnyObject>
    private let observersLock = NSLock()
    public lazy var accessType: NetworkType = {
        return self.accessTypeFor(connection: reach.connection, wwanType: networkInfo?.wwanType() ?? .unknown)
    }()
    public var isReachable: Bool {
        return accessType != .notReachable
    }

    private let reach = Reachability()!
    private var networkInfo: CTTelephonyNetworkInfo?
    private let cellularData = CTCellularData()
    public static let shared = DocsNetStateMonitor()

    private init() {
        observers = NSHashTable(options: .weakMemory)
        try? reach.startNotifier()
        reach.whenReachable = { [weak self] reachability in
            DocsLogger.info("reachable: curentNet: \(reachability.description)", component: LogComponents.net)
            guard let strongSelf = self else {
                return
            }
            
            //这里延时是为了主端任务错开，避免大量任务导致卡顿
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500, execute: {
                strongSelf.updateNetwork(connection: reachability.connection,
                                         celluarState: strongSelf.cellularData.restrictedState)
            })
        }
        reach.whenUnreachable = { [weak self] reachability in
            DocsLogger.info("unreachable: curentNet: \(reachability.description)", component: LogComponents.net)
            guard let strongSelf = self else {
                return
            }

            //这里延时是为了主端任务错开，避免大量任务导致卡顿
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500, execute: {
                strongSelf.updateNetwork(connection: reachability.connection,
                                         celluarState: strongSelf.cellularData.restrictedState)
            })
        }
        DispatchQueue.main.async {
            self.networkInfo = CTTelephonyNetworkInfo()
        }
    }

    public func addObserver(_ observer: AnyObject, _ block: @escaping NetStatusCallback) {
        objc_setAssociatedObject(observer,
                                 &managerKey, block,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        observersLock.lock()
        self.observers.add(observer)
        observersLock.unlock()
        block(self.accessType, self.isReachable)
    }

    public func notify(observer: AnyObject, callback: @escaping NetStatusCallback) {
        self.addObserver(observer, callback)
    }

    private func updateNetwork(connection: Reachability.Connection, celluarState: CTCellularDataRestrictedState) {
        self.accessType = accessTypeFor(connection: connection, wwanType: networkInfo?.wwanType() ?? .unknown)
        observersLock.lock()
        let observers = self.observers.allObjects
        observersLock.unlock()
        for observer in observers {
            let block = objc_getAssociatedObject(observer, &managerKey)
            guard let callback = block as? NetStatusCallback else { return }
            callback(self.accessType, self.isReachable)
        }
        if self.accessType == .notReachable {
            let extraInfo = ["celluarState": celluarState.rawValue, "isRestricted": celluarState == .restricted] as [String: Any]
            DocsLogger.info("nonet, celluar restrict info ", extraInfo: extraInfo, component: LogComponents.net)
        }
    }

    private func accessTypeFor(connection: Reachability.Connection, wwanType: CTTelephonyNetworkInfo.WwanType) -> NetworkType {
        var netType: NetworkType = .notReachable
        switch connection {
        case .none:
            netType = .notReachable
        case .wifi:
            netType = .wifi
        case .cellular:
            switch wwanType {
            case .wwan2G: netType = .wwan2G
            case .wwan3G: netType = .wwan3G
            case .wwan4G: netType = .wwan4G
            case .unknown: netType = .wwan4G
            }
        }
        return netType
    }
}

extension CTTelephonyNetworkInfo {
    fileprivate enum WwanType: Int {
        case wwan2G
        case wwan3G
        case wwan4G
        case unknown
    }

    fileprivate func wwanType() -> WwanType {
        var type: WwanType = .unknown
        guard let carrierType = self.currentRadioAccessTechnology else {
            DocsLogger.info("can not get carrier type", component: LogComponents.net)
            return .unknown
        }
        DispatchQueue.main.once {
            DocsLogger.info("carriertype is \(carrierType)", component: LogComponents.net)
        }
        switch carrierType {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            type = .wwan2G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            type = .wwan3G
        case CTRadioAccessTechnologyLTE:
            type = .wwan4G
        default: type = .unknown
        }
        return type
    }
}
