// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientOpenPlatformAppStrategyCode: OPMonitorCodeBase {

    /** 小程序检验权限接口请求成功 */
    public static let gadget_state_success = EPMClientOpenPlatformAppStrategyCode(code: 10000, level: OPMonitorLevelNormal, message: "gadget_state_success")

    /** 小程序检验权限接口请求失败 */
    public static let gadget_state_fail = EPMClientOpenPlatformAppStrategyCode(code: 10001, level: OPMonitorLevelError, message: "gadget_state_fail")

    /** 网页应用检验权限接口成功 */
    public static let h5_state_success = EPMClientOpenPlatformAppStrategyCode(code: 10002, level: OPMonitorLevelNormal, message: "h5_state_success")

    /** 网页应用检验权限接口失败 */
    public static let h5_state_fail = EPMClientOpenPlatformAppStrategyCode(code: 10003, level: OPMonitorLevelError, message: "h5_state_fail")

    /** 机器人校验权限接口请求成功 */
    public static let bot_state_success = EPMClientOpenPlatformAppStrategyCode(code: 10004, level: OPMonitorLevelNormal, message: "bot_state_success")

    /** 机器人校验权限接口请求失败 */
    public static let bot_state_fail = EPMClientOpenPlatformAppStrategyCode(code: 10005, level: OPMonitorLevelError, message: "bot_state_fail")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientOpenPlatformAppStrategyCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.app_strategy"
}