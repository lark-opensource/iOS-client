// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMClientOpenPlatformInfraFileSystemCode: OPMonitorCodeBase {

    /** 开放应用沙箱属性信息 */
    public static let open_app_sandbox_info = EPMClientOpenPlatformInfraFileSystemCode(code: 10001, level: OPMonitorLevelNormal, message: "open_app_sandbox_info")

    /** 开放应用 FileSystem primitive api */
    public static let open_app_filesystem_primitive_api = EPMClientOpenPlatformInfraFileSystemCode(code: 10002, level: OPMonitorLevelNormal, message: "open_app_filesystem_primitive_api")

    /** iOS BDPURLProtocol 不能从 UA 正常解析 uniqueId */
    public static let open_app_webview_ua_resolve_fail = EPMClientOpenPlatformInfraFileSystemCode(code: 10003, level: OPMonitorLevelNormal, message: "open_app_webview_ua_resolve_fail")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMClientOpenPlatformInfraFileSystemCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.infra.file_system"
}