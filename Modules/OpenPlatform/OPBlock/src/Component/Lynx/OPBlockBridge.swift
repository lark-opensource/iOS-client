//
//  OPBlockBridge.swift
//  OPSDK
//
//  Created by Limboy on 2020/11/11.
//

import Foundation
import Lynx
import ECOProbe
import OPSDK
import LKCommonsLogging

protocol OPBlockBridgeDelegate: AnyObject {
    func invoke(name: String, param: [AnyHashable: Any], callback: LynxCallbackBlock?)
}

// 向OPBlockBridge传入的参数类型
struct OPBlockBridgeData {
    let context: OPContainerContext
    weak var delegate: OPBlockBridgeDelegate?
}

@objcMembers
class OPBlockBridge: NSObject, LynxModule {

    weak var delegate: OPBlockBridgeDelegate?
    var containerContext: OPContainerContext?

    private var trace: BlockTrace? {
        containerContext?.blockTrace
    }

    required override init() {
        super.init()
    }

    /// bd_core.js 规定要使用这个名字
    static var name: String = "BDLynxModule"

    /// 设置查找规则，方便后续的动态派发
    static var methodLookup: [String : String] = [
        "invoke": NSStringFromSelector(#selector(invoke(name:param:callback:)))
    ]

    required init(param: Any) {
        let paramData = param as? OPBlockBridgeData
        delegate = paramData?.delegate
        containerContext = paramData?.context

        super.init()
        /// 想不到更好的不用强转的，设置 delegate 的方法了
        trace?.info("OPBlockBridge.init")
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
        trace?.info("OPBlockBridge.invoke name: \(String(describing: name ?? ""))")
        let param = param ?? [:]
        delegate?.invoke(name: name, param: param, callback: callback)
    }
}
