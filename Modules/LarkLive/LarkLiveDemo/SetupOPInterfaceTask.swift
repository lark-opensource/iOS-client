//
//  SetupOPInterfaceTask.swift
//  LarkOpenPlatform
//
//  Created by changrong on 2020/9/25.
//

import Foundation
import BootManager
import LarkContainer
import LarkOPInterface

class SetupOPInterfaceTask: FlowBootTask, Identifiable {
    static var identify = "SetupOPInterfaceTask"

    override var scope: Set<BizScope> { return [.openplatform, .docs] }

    override func execute(_ context: BootContext) {
        /// OPTrace 全局初始化
        let config = OPTraceConfig(prefix: "1.0") { (parent) -> String in
            return "\(parent)-LarkLiveDemo"
        }
        OPTraceService.default().setup(config)

        /// OPMonitor 全局初始化
        OPMonitorService.setup(OPMonitorServiceConfig(reportProtocol: DemoOpMonitor.shared, logProtocol: DemoOpMonitor.shared))
    }
}

private class DemoOpMonitor: NSObject, OPMonitorReportProtocol, OPMonitorLogProtocol {
    static let shared = DemoOpMonitor()
    func report(withName name: String, metrics: [String: Any]?, categories: [String: Any]?, platform: OPMonitorReportPlatform) {
    }

    func log(with level: OPMonitorLogLevel, tag: String?, file: String?, function: String?, line: Int, content: String?) {
    }
}
