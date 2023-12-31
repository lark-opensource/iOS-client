//
//  OPBlockEngine.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/8/12.
//

import Foundation
import TTMicroApp
import OPSDK

// 迁移自OPBlockAPIAdapterPlugin，后期删除OPBlockAPIAdapterPlugin

public final class OPBlockEngine: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol {
    
    private weak var containerContext: OPContainerContext?
    
    /// 应用id
    public var appId: String {
        uniqueID.appID
    }
    
    /// 应用类型
    public let appType: BDPType = .block
    
    /// 引擎唯一标示符
    public let uniqueID: BDPUniqueID
    
    /// 开放平台 JSBridge 方法类型
    public let bridgeType: BDPJSBridgeMethodType = [.block]
    
    /// Block API权限校验器
    public var authorization: BDPJSBridgeAuthorizationProtocol?
    
    /// 调用 API 所在的 ViewController 环境
    public weak var bridgeController: UIViewController?
    
    /// 用于回调的 bridge 对象
    public weak var bridge: OPBridgeProtocol?
    
    public required init(containerContext: OPContainerContext) {
        self.containerContext = containerContext
        self.uniqueID = containerContext.uniqueID
        self.authorization = OPBlockAuthorization(authDataSource: OPBlockMetaWithAuth(name: "", icon: "", containerContext: containerContext), storage: OPBlockAuthStorageProvider())
        super.init()
    }
    //  本期API不包括主动执行JS，暂时空实现
    public func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        let msg = "block need api call js now, please write it"
        assertionFailure(msg)
        BDPLogError(tag: .cardApi, msg)
    }
    public func bdp_fireEventV2(_ event: String, data: [AnyHashable: Any]?) {
        do {
            try bridge?.sendEvent(eventName: event, params: data, callback: nil)
        } catch {
            // TODO: 异常处理
        }
    }
    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable: Any]?) {
        do {
            try bridge?.sendEvent(eventName: event, params: data, callback: nil)
        } catch {
            // TODO: 异常处理
        }
    }
}
