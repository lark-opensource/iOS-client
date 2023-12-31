//
//  BlockitConfig.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import LarkSetting

final class BlockitConfig {
    let token: String
    let deviceId: String
    let contentType = "application/json"
    let cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy

    var urlPrefix: String {
        let domain = DomainSettingManager.shared.currentSetting[.open]?.first ?? ""
        return "https://" + domain
    }

    init(token: String, deviceId: String) {
        self.token = token
        self.deviceId = deviceId
    }
}
