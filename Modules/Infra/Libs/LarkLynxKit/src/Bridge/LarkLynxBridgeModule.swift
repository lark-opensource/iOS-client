//
//  LarkLynxBridgeModule.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/10/27.
//

import Foundation
import Lynx
import OPSDK
import LKCommonsLogging

@objcMembers
class LarkLynxBridgeModule: NSObject, LynxContextModule {
    
    static let logger = Logger.oplog(LarkLynxBridgeModule.self, category: "CommonLynxContainer")
    private var bridgeMethodDispatcher: LarkLynxBridgeMethodProtocol?
    private var tagForBridgeMethodGroup: String?
    private var lynxContext: LynxContext?
    private var bizContext: LynxContainerContext?
    static var name: String = "BDLynxModule"
    
    static var methodLookup: [String : String] = [
        "invoke": NSStringFromSelector(#selector(invoke(name:param:callback:)))
    ]
    
    required init(lynxContext context: LynxContext) {
        self.lynxContext = context
    }
    
    required init(lynxContext context: LynxContext, withParam param: Any) {
        let paramData = param as? LarkLynxBridgeData
        self.bridgeMethodDispatcher = paramData?.bridgeDispatcher
        self.bizContext = paramData?.context
        self.lynxContext = context
        self.tagForBridgeMethodGroup = paramData?.tagForBridgeMethodGroup
    }
    
    required override init() {
        super.init()
    }

    required init(param: Any) {
        let paramData = param as? LarkLynxBridgeData
        self.bridgeMethodDispatcher = paramData?.bridgeDispatcher
        self.bizContext = paramData?.context
        self.tagForBridgeMethodGroup = paramData?.tagForBridgeMethodGroup
        super.init()
    }

    
    /// 收到js调用（Lynx通过runtime调用invoke方法，需要加上dynamic进行修饰让这个方法支持动态派发）
    /// - Parameters:
    ///   - name: js方法名
    ///   - param: 参数
    ///   - callback: 回调
    @objc dynamic func invoke(
        name: String!,
        param: [AnyHashable : Any]!,
        callback: LynxCallbackBlock?
    ) {
        Self.logger.info("LarkLynxBridgeModule: invoke api:\(String(describing: name)), Dispatcher is nil: \(bridgeMethodDispatcher.isNil)")
        if let bridgeMethodDispatcher = self.bridgeMethodDispatcher {
            bridgeMethodDispatcher.invoke(apiName: name, params: param, lynxContext: self.lynxContext, bizContext: self.bizContext, callback: callback)
        } else {
            LarkLynxBridgeMethodManager.shared.asyncCall(tag: self.tagForBridgeMethodGroup ?? "", apiName: name, params: param, context: LarkLynxBridgeContext(lynxContext: self.lynxContext, bizContext: self.bizContext)) { data in
                callback?(data as Any)
            }
        }
    }
}
