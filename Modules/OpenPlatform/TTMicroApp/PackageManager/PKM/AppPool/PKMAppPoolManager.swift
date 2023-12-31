//
//  PKMAppPoolManager.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/30.
//

import Foundation
import OPSDK

protocol PKMAppPoolManagerProtocol {
    func appPoolWith(pkmType: PKMType, isPreview: Bool) -> PKMAppPoolProtocol
}

final class PKMAppPoolManager: PKMAppPoolManagerProtocol {
    //多线程锁，allAppPools 线程安全
    private let appPoolLock = NSLock()
    var allAppPools: [String: PKMAppPoolProtocol] = [:]
    public static let sharedInstance = PKMAppPoolManager()
    
    //通过用类型和是否预览，获取应用池
    func appPoolWith(pkmType: PKMType, isPreview: Bool = false) -> PKMAppPoolProtocol {
        defer{
            appPoolLock.unlock()
        }
        appPoolLock.lock()
        let appPoolKey = "\(pkmType.toString())_\(isPreview)"
        if let appPool = allAppPools[appPoolKey] {
            return appPool
        }
        let appPool = PKMAppPool(pkmType, isPreview: isPreview)
        allAppPools[appPoolKey] = appPool
        return appPool
    }
    
}
