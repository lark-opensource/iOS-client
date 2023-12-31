//
//  SpaceMultiSectionIndexCache.swift
//  SKCommon
//
//  Created by majie.7 on 2023/9/27.
//

import Foundation
import SKFoundation


public class SpaceMultiSectionIndexCache {
    
    
    private var cacheKey: String {
        "space.new.home.multi.section.index.\(identifier)"
    }
    
    private let key = "section.index"
    
    private let needActive: Bool
    private let identifier: String
    
    public init(needActive: Bool, identifier: String) {
        self.needActive = needActive
        self.identifier = identifier
    }
    
    public func set(index: Int) {
        guard needActive else {
            return
        }
        do {
            let dic: [String: Int] = [key: index]
            let data = try JSONEncoder().encode(dic)
            CacheService.configCache.set(object: data, forKey: cacheKey)
        } catch {
            DocsLogger.error("multi.section.index: set multi section index error: \(error)")
        }
    }
    
    public func get() -> Int {
        guard needActive else {
            return 0
        }
        guard let data: Data = CacheService.configCache.object(forKey: cacheKey) else {
            DocsLogger.error("multi.section.index: get multi section index cahce error, no cache data")
            return 0
        }
        do {
            DocsLogger.info("multi.section.index: get multi section index cache success")
            let dic = try JSONDecoder().decode([String: Int].self, from: data)
            let index = dic[key]
            return index ?? 0
        } catch {
            DocsLogger.error("multi.section.index: get multi section index cache error: \(error)")
            return 0
        }
    }
}
