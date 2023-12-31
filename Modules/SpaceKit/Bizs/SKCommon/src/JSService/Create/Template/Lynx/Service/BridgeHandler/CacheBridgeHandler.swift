//
//  CacheBridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/4/2.
//  

import BDXBridgeKit
import BDXServiceCenter
import Foundation
import RxSwift

class WriteCacheBridgeHandler: BridgeHandler {
    let methodName = "ccm.setCacheItem"
    let handler: BDXLynxBridgeHandler = { (_, _, params, callback) in
        guard let biz = params?["business"] as? String, let key = params?["key"] as? String else {
            callback(BDXBridgeStatusCode.failed.rawValue, nil)
            return
        }
        let value = params?["data"] as? String
        DispatchQueue.global().async {
            let success = LynxDBManager.shared.update(value: value, key: key, for: biz)
            let code = success ? BDXBridgeStatusCode.succeeded : BDXBridgeStatusCode.failed
            callback(code.rawValue, nil)
        }
    }
}
class ReadCacheBridgeHandler: BridgeHandler {
    let methodName = "ccm.getCacheItem"
    
    let handler: BDXLynxBridgeHandler = { (_, _, params, callback) in
        guard let biz = params?["business"] as? String, let key = params?["key"] as? String else {
            callback(BDXBridgeStatusCode.failed.rawValue, nil)
            return
        }
        DispatchQueue.global().async {
            if let value = LynxDBManager.shared.value(of: key, for: biz) {
                callback(BDXBridgeStatusCode.succeeded.rawValue, ["data": value])
            } else {
                callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
            }
        }
    }
}
