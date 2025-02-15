// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientOpenPlatformWebLaunchCode: OPMonitorCodeBase {

    /** H5 App 启动异常 */
    public static let load_error = EPMClientOpenPlatformWebLaunchCode(code: 10000, level: OPMonitorLevelError, message: "load_error")

    /** H5 App 启动正常 */
    public static let load_success = EPMClientOpenPlatformWebLaunchCode(code: 10002, level: OPMonitorLevelNormal, message: "load_success")

    /** appid meta&#38;pkg获取开始 */
    public static let meta_pkg_load_start = EPMClientOpenPlatformWebLaunchCode(code: 10004, level: OPMonitorLevelNormal, message: "meta_pkg_load_start")

    /** appid meta&#38;pkg获取结束 */
    public static let meta_pkg_load_finish = EPMClientOpenPlatformWebLaunchCode(code: 10005, level: OPMonitorLevelNormal, message: "meta_pkg_load_finish")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientOpenPlatformWebLaunchCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.web.launch"
}