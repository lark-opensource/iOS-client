//
//  PhotoAuthorityFixer.swift
//  LarkAssetsBrowser
//
//  Created by Hayden on 21/8/2023.
//

import Foundation
import LarkSetting

struct PhotoAuthorityFixer {

    /// 判断 iOS17 的相册权限 bug 是否已修复
    /// - NOTE: 背景：https://bytedance.feishu.cn/docx/IiStdYAWMoVGV1xWu2ucoDEanzh?theme=FOLLOW_SYSTEM&contentTheme=DARK
    /// - NOTE: 确认 iOS17 在后续版本修复了权限 bug 以后，及时更新 Setting 中的配置
    static let isIOS17PermissionBugFixed: Bool = {

        guard #available(iOS 17, *) else {
            // iOS17 以下没有该 bug，所以此处返回 true
            return true
        }

        // 获取 Setting 中配置的 bug 已修复的系统版本
        guard let config = try? SettingManager.shared.setting(with: "photos_permission_config"),
           let fixedVersion = config["permission_bug_fixed_version"] as? String else {
            // 如果启动后立即打开相册，此时没拉到 Setting，此时当做未修复来处理
            return false
        }

        // 如果当前系统版本 >= 已修复版本，则确认此 bug 已修复
        let systemVersion = UIDevice.current.systemVersion
        switch compareVersions(systemVersion, fixedVersion) {
        case .orderedAscending:     return false
        case .orderedSame:          return true
        case .orderedDescending:    return true
        }
    }()

    /// 比较两个符合 Semantic Versioning 规则的字符串类型版本号
    /// - NOTE: 历史代码中有很多转换成 Float 直接比较的，会有 badcase：`6.10 < 6.2`（不过 iOS 系统中很难发生，iOS 的中间版本很少出到过 10）
    static func compareVersions(_ leftVersion: String, _ rightVersion: String) -> ComparisonResult {
        // Semantic Versioning 系统中，版本号的分隔符
        let versionDelimiter = "."
        // 使用分隔符拆分版本号
        var leftVersionComponents = leftVersion.components(separatedBy: versionDelimiter)
        var rightVersionComponents = rightVersion.components(separatedBy: versionDelimiter)
        // 比较版本号是否位数一致
        let zeroDiff = leftVersionComponents.count - rightVersionComponents.count
        if zeroDiff == 0 {
            // 如果位数一致，直接使用 .numeric 比较
            return leftVersion.compare(rightVersion, options: .numeric)
        } else {
            // 如果位数不一致，用 "0" 向尾部补齐版本号后，再比较
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                rightVersionComponents.append(contentsOf: zeros)
            } else {
                leftVersionComponents.append(contentsOf: zeros)
            }
            return leftVersionComponents.joined(separator: versionDelimiter)
                .compare(rightVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}
