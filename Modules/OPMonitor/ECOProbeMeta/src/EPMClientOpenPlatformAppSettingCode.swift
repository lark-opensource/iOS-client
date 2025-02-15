// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientOpenPlatformAppSettingCode: OPMonitorCodeBase {

    /** 拉取关于页信息成功 */
    public static let pull_about_info_success = EPMClientOpenPlatformAppSettingCode(code: 10000, level: OPMonitorLevelNormal, message: "pull_about_info_success")

    /** 拉取关于页信息失败 */
    public static let pull_about_info_fail = EPMClientOpenPlatformAppSettingCode(code: 10001, level: OPMonitorLevelError, message: "pull_about_info_fail")

    /** 关于页拉取应用权限成功 */
    public static let pull_authorize_data_info_success = EPMClientOpenPlatformAppSettingCode(code: 10002, level: OPMonitorLevelNormal, message: "pull_authorize_data_info_success")

    /** 关于页拉取应用权限失败 */
    public static let pull_authorize_data_info_fail = EPMClientOpenPlatformAppSettingCode(code: 10003, level: OPMonitorLevelError, message: "pull_authorize_data_info_fail")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientOpenPlatformAppSettingCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.app_setting"
}