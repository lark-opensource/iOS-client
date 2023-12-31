//
//  DocsIconCache.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/13.
//  缓存meta信息

import Foundation
import LarkStorage
import LarkCache
import LarkAccountInterface
import LarkContainer

class DocsIconCache: UserResolverWrapper {
    
    public var userResolver: LarkContainer.UserResolver
    
    @ScopedProvider private var passport: PassportUserService?
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    private lazy var docsIconCache: Cache = {
        let c: Cache
        let domain = Domain.biz.ccm.child("DocsIconCache")
        let space: Space = .user(id: passport?.user.userID ?? "")
        let cachePath = IsolateSandbox(space: space, domain: domain).rootPath(forType: .document)
        c = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "document/DocsSDK/$uid/DocsIconCache"
        )

        return c
    }()

    func getMetaInfoForKey(Key: String) -> String? {
        guard let data: NSCoding = docsIconCache.object(forKey: Key) else {
            return nil
        }
        return data as? String
    }
    
    func saveMetaInfo(docsToken: String, iconInfo: String) {
        docsIconCache.setObject(iconInfo as NSCoding, forKey: docsToken)
    }
}

