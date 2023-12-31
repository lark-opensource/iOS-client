//
//  PluginManager.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/24.
//

import Foundation
import ThreadSafeDataStructure

typealias Factory = () -> ReachPointPlugin
typealias Element = (reachPointType: String, factory: Factory, instance: ReachPointPlugin?)

final class PluginManager {
    let type2Plugin: SafeDictionary<String, Element> = [:] + .readWriteLock

    init() {}

    func addPlugin(reachPointType: String, factory: @escaping Factory, instance: ReachPointPlugin? = nil) {
        guard type2Plugin[reachPointType] == nil else {
            return
        }
        type2Plugin[reachPointType] = Element(reachPointType: reachPointType, factory: factory, instance: instance)
    }

    func removePlugin(reachPointType: String) {
        type2Plugin.removeValue(forKey: reachPointType)
    }

    func getPlugin(reachPointType: String) -> ReachPointPlugin? {
        guard let element = type2Plugin[reachPointType] else {
            return nil
        }
        return element.instance ?? createPlugin(reachPointType: reachPointType)
    }

    func createPlugin(reachPointType: String) -> ReachPointPlugin? {
        guard let element = type2Plugin[reachPointType] else {
            return nil
        }
        let instance = element.factory()
        type2Plugin[reachPointType] = Element(reachPointType: reachPointType,
                                              factory: element.factory,
                                              instance: instance)
        return instance
    }

    func contains(reachPointType: String) -> Bool {
        return type2Plugin.contains { $0.key == reachPointType }
    }
}
