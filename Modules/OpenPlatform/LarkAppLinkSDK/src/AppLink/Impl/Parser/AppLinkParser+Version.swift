//
//  AppLinkParser+Version.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/30.
//

import Foundation
import LarkFoundation

extension AppLinkParser {
    
    /// 检查版本是否可用
    func checkVersionAvailable(_ appLink: AppLink) -> Bool {
        let queryParameters = appLink.url.queryParameters
        let larkVer = LarkFoundation.Utils.appVersion
        guard !larkVer.isEmpty,
            let minVer = queryParameters["min_lk_ver_ios"] ?? queryParameters["min_lk_ver"],
            !minVer.isEmpty,
            let larkVerInfo = versionInfo(larkVer),
            let minVerInfo = versionInfo(minVer) else {
                return true
        }

        return !((larkVerInfo.0 < minVerInfo.0) ||
            (larkVerInfo.0 == minVerInfo.0 && larkVerInfo.1 < minVerInfo.1) ||
            (larkVerInfo.0 == minVerInfo.0 && larkVerInfo.1 == minVerInfo.1 && larkVerInfo.2 < minVerInfo.2))
    }

    /// 提取 SemVer 版本号 (major,minor,patch)
    private func versionInfo(_ version: String) -> (Int, Int, Int)? {
        let components = version.components(separatedBy: "-")
        guard let baseVersion = components.first else {
            return nil
        }
        let versionComponents = baseVersion.components(separatedBy: ".")
        guard versionComponents.count >= 3 else {
            return nil
        }
        let major = Int(versionComponents[0]) ?? 0
        let minor = Int(versionComponents[1]) ?? 0
        let patch = Int(versionComponents[2]) ?? 0

        return (major, minor, patch)
    }
}
