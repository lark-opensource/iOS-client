//
//  LarkDocsIconAssembly.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/7/13.
//

import Foundation
import LarkAssembler
import LarkContainer
import LarkSetting

public final class LarkDocsIconAssembly: LarkAssemblyInterface {
    
    public init() {}
    
    enum DocsUserScope {
        static let enableUserScope: Bool = {
            let flag = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.ccm")
            print("[Info] Get CCM userScopeFG: \(flag)")
            return flag
        }()
        
        public static var userScopeCompatibleMode: Bool { !enableUserScope }
        /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
        public static let userScope = UserLifeScope { userScopeCompatibleMode }
        /// 替换.graph, FG控制是否开启兼容模式。没有指定 scope 的默认都为 .graph
        public static let userGraph = UserGraphScope { userScopeCompatibleMode }
    }
    
    public func registContainer(container: Container) {
        
        container.inObjectScope(DocsUserScope.userScope).register(DocsIconManager.self) { r in
            return DocsIconManager(userResolver: r)
        }
        
        container.inObjectScope(DocsUserScope.userScope).register(DocsIconCache.self) { r in
            return DocsIconCache(userResolver: r)
        }
        
        container.inObjectScope(DocsUserScope.userScope).register(DocsUrlUtil.self) { r in
            return DocsUrlUtil(userResolver: r)
        }
        
        container.inObjectScope(DocsUserScope.userScope).register(DocsIconSetting.self) { r in
            return DocsIconSetting(userResolver: r)
        }
        
        container.inObjectScope(DocsUserScope.userScope).register(H5UrlPathConfig.self) { r in
            return H5UrlPathConfig(userResolver: r)
        }
        
        container.inObjectScope(DocsUserScope.userScope).register(DocsIconFeatureGating.self) { r in
            return DocsIconFeatureGating(userResolver: r)
        }
        
        container.inObjectScope(DocsUserScope.userScope).register(DocsIconRequest.self) { r in
            return DocsIconRequest(userResolver: r)
        }
    }
    
}
