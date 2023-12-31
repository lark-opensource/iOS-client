//
//  AppCardErrorDefine.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/10.
//

import Foundation
import LarkOPInterface

private let cardBaseDomain = "client.open_platform.app_card"

@objcMembers
final class AppCardMonitorCodeInstall: OPMonitorCode {
    /// 卡片安装失败
    static public let install_failed = AppCardMonitorCodeInstall(code: 10000, level: OPMonitorLevelError, message: "install_failed")
    /// 卡片安装成功
    static public let install_success = AppCardMonitorCodeInstall(code: 10001, level: OPMonitorLevelNormal, message: "install_success")

    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: AppCardMonitorCodeInstall.domain, code: code, level: level, message: message)
    }
    static public let domain = cardBaseDomain + ".install"
}
