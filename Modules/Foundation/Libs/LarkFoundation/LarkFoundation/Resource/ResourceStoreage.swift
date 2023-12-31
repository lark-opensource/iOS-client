//
//  ResourceStoreage.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/5/23.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum ResourceStorageOption {
    case decode((Data) -> Data?)
    case encode((Data) -> Data?)
    case keyToFileName((String) -> String)
    case callbackQueue(DispatchQueue)
}

public protocol CanStorage: AnyObject {
    associatedtype Resource
    func getData() -> Data
    static func generate(data: Data) -> Self.Resource?
}

public protocol ResourceStorage {
    associatedtype ResourceItem: CanStorage

    var name: String { get set }
    var options: [ResourceStorageOption] { get set }

    func isMemeryCached(key: String) -> Bool
    func isCached(key: String) -> Bool
    func isDiskCached(key: String) -> Bool
    func store(key: String, resource: ResourceItem, compliteHandler: ((Data?) -> Void)?)
    func store(key: String, oldKey: String, resource: ResourceItem)
    func remove(key: String)
    func get(key: String) -> ResourceItem?
    func get(key: String, resourceBlock: @escaping (ResourceItem?) -> Void)
    func getFromDisk(key: String) -> ResourceItem?
    func cachePath(key: String) -> String
    func removeAllCache()
}
