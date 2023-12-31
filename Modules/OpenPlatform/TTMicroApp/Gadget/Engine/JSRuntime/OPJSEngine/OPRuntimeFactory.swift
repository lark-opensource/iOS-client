//
//  OPRuntimeFactory.swift
//  TTMicroApp
//
//  Created by yi on 2021/11/30.
//

import Foundation
import OPJSEngine
import LKCommonsLogging
import OPFoundation

@objcMembers
public final class OPRuntimeFactory: NSObject {
    public static let shared = OPRuntimeFactory()
    static let logger = Logger.log(OPRuntimeFactory.self, category: "OPJSEngine")

    public func debugMicroAppRuntime(address: String, coreCompleteBlk: BDPJSRuntimeCoreCompleteBlock?) -> OPMicroAppJSRuntimeProtocol {
        return OPMicroAppJSRuntime(address: address, completeBlk: {
            coreCompleteBlk?()
        }, runtimeType:.jscore) as OPMicroAppJSRuntimeProtocol
    }

    public func microAppRuntime(coreCompleteBlk: BDPJSRuntimeCoreCompleteBlock?) -> OPMicroAppJSRuntimeProtocol {
        return microAppRuntime(coreCompleteBlk: coreCompleteBlk, appType: .gadget)
    }

    public func microAppRuntime(coreCompleteBlk: BDPJSRuntimeCoreCompleteBlock?, appType: BDPType) -> OPMicroAppJSRuntimeProtocol {
        return microAppRuntime(coreCompleteBlk: coreCompleteBlk, appType: appType, runtimeType: runtimeFgType())
    }
    public func microAppRuntime(coreCompleteBlk: BDPJSRuntimeCoreCompleteBlock?, appType: BDPType, runtimeType: OPRuntimeType) -> OPMicroAppJSRuntimeProtocol {
        var workerType = runtimeType
        if runtimeType == .unknown {
            workerType = runtimeFgType()
        }
        Self.logger.info("microAppRuntime init, js_engine_type\(workerType.rawValue)")
        return OPMicroAppJSRuntime(coreCompleteBlk: coreCompleteBlk, with: appType, runtimeType: workerType) as OPMicroAppJSRuntimeProtocol
    }

    func seperateJSRuntime(sourceWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol), data: [AnyHashable: Any] = [:], interpreters: OpenJSWorkerInterpreters) -> OPSeperateJSRuntimeProtocol {
        let jsRuntimeFg = sourceWorker is OPMicroAppJSRuntime
        registerService()
        Self.logger.info("microAppRuntime init, new arch open status\(jsRuntimeFg)")
        if !jsRuntimeFg {
            return OpenJSWorker(sourceWorker: sourceWorker, data: data, interpreters: interpreters) as OPSeperateJSRuntimeProtocol
        }
        return OPSeperateJSRuntime(sourceWorker: sourceWorker, data: data, interpreters: interpreters) as OPSeperateJSRuntimeProtocol
    }

    func runtimeFgType() -> OPRuntimeType {
        registerService()
        return GeneralJSRuntimeTypeFg.shared.runtimeType
    }

    public func registerService() {
        if OPJSEngineService.shared.utils == nil {
            OPJSEngineService.shared.utils = OPJSEngineUtilsService()
        }
        if OPJSEngineService.shared.monitor == nil {
            OPJSEngineService.shared.monitor = OPJSEngineMonitorService()
        }
    }
}
