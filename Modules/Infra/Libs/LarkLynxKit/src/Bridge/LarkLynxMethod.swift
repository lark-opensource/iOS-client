//
//  LarkLynxMethod.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/2/21.
//

import Foundation
import LarkOpenAPIModel
import ECOProbe
import Lynx

public class LarkLynxBridgeContext {
    public var lynxContext: LynxContext?
    public var bizContext: LynxContainerContext?
    
    public init(lynxContext: LynxContext? = nil, bizContext: LynxContainerContext? = nil) {
        self.lynxContext = lynxContext
        self.bizContext = bizContext
    }
}


public protocol LarkLynxMethod {
    
    init()
    
    /// - Parameters:
    ///   - apiName: 接口名
    ///   - params: 入参
    ///   - context: context
    ///   - callback: 回调：成功时会带上具体返回数据，失败时会带上
    func handle(
        params: [AnyHashable: Any]?,
        context: LarkLynxBridgeContext,
        callback: @escaping ([AnyHashable: Any]?) -> Void
    )
    
    static func methodName() -> String
}

