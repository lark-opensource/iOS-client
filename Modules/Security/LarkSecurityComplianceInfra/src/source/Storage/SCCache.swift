//
//  SCCache.swift
//  LarkSecurityComplianceInfra
//
//  Created by AlbertSun on 2023/6/13.
//

import Foundation
import LarkCache
import LarkStorage

// 通过 LarkCache 缓存的数据可以通过通用设置清除缓存来清除，无豁免路径
public var securityComplianceCache: (String, SncBiz) -> CryptoCache = { (uid, biz) in
    return CacheManager.shared.cache(
        rootPath: scIsoPath(userId: uid, biz: biz),
        cleanIdentifier: "library/Caches/securityCompliance/user_id/\(biz.isolationId)"
    ).asCryptoCache()
}

public func scIsoPath(userId: String, biz: SncBiz) -> IsoPath {
    return IsolateSandbox(space: .user(id: userId),
                          domain: biz)
    .rootPath(forType: .cache)
}
