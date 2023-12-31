//
//  MailEnvConfig.swift
//
//  Created by majunxiao on 8/10/2020.
//

import Foundation
import LarkReleaseConfig
import LarkAppConfig
import LarkEnv

struct MailEnvConfig {
    static var isStagingEnv: Bool {
        return EnvManager.env.type == .staging
    }

    static var appEnv: String {
        var res = ""
        if EnvManager.env.type == .release {
            res = "online"
        } else if EnvManager.env.type == .staging {
            res = "boe"
        } else if EnvManager.env.type == .preRelease {
            res = "pre"
        }
        return res
    }
}
