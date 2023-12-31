//
//  VersionControlHelper.swift
//  LarkVersion
//
//  Created by chengzhipeng-bytedance on 2017/8/31.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkFoundation
import LarkModel
import LarkReleaseConfig
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer
import RustPB
import LarkAccountInterface

final class VersionControlHelper: UserResolverWrapper {
    private static var logger = Logger.log(VersionControlHelper.self, category: "LarkVersion.Version")

    @ScopedInjectedLazy private var configureAPI: ConfigurationAPI?
    @ScopedInjectedLazy private var client: SDKRustService?
    @ScopedInjectedLazy private var deviceService: DeviceService?
    private let currentChatterId: String
    private let currentTenantId: String
    var userResolver: UserResolver

    init(userResolver: UserResolver, currentChatterId: String, currentTenantId: String) {
        self.userResolver = userResolver
        self.currentChatterId = currentChatterId
        self.currentTenantId = currentTenantId
    }

    /// 检查新版本
    ///
    /// - Parameters:
    ///     - checkShowUpgrade: 是否检测Info.plist中的SHOW_UPGRADE值。True则检测，False则绕过
    ///     - source: 版本更新的ChannelName。默认值：Info.plist中配置的CHANNEL_NAME
    func getVersionInfo(checkShowUpgrade: Bool = true, source: String? = nil) -> Observable<RustPB.Basic_V1_GetNewVersionResponse> {
        guard let configureAPI = configureAPI else {
            VersionControlHelper.logger.error("version: configureAPI resolve failed")
            return .empty()
        }
        if checkShowUpgrade && !ReleaseConfig.isShowUpgrade {
            return .empty()
        }

        let sourceValue = source ?? ReleaseConfig.channelName.replacingOccurrences(of: " ", with: "").lowercased()
        VersionControlHelper.logger.info("get version info, version:\(LarkFoundation.Utils.appVersion), buildVersion:\(LarkFoundation.Utils.buildVersion), source:\(sourceValue)")

        return configureAPI.getNewVersion(
            version: versionForRequest(LarkFoundation.Utils.appVersion),
            os: "iOS",
            userID: currentChatterId,
            tenantID: currentTenantId,
            source: sourceValue,
            kaChannel: ReleaseConfig.isKA ? ReleaseConfig.releaseChannel  : nil
        )
    }

    func getVersionNote() -> Observable<RustPB.Basic_V1_VersionData> {
        guard let configureAPI = configureAPI else {
            VersionControlHelper.logger.error("version: configureAPI resolve failed")
            return .empty()
        }
        let version = versionForRequest(LarkFoundation.Utils.appVersion)
        let platform = Display.pad ? "iPadOS" : "iOS"
        return configureAPI.getVersionNote(version: version, platform: platform)
    }

    /// 格式化 version 并确定 source
    ///
    /// - Parameter version: appVersion
    /// - Returns: (version, source)
    fileprivate func format(_ version: String) -> String {
        let pattern = "\\d+\\.\\d+\\.\\d+(-(beta|alpha)?\\d+)?"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
            let result = regex.matches(version).first else {
                return version
        }

        let beta = "beta"
        let alpha = "alpha"

        if version.contains(beta) {
            return result.contains(beta) ? result : result+"-\(beta)1"
        } else if version.contains(alpha) {
            return result.contains(alpha) ? result : result+"-\(alpha)1"
        } else {
            return result
        }
    }
    
    fileprivate func versionForRequest(_ version: String) -> String {
        let omegaVersion = LarkFoundation.Utils.omegaVersion
        guard !omegaVersion.isEmpty else {
            return format(version)
        }
        return format(version) + "omega\(omegaVersion)"
    }
}
