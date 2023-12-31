//
//  OPLynxBridgeMethodProtocol.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/4.
//

import Foundation
import Lynx

///abstract [简述]Lynx通用容器中JSBridge，Lynx调用端上的能力
public protocol LarkLynxBridgeMethodProtocol {
    
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(
        apiName: String!,
        params: [AnyHashable : Any]!,
        lynxContext: LynxContext?,
        bizContext: LynxContainerContext?,
        callback: LynxCallbackBlock?
    )
    
}
