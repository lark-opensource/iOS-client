//
//  KVStore+Ext.swift
//  LarkStorage
//
//  Created by 7Up on 2022/9/29.
//

import Foundation

extension KVStore {

    func allComponents() -> (base: KVStoreBase?, proxies: [KVStoreProxy]) {
        var proxies = [KVStoreProxy]()
        var base: KVStoreBase?

        var iter: KVStore? = self
        repeat {
            if let proxy = iter as? KVStoreProxy {
                proxies.insert(proxy, at: 0)
                iter = proxy.wrapped
            } else if let abase = iter as? KVStoreBase {
                base = abase
                iter = nil
            } else {
                iter = nil
            }
        } while iter != nil

        return (base, proxies)
    }

    func findBase() -> KVStoreBase? {
        return allComponents().base
    }

    func findProxy<T: KVStoreProxy>() -> T? {
        let proxies = allComponents().proxies
        for proxy in proxies {
            if let test = proxy as? T {
                return test
            }
        }
        return nil
    }

}
