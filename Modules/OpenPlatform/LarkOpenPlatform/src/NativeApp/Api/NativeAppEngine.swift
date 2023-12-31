//
//  NativeAppEngine.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/5/26.
//

import Foundation
import OPJSEngine
import TTMicroApp


@objcMembers
public class NativeAppEngine: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol {

    /// 引擎唯一标示符
    public var uniqueID: BDPUniqueID

    /// 开放平台 JSBridge 方法类型
    public var bridgeType: BDPJSBridgeMethodType = [.card]

    /// NativeApp API权限校验器
    public var authorization: BDPJSBridgeAuthorizationProtocol? = NativeAppAuthorization()

    /// 调用 API 所在的 ViewController 环境
    public var bridgeController: UIViewController? = UIViewController()

    init(uniqueID: BDPUniqueID) {
        self.uniqueID = uniqueID
        super.init()
    }
    //  本期API不包括主动执行JS，暂时空实现
    public func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        let msg = "card need api call js now, please write it"
        assertionFailure(msg)
        BDPLogError(tag: .cardApi, msg)
    }
    public func bdp_fireEventV2(_ event: String, data: [AnyHashable : Any]?) {
        let msg = "card need api call js now, please write it"
        assertionFailure(msg)
        BDPLogError(tag: .cardApi, msg)
    }
    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable : Any]?) {
        let msg = "card need api call js now, please write it"
        assertionFailure(msg)
        BDPLogError(tag: .cardApi, msg)
    }
}
