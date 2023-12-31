//
//  OPRunnerBridge.swift
//  EEMicroAppSDK
//
//  Created by kongkaikai on 2021/6/16.
//

import Foundation
import OPSDK
import LarkContainer

/// public to show this class in EEMicroAppSDK-umbrella
@objc public enum EMADiagnoseCommandRunnerGroup: Int {
    case exportFileSystemLog = 107
    case mockFgSetting
}

@objc public final class OPRunnerBridge: NSObject {

    @objc public static func runner(with command: EMADiagnoseCommandRunnerGroup) -> OPDiagnoseBaseRunner? {
        // TODOZJX
        let userResolver = OPUserScope.userResolver()
        switch command {
        /// DiagnoseCommand Runner分发逻辑
        case .exportFileSystemLog:
            return OPExportFileSystemLogRunner(resolver: userResolver, permission: .release)
        case .mockFgSetting:
            #if ALPHA
            return OPDebugMockFGSetting(resolver: userResolver, permission: .release)
            #else
            return nil
            #endif

        @unknown default:
            /// 比 getAllAliveApp 大的都是runner，未来如果有新的类型，可以添加新的 Range 判断
            if command.rawValue > 101 {
                assert(false, "New runner case.")
            }

            return nil
        }
    }
}
