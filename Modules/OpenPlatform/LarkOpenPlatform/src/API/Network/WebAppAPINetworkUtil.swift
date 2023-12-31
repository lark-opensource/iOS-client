//
//  WebAppAPINetworkUtil.swift
//  LarkOpenPlatform
//
//  Created by jiangzhongping on 2023/12/1.
//

import Foundation
import ECOInfra
import LarkSetting

final class WebAppAPINetworkUtil {
        
    private static func domain(_ alias: DomainKey) -> String? {
        return DomainSettingManager.shared.currentSetting[alias]?.first
    }
    
    private static func url(with host: String, path: String) -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if let url = components.url {
            return url.absoluteString
        }
        return nil
    }
    
    static func getRequestURLString(_ alias: DomainKey, path: String) -> String? {
        guard let host = domain(alias) else {
            return nil
        }
        return url(with: host, path: path)
    }
}
