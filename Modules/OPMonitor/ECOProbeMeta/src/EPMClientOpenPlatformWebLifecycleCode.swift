// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientOpenPlatformWebLifecycleCode: OPMonitorCodeBase {

    /** 网页心跳埋点 */
    public static let web_heartbeat = EPMClientOpenPlatformWebLifecycleCode(code: 10008, level: OPMonitorLevelNormal, message: "web_heartbeat")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientOpenPlatformWebLifecycleCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.web.lifecycle"
}