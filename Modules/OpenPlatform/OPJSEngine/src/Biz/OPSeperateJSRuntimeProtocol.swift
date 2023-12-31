//
//  OPSeperateJSRuntimeProtocol.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/6.
//
// 独立worker协议

import Foundation
import OPSDK
import OPFoundation

public protocol OPSeperateJSRuntimeProtocol: OPBaseJSRuntimeProtocol {
    var sourceWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? { get set }
    var rootWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? { get set }
    var authorization: BDPJSBridgeAuthorizationProtocol? { get set }
    // bridge 控制器
    var bridgeController: UIViewController? { get set }
    var uniqueID: OPAppUniqueID { get set  }
    // 终止worker
    func terminate()
}
