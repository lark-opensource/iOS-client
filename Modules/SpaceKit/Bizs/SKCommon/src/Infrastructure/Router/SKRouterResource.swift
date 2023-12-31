//
//  SKRouterResource.swift
//  SpaceKit
//
//  Created by Gill on 2019/12/23.
//

import SKFoundation
import SpaceInterface

public protocol SKRouterResource {
    var url: URL { get }
    var isSupported: Bool { get }
    var docsType: DocsType { get }
    var isVersion: Bool { get }
}
extension URL: SKRouterResource {
    public var url: URL { return self }
    public var isSupported: Bool { return  URLValidator.isSupportURLRawtype(url: self).0 }
    public var docsType: DocsType { return  URLValidator.isSupportURLRawtype(url: self).1 }
    public var isVersion: Bool { return URLValidator.isDocsVersionUrl(self) }
}
extension SpaceEntry: SKRouterResource {
    public var url: URL {
        
        //文档域名优化，使用原始的url，如果originUrl取不到，兜底拼接的
        if UserScopeNoChangeFG.HZK.mgDomainOptimize,
            let originUrl = self.originUrl,
            let originUrl = URL(string: originUrl) {
            return originUrl
        }
        return DocsUrlUtil.url(type: type, token: objToken)
    }
    public var isSupported: Bool { return isSupportedType() }
    public var docsType: DocsType { return type }
    public var isVersion: Bool {
        guard let urlString = self.shareUrl, let url = URL(string: urlString) else {
            return false
        }
        return URLValidator.isDocsVersionUrl(url)
    }
}

extension SpaceEntry {
    /// 真实类型（如果是 wiki 会从 wiki 内解析出真实类型）
    public var realType: DocsType {
        if let wikiEntry = self as? WikiEntry {
            return wikiEntry.wikiInfo?.docsType ?? wikiEntry.docsType
        }
        return docsType
    }
}
