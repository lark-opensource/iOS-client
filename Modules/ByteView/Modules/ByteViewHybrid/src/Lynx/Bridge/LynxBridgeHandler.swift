//
// Created by maozhixiang.lip on 2022/10/19.
//

import Foundation
import BDXBridgeKit

typealias LynxBridgeParams = [AnyHashable: Any]
typealias LynxBridgeStatus = BDXBridgeStatusCode
typealias LynxBridgeCallback = (BDXBridgeStatusCode, LynxBridgeParams) -> Void

protocol LynxBridgeHandler {
    var name: String { get }
    func handle(param: LynxBridgeParams?, callback: LynxBridgeCallback)
}
