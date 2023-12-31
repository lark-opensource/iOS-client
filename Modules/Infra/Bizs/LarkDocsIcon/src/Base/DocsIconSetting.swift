//
//  DocsIconSetting.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/25.
//

import Foundation
import LarkSetting
import LarkContainer

class DocsIconSetting: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    
    @ScopedProvider private var settingService: SettingService?
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public var domainConfig: [String: Any]? {
        return try? self.settingService?.setting(with: UserSettingKey.make(userKeyLiteral: "domain_config"))
    }
    
    public var ccmCustomIconConfig: [String: Any]? {
        return try? self.settingService?.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_custom_icon_config"))
    }
    
    private var _bucketPath: String = ""
    public var bucketPath: String {
        if _bucketPath.isEmpty {
            let path = self.ccmCustomIconConfig?["bucket_path"] as? String ?? ""
            _bucketPath = path
        }
        return _bucketPath
    }
}

class DocsIconDomain {
    
    public static var docsDomain: String {
        
        return domain(of: .docsApi)
    }
    
    //后续larkIconDisable fg删掉，这个函数也删除
    public static var cdn: String {

        return domain(of: .cdn)
    }
    
    private static func domain(of alias: DomainKey) -> String {
        guard let domain = DomainSettingManager.shared.currentSetting[alias]?.first else {
            DocsIconLogger.logger.error("Docs icon get domain setting failed,alias: \(alias)")
            return ""
        }
        return domain
    }
}
