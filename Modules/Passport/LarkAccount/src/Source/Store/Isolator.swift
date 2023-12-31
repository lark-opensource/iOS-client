//
//  Isolator.swift
//  LarkAccount
//
//  Created by bytedance on 2021/5/19.
//
import Foundation
import LKCommonsLogging
import UIKit

//sha256
public struct IsolatorConfig {
    let loggerClass: AnyClass
    let shouldEncrypted: Bool // value是否加密
}

public protocol IsolateDataCommonProtocol {
    func removeDataStorage()
}

protocol IsolateDataKVProtocol: IsolateDataCommonProtocol {
    var config: IsolatorConfig { get set }
    var isolatorLayer: String { get set }

    init(config: IsolatorConfig, isolatorLayer: String)

    /* add & update*/
    func update<T>(key: PassportStorageKey<T>, value: T?) -> IsolateDataKVProtocol

    func remove<T>(key: PassportStorageKey<T>) -> IsolateDataKVProtocol

    func get<T>(key: PassportStorageKey<T>) -> T?
}

private class CommonLayers {
    static let global = "Global"
    static let user = "User"
}

class Isolator {

    private init() {}

    static let shared = Isolator()

    let lock = NSLock()
    var isolatorDic: [String: IsolateDataCommonProtocol] = [:]

    static let commonConfig = IsolatorConfig(loggerClass: Isolator.self, shouldEncrypted: true)

    public static var global: IsolateDataKVProtocol {
        return self.shared.createIsolateKVData(namespace: .passportGlobalIsolator, isolatorLayersIds: [CommonLayers.global], isolatorConfig: commonConfig)
    }

    public static func layersGlobal(namespace: IsolatorNamespace) -> IsolateDataKVProtocol { self.shared.createIsolateKVData(namespace: namespace, isolatorLayersIds: [CommonLayers.global], isolatorConfig: commonConfig)
    }

    public static func createIsolateKVData(namespace: IsolatorNamespace, isolatorLayersIds: [String], isolatorConfig: IsolatorConfig? = nil) -> IsolateDataKVProtocol {
        let config = isolatorConfig ?? Self.commonConfig
        return self.shared.createIsolateKVData(namespace: namespace, isolatorLayersIds: isolatorLayersIds, isolatorConfig: config)
    }

    public static func deleteIsolateData(namespace: IsolatorNamespace, isolatorLayersIds: [String]) {
        return self.shared.deleteIsolateData(namespace: namespace, isolatorLayersIds: isolatorLayersIds)
    }
    
}

extension Isolator {
    private func createIsolateKVData(namespace: IsolatorNamespace, isolatorLayersIds: [String], isolatorConfig: IsolatorConfig) -> IsolateDataKVProtocol {
        
        lock.lock()
        defer { lock.unlock() }
        
        let recordKey = genRecordKey(namespace: namespace, isolatorLayersIds: isolatorLayersIds)
        let isolateData = IsolateUserDefaultsData(config: isolatorConfig, isolatorLayer: recordKey)
        isolatorDic[recordKey] = isolateData
        return isolateData
    }

    private func deleteIsolateData(namespace: IsolatorNamespace, isolatorLayersIds: [String]) {
        
        lock.lock()
        defer { lock.unlock() }
        
        let recordKey = genRecordKey(namespace: namespace, isolatorLayersIds: isolatorLayersIds)
        if let storage = isolatorDic[recordKey] {
            isolatorDic.removeValue(forKey: recordKey)
            storage.removeDataStorage()
        }
    }

    private func genRecordKey(namespace: IsolatorNamespace, isolatorLayersIds: [String]) -> String {
        var prefixStr = namespace.rawValue
        for id in isolatorLayersIds {
            prefixStr += "_\(id)"
        }
        return prefixStr
    }
}
