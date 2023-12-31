//
//  ShareMonitor.swift
//  LarkWebViewController
//
//  Created by Meng on 2021/1/15.
//

import Foundation
import LarkOPInterface

final class OPShareMonitorCodeH5: OPMonitorCode {
    /// 分享入口触发
    static let share_entry_start = OPShareMonitorCodeH5(code: 10_001, message: "share_entry_start")

    /// 分享上传图片成功
    static let share_upload_image_success = OPShareMonitorCodeH5(code: 10_003, message: "share_upload_image_success")

    /// 分享上传图片失败
    static let share_upload_image_failed = OPShareMonitorCodeH5(code: 10_004, level: OPMonitorLevelError, message: "share_upload_image_failed")

    /// 唤起分享容器
    static let share_container_start = OPShareMonitorCodeH5(code: 10_005, message: "share_container_start")

    /// 关闭分享容器
    static let share_container_close = OPShareMonitorCodeH5(code: 10_006, message: "share_container_close")

    /// 分享卡片成功
    static let share_card_success = OPShareMonitorCodeH5(code: 10_007, message: "share_card_success")

    /// 分享卡片失败
    static let share_card_failed = OPShareMonitorCodeH5(code: 10_008, level: OPMonitorLevelError, message: "share_card_failed")

    init(code: Int, level: OPMonitorLevel = OPMonitorLevelNormal, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }

    static let domain = "client.open_platform.share"
}
