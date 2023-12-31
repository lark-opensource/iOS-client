//
//  LarkMessengerCache.swift
//  LarkCore
//
//  Created by Supeng on 2020/8/18.
//

import Foundation
import LarkCache
import LarkAccountInterface
import LarkStorage

// MARK: fileDownloadCache

private let downloadDomain = Domain.biz.messenger.child("Downloads")

public func fileDownloadRootPath(userID: String) -> IsoPath {
    return .in(space: .user(id: userID), domain: downloadDomain).build(.cache)
}

public var fileDownloadCache: (String) -> CryptoCache = { userID in
    return CacheManager.shared.cache(
        rootPath: fileDownloadRootPath(userID: userID),
        cleanIdentifier: "library/Caches/messenger/user_id/downloads"
    ).asCryptoCache()
}
