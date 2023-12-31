//
//  SetupPerfMonitor.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/28.
//


//TODO: delete related to LarkPerf && CustomCPUMonitor
//import Foundation
//import BootManager
//import LarkPerf
//import LarkMonitor
//
//final class SetupPerfMonitor: FlowBootTask, Identifiable { // Global
//    static var identify = "SetupPerfMonitor"
//
//    override func execute(_ context: BootContext) {
//        AppMonitor.shared.startMonitor()
//        // lint:disable:next lark_storage_check
//        if let config = UserDefaults(suiteName: "lk_safe_mode")?.value(forKey: "lark_custom_exception_config") as? [String: Any] {
//            LarkMonitor.startCustomException(config)
//        }
//    }
//}
