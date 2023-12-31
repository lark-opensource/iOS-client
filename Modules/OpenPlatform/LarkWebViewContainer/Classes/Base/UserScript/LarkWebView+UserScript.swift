//
//  LarkWebView+UserScript.swift
//  LarkWebViewContainer
//
//  Created by yinyuan on 2022/4/12.
//

import Foundation
import LarkSetting
import LarkPrivacySetting

extension LarkWebView {
    
    func setupUserScript() {
        
        if FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.geo_check.disable")) == false {// user:global
        if !LarkLocationAuthority.checkAuthority() {
            let userScript = WKUserScript(source: WebUserScript.geoLocationDisable, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            configuration.userContentController.addUserScript(userScript)
        }
        }
    }
    
}
