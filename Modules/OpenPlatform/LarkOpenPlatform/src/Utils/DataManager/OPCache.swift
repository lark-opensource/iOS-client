//
//  OPCache.swift
//  LarkOpenPlatform
//
//  Created by  bytedance on 2020/9/24.
//

import Foundation
import LarkCache
import LarkAccountInterface

/// openPlatform模块，存储路径为"openPlatform"
public enum OPBiz: Biz {
    public static var parent: Biz.Type?
    public static var path: String = "openPlatform"
}

/// 用户路径
public enum UserDirectory: Biz {
    public static var parent: Biz.Type? = OPBiz.self
    public static var path: String {
        "LarkUser_" + AccountServiceAdapter.shared.currentChatterId
    }
}

/// 功能路径，download
public enum RequestCache: Biz {
    public static var parent: Biz.Type? = UserDirectory.self
    public static var path: String = "requestsCache"
}

/// openPlatform的后台请求结果的缓存
public var OPRequestCache: () -> Cache = {
    CacheManager.shared.cache(biz: RequestCache.self, directory: .cache, cleanIdentifier: "library/Caches/openPlatform/user_id/requestsCache")
}

/// messageCard cache
public enum MessageCardCache: Biz {
    public static var parent: Biz.Type? = UserDirectory.self
    public static var path: String = "messageCardCache"
}

/// messageCard style cache
public var OPMessageCardStyleCache: () -> Cache = {
    CacheManager.shared.cache(biz: MessageCardCache.self,
                              directory: .cache,
                              cleanIdentifier: "library/Caches/openPlatform/user_id/messageCardCache")
}
