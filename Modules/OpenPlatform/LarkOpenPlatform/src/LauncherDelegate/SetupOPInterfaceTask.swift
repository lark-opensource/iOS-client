//
//  SetupOPInterfaceTask.swift
//  LarkOpenPlatform
//
//  Created by changrong on 2020/9/25.
//

import Foundation
import BootManager
import LarkContainer
import RunloopTools
import LarkOPInterface
import LKTracing
import LKCommonsLogging
import EEMicroAppSDK

class SetupOPInterfaceTask: FlowBootTask, Identifiable {// user:global
    static var identify = "SetupOPInterfaceTask"

    override var delayScope: Scope? { return .container }
    
    override var runOnlyOnce: Bool {
        return true
    }

    override var scope: Set<BizScope> { return [.openplatform, .docs] }

    /// monitor 上报能力
    private static var monitorReporter = MonitorServiceReporter()

    /// monitor 日志能力
    private static var monitorLogger = MonitorServiceLogger()

    override func execute(_ context: BootContext) {

        // OPLog 初始化,用于设定 OPLogProxy，以及构造正真的 logger
        // OPLogProxy 只是用于日志审查，并不会实际消费日志，需要再注入 logger 构造方法用于消费审查后的日志
        Logger.setupOPLog { (type, category) -> Log in
            return Logger.log(type, category: "OpenPlatform." + category)
        }

        /// OPTrace 全局初始化
        let config = OPTraceConfig(prefix: LKTracing.identifier) { (parent) -> String in
            return LKTracing.newSpan(traceId: parent)
        }
        OPTraceService.default().setup(config)

        /// OPMonitor 全局初始化
        OPMonitorService.setup(OPMonitorServiceConfig(reportProtocol: SetupOPInterfaceTask.monitorReporter, logProtocol: SetupOPInterfaceTask.monitorLogger))
    }
}
