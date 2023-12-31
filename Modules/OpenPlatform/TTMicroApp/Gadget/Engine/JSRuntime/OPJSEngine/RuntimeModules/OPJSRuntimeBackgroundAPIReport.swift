//
//  OPJSRuntimeBackgroundAPIReport.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/7/7.
//

import Foundation
import ECOProbe
import OPFoundation
import LKCommonsLogging

final class OPJSRuntimeBackgroundAPIReport {
    
    private var beginTime: TimeInterval?
    var queue: [String] = []
    private let lock = NSRecursiveLock()
    static let logger = Logger.log(OPJSRuntimeBackgroundAPIReport.self, category: "TTMicroApp")
    
    func enterBackground() {
        lock.lock()
        defer {
            lock.unlock()
        }
        beginTime = Date().timeIntervalSince1970
        queue.removeAll()
    }
    
    func enterForeground(uniqueID: OPAppUniqueID?) {
        guard let uniqueID else {
            Self.logger.error("enterForeground fail, uniqueID is nil")
            return
        }

        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard let beginTime else {
            Self.logger.error("enterForeground fail, beginTime is nil")
            return
        }
        guard !queue.isEmpty else {
            self.beginTime = nil
            return
        }
        
        let duration = Int((Date().timeIntervalSince1970 - beginTime) * 1000)
        
        let appTracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        
        let categoryMap = categoryMap(queue: queue, duration: duration)
        queue.removeAll()
        self.beginTime = nil
        
        OPMonitor(kEventName_op_client_api_block_list_when_background)
            .setUniqueID(uniqueID)
            .tracing(appTracing)
            .addCategoryMap(categoryMap)
            .setPlatform(.slardar)
            .flush()
    }
    
    func push(apiName: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard beginTime != nil else {
            // 不在后台的时候不能填入
            return
        }
        queue.append(apiName)
    }
}

func categoryMap(queue: [String], duration: Int) -> [String: any Codable & Equatable] {
    let count = queue.count
    
    let sortedPairs = queue.toSorteDictionaryByValue()
    
    let category1to5 = printMap(sortedPairs: sortedPairs)
    
    var baseParams: [String: any Codable & Equatable] = [
        "api_count" : count,
        "duration": duration,
    ].merging(category1to5) { $1 }
    
    if (count < 20) { // 总数<20
        baseParams["api_list"] = queue.joined(separator: ",")
    } else {
        // 取有序数组的前20个元素
        baseParams["api_list"] = toJSONString(sortedPairs: Array(sortedPairs.prefix(20)))
    }
    return baseParams
}

func toJSONString(sortedPairs: [(String, Int)]) -> String {
    sortedPairs.map { key, value in
        "\(key):\(value)"
    }.joined(separator: ",")
}

fileprivate func printMap(sortedPairs: [(String, Int)]) -> [String: any Codable & Equatable] {
    var result: [String: any Codable & Equatable] = [:]
    (1...5).forEach { index in
        if sortedPairs.count > index - 1 {
            let element = sortedPairs[index - 1]
            result["api_name\(index)"] = element.0
            result["api_count\(index)"] = element.1
        } else {
            result["api_name\(index)"] = ""
            result["api_count\(index)"] = 0
        }
    }
    return result
}

fileprivate extension Array where Element == String {
    func toSorteDictionaryByValue() -> [(String, Int)] {
        var dictionary = OrderedDictionary()
        
        for element in self {
            if let count = dictionary[element] {
                dictionary[element] = count + 1
            } else {
                dictionary[element] = 1
            }
        }
        
        let sortedPairs = dictionary.sortedByValueDescending()
        return sortedPairs
    }
}

struct OrderedDictionary {
    private var keys: [String] = []
    private var values: [String: Int] = [:]

    subscript(key: String) -> Int? {
        get {
            return values[key]
        }
        set {
            if let newValue = newValue {
                updateValue(newValue, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }

    mutating func updateValue(_ value: Int, forKey key: String) {
        if values[key] == nil {
            keys.append(key)
        }
        values[key] = value
    }

    mutating func removeValue(forKey key: String) {
        keys.removeAll { $0 == key }
        values[key] = nil
    }
    
    func sortedByValueDescending() -> [(key: String, value: Int)] {
        return keys.sorted { lhs, rhs in
            let lhsValue = values[lhs] ?? 0
            let rhsValue = values[rhs] ?? 0
            return lhsValue > rhsValue
        }.map { ($0, values[$0] ?? 0) }
    }
}
