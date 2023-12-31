//
//  OPJSRuntimeAPIDispatchModuleProtocol.swift
//  OPJSEngine
//
//  Created by yi on 2021/12/25.
//
// api分发 module，用于分发从js到native的消息
import Foundation
import OPSDK
import OPFoundation

@objc
public protocol OPJSRuntimeAPIDispatchModuleProtocol: GeneralJSRuntimeModuleProtocol {
    var rootWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? { get set }
    var workerName: String { get set }
    func handleInvokeInterruption(stop: Bool)
    func invoke(event: String, param: [AnyHashable: Any]?, callbackID: String?, extra: [AnyHashable: Any]?, isNewBridge: Bool) -> Any?
    func call(event: String, param: [AnyHashable: Any]?, callbackID: NSNumber?) -> NSDictionary?
    func enableForegroundAPIDispatchFix() -> Bool
}
