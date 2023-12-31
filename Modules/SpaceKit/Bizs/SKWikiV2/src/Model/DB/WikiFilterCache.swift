//
//  WikiFilterCache.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/12/9.
//

import Foundation
import SKCommon
import SKFoundation
import SKWorkspace

public final class WikiFilterCache {
    public static var shared = WikiFilterCache()
    
    private let cacheKey = "wiki-filter" + (User.current.info?.userID ?? "")
    private let typeKey = "wiki-filter-type"
    private let classKey = "wiki-filter-class"
    
    func set(spaceType: SpaceType, classType: SpaceClassType) {
        do {
            let dic: [String: String] = [typeKey: spaceType.rawValue, classKey: classType.classId]
            let data = try JSONEncoder().encode(dic)
            CacheService.configCache.set(object: data, forKey: cacheKey)
        } catch {
            DocsLogger.error("wiki.home.filter: set wiki filter data error: \(error)")
        }
    }
    
    // all: 全部空间, all: 全部分类
    func get() -> (SpaceType, SpaceClassType) {
        guard let data: Data = CacheService.configCache.object(forKey: cacheKey) else {
            DocsLogger.error("wiki.home.filter: get wiki filter cache error, no cache Data")
            return (.all, .all)
        }
        do {
            DocsLogger.info("wiki.home.filter: get wiki filter cache success")
            let dic = try JSONDecoder().decode([String: String?].self, from: data)
            let type = dic[typeKey] as? String ?? "all"
            let classId = dic[classKey] as? String ?? "all"
            let spaceType = SpaceType(rawValue: type) ?? .all
            if classId == "all" {
                return (spaceType, .all)
            } else {
                return (spaceType, .other(classId))
            }
        } catch {
            DocsLogger.error("wiki.home.filter: get wiki filter cache error: \(error)")
            return (.all, .all)
        }
    }
}
