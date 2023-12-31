//
//  WebAppConfig+Ext.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/23.
//

import Foundation
import LarkSetting
import LarkAccountInterface


extension WebAppConfig {
    func getUrlDomain() -> String? {
        let hostType = self.router.hostConfig.hostType
        switch hostType {
        case "tenant_code":
            //取租户域名
            guard let domain = DomainSettingManager.shared.currentSetting["docs_main_domain"]?.first else {
                WALoader.logger.error("web app config: can not get tenant host")
                return nil
            }
            return domain
        case "biz_domain":
            //取allias中的别名
            guard let alias = router.hostConfig.bizDomainAlias,
                  let key = DomainKey(rawValue: alias) else {
                WALoader.logger.error("web app config: illegal host alias")
                return nil
            }
            guard let domain = DomainSettingManager.shared.currentSetting[key]?.first else {
                WALoader.logger.error("web app config: get domain with alias failed")
                return nil
            }
            let hostArray = domain.components(separatedBy: ".")
            let hostThridlevel = 3
            if hostArray.count < hostThridlevel {
                var tenantCode = AccountServiceAdapter.shared.currentTenant.tenantCode
                if tenantCode.isEmpty {
                    tenantCode = "www"
                }
                return "\(tenantCode).\(domain)"
            } else {
                return domain
            }
        case "const":
            // 取当前域名
            guard let domain = router.hostConfig.constHosts?.first else {
                WALoader.logger.error("web app config: can not get const hosts")
                return nil
            }
            return domain
        default:
            WALogger.logger.error("web app config: the host type not conform to specifications")
            return nil
        }
    }
    
    func getPreloadURL() -> URL? {
        guard let scheme = self.resInterceptConfig?.mainScheme,
              let domain = self.getUrlDomain(),
              let path = self.preloadConfig?.urlPath else {
            WALogger.logger.error("web app config: scheme/domain/path is empty")
            return nil
        }
        guard let url = URL(string: "\(scheme)://\(domain)/\(path)") else {
            WALogger.logger.error("web app config: scheme/domain/path is invalid")
            return nil
        }
        return url
    }
    
    var interceptEnable: Bool {
        guard let enable = self.resInterceptConfig?.enable, enable else {
            return false
        }
        guard let fgKey = self.resInterceptConfig?.fgKey else {
            return true
        }
        let fgOpen = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: fgKey))
        return fgOpen
    }
    
    var needPreload: Bool {
        guard let preloadConfig else { return false }
        return self.interceptEnable && preloadConfig.needPreload
    }
    
    var supportOffline: Bool {
        interceptEnable
    }
    
    /// Loading超时时间(seconds)
    var loadingTimeout: Double {
        let timeout = self.openConfig?.loadingTimeout ?? (WAProloadConfig.defaultTimeout + 5)
        return Double(timeout) / 1000
    }
    
    /// 预加载超时时间(seconds)
    var preloadTimeout: Double {
        let timeout = self.preloadConfig?.timeout ?? WAProloadConfig.defaultTimeout
        return Double(timeout) / 1000
    }
    
    /// 最大复用次数，0侧不复用
    var maxReuseTimes: Int {
        return self.webviewConfig?.maxReuseTimes ?? 0
    }
    
    /// 是否支持webview复用
    var supportWebViewReuse: Bool {
        return needPreload //支持预加载才能复用
    }
}


extension WAProloadConfig {
    var needPreload: Bool {
        self.policy != .none
    }
}
