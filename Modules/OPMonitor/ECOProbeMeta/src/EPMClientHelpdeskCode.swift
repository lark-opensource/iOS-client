// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientHelpdeskCode: OPMonitorCodeBase {

    /** 成功 */
    public static let success = EPMClientHelpdeskCode(code: 10000, level: OPMonitorLevelNormal, message: "success")

    /** 失败 */
    public static let fail = EPMClientHelpdeskCode(code: 10001, level: OPMonitorLevelError, message: "fail")

    /** 取消 */
    public static let cancel = EPMClientHelpdeskCode(code: 10002, level: OPMonitorLevelWarn, message: "cancel")

    /** 超时 */
    public static let timeout = EPMClientHelpdeskCode(code: 10003, level: OPMonitorLevelError, message: "timeout")

    /** 不合法的参数 */
    public static let invalid_params = EPMClientHelpdeskCode(code: 10004, level: OPMonitorLevelError, message: "invalid_params")

    /** 数据解析失败 */
    public static let parse_data_failed = EPMClientHelpdeskCode(code: 10005, level: OPMonitorLevelError, message: "parse_data_failed")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientHelpdeskCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.helpdesk"
}