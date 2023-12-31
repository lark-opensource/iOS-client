//
//  NativeAppManagerInternalProtocol.swift
//  LarkOPInterface
//
//  Created by bytedance on 2022/9/27.
//

import Foundation
import NativeAppPublicKit

public protocol NativeAppManagerInternalProtocol {
    
    ///存储NativeApp的可见性状态
    var nativeAppGuideInfoDic: [String: NativeGuideInfo] { get }
    
    /**
     获取NativeApp的可见性
     */
    func getNativeAppGuideInfo()
    
    /**
     设置NativeAppManager
     */
    func setupNativeAppManager()
    
    
    func setupContainer()
}

