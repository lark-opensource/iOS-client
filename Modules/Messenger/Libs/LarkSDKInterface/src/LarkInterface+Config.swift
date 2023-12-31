//
//  LarkInterface+Config.swift
//  LarkInterface
//
//  Created by qihongye on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import LarkRustClient
import RustPB

public extension RustPB.Basic_V1_AppConfig {
    final class ResourceKey {
        /// 关于Lark -> 特色功能
        public static let helpKeyFeature = "help-key-feature"
        /// 关于Lark -> 最佳实践
        public static let helpBestPractice = "help-best-practice"
        /// 关于Lark -> 用户协议
        public static let helpUserAgreement = "help-user-agreement"
        /// 关于Lark -> 隐私政策
        public static let helpPrivatePolicy = "help-private-policy"
        /// 关于Lark -> 更新日志
        public static let helpReleaseLog = "help-release-log"
        /// 关于Lark -> 安全白皮书
        public static let securityWhitePaper = "security-white-paper"
        /// 关于Lark -> 应用权限说明
        public static let applicationPermissionDescription = "application-permission-description"
        /// 关于Lark -> 第三方SDK列表
        public static let thirdPartySdk = "third-party-sdk"
        /// 设置页首页 -> 个人信息收集清单
        public static let privacyChecklist = "privacy-checklist"
        /// 关于Lark -> 个人信息下载
        public static let personalInfoDownload = "personal-download"
        /// 关于Lark -> 开源组件声明
        public static let openSourceNotice = "open-source-notice-ios"
        /// 电话查询限制 -> 详情
        public static let helpAboutTelQueryLimit = "help-about-telephone-tel-query-limit"
        /// 钱包 -> 帮助
        public static let helpAboutHongbao = "help-about-hongbao"
    }
}

public protocol UserAppConfig {
    var appConfig: RustPB.Basic_V1_AppConfig? { get }

    var appConfigSignal: Observable<RustPB.Basic_V1_AppConfig> { get }

    func fetchAppConfigIfNeeded()

    func resourceAddrWithLanguage(key: String) -> String?
}
