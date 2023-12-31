//
//  MyLibraryCache.swift
//  SKCommon
//
//  Created by majie.7 on 2023/2/3.
//

import Foundation
import SKFoundation

public class MyLibrarySpaceIdCache {
    
    
    private static var cacheKey: String {
        "wiki-library"
    }
    
    private static let key = "wiki-library-space-id"
    
    public static func set(spaceId: String) {
        do {
            let dic: [String: String] = [key: spaceId]
            let data = try JSONEncoder().encode(dic)
            CacheService.configCache.set(object: data, forKey: cacheKey)
            DocsLogger.info("wiki.my.library: set my library space id succeed, id is \(spaceId.encryptToken)")
        } catch {
            DocsLogger.error("wiki.my.library: set my library space id error: \(error)")
        }
    }
    
    public static func get() -> String? {
        guard let data: Data = CacheService.configCache.object(forKey: cacheKey) else {
            DocsLogger.error("wiki.my.library: get my library space id cahce error, no cache data")
            return nil
        }
        do {
            let dic = try JSONDecoder().decode([String: String].self, from: data)
            let spaceId = dic[key]
            DocsLogger.info("wiki.my.library: get my library space id cache success, id is \(String(describing: spaceId?.encryptToken))")
            return spaceId
        } catch {
            DocsLogger.error("wiki.my.library: get my library cache error: \(error)")
            return nil
        }
    }
    
    public static func isMyLibrary(_ spaceId: String) -> Bool {
        let libraryId = get()
        return libraryId == spaceId
    }
}
