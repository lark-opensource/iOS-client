//
//  NativeAppExtensionProtocol.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/8.
//

import Foundation

///abstract [简述]NativeApp中NativeApp要实现的基Protocol，定义NativeApp的通用能力
@objc
public protocol NativeAppExtensionProtocol: NSObjectProtocol {
    
    
    /**
     获取NativeApp的相关信息(appId)
     */
    @objc
    func getNativeAppId() -> String
    
}

