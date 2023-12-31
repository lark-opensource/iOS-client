//
//  LKWSecurityLogUtils.swift
//  LarkWebViewContainer
//
//  Created by ByteDance on 2022/10/18.
//

import Foundation
import LKCommonsLogging
import LarkSetting
import ECOInfra

public final class LKWSecurityLogUtils {
    private static let logger = Logger.lkwlog(LKWSecurityLogUtils.self, category: "securityEncrypt.LKWSecurityLogUtils")
    private static var webURLAES256LogEnable: Bool = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "webview.container.url.encrypted.log.ios"))// user:global
    
    public static func webSafeAESURL(_ url: String, msg: String) {
        guard webURLAES256LogEnable else {
            Self.logger.info("can not encrypt data, fg not enable")
            return
        }
        DispatchQueue.global().async {
            Self.logger.info("\(msg) encrypted_url: \(OPEncryptUtils.webURLAES256Encrypt(content: url))")
        }
    }
}
