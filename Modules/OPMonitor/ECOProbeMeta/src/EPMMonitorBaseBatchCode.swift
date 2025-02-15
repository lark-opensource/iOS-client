// DO NOT EDIT.
//
// Generated by the iOS generator for OPMonitorCode.
// Source:   

import Foundation

@objcMembers
public final class EPMMonitorBaseBatchCode: OPMonitorCodeBase {

    /** 批量上报 monitor */
    public static let batch_monitor = EPMMonitorBaseBatchCode(code: 10000, level: OPMonitorLevelNormal, message: "batch_monitor")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: EPMMonitorBaseBatchCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "monitor.base.batch"
}