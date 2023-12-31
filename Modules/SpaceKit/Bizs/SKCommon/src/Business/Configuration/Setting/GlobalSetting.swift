//
//  GlobalSetting.swift
//  SpaceKit
//
//  Created by huangjinzhu on 2018.
//

import Foundation
import LarkFoundation
import LarkRustHTTP
import LarkRustClient
import SKUIKit
import SKInfra

internal struct GlobalSetting {
    #if DEBUG || BETA
    public static var isDevMenuEnable = true
    #else
    public static var isDevMenuEnable = false
    #endif

    static func appCanDebug() -> Bool {
        #if DEBUG
        return true
        #else
        let suffix = Utils.appVersion.lf.matchingStrings(regex: "[a-zA-Z]+(\\d+)?").first?.first
        return suffix != nil
        #endif
    }


    static func configRustProxy(force: Bool = false) {
        if GlobalSetting.appCanDebug() {
            RustHttpManager.rustService = { DocsContainer.shared.resolve(RustService.self) }
            let systemProxyURL = RustHttpManager.systemProxyURL
            if systemProxyURL != RustHttpManager.globalProxyURL || force {
                RustHttpManager.globalProxyURL = systemProxyURL
            }
        } 
    }
}
