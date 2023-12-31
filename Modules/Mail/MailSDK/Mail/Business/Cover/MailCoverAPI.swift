//
//  MailCoverAPI.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/5/22.
//

import Foundation

struct MailCoverAPI {
    private static let officalCoverPath = "/mail/api/cover/official/list"

    static func getOfficalCoverURL(configurationProvider: ConfigurationProxy?) -> String {
        let url = "https://" + (configurationProvider?.getDomainSetting(key: .emailBff).first ?? "") + officalCoverPath
        return url
    }

    static func officalCoverURL(configurationProvider: ConfigurationProxy?, token: String, isThumbnail: Bool) -> String {
        var url = "https://" + (configurationProvider?.getDomainSetting(key: .emailCoverCdnPath).first ?? "") + "/\(token)"
        if isThumbnail {
            url += "_s"
        }
        return url
    }
}
