//
//  CardEngine.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/8.
//

import Foundation

/// 卡片JSBridge引擎
@objcMembers
public final class CardEngine: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol {

    /// 引擎唯一标示符
    public var uniqueID: BDPUniqueID

    /// 开放平台 JSBridge 方法类型
    public var bridgeType: BDPJSBridgeMethodType = [.card]

    /// 卡片API权限校验器
    public var authorization: BDPJSBridgeAuthorizationProtocol? = CardAuthorization()

    //  TODO：目前卡片无这个环境，暂时设置UIViewController()
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
