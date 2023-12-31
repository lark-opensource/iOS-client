//
//  LarkWebView+ComponentInsertSync.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/10/19.
//

import Foundation
import LKCommonsLogging
import ECOInfra
import WebKit

public extension LarkWebView {
    static var nativeComponentSyncManagerKey = "NativeComponentSyncManagerKey" // 同层组件同步暂存池管理对象
    
    private var op_nativeComponentSyncManager: OpenNativeComponentSyncManager? {
        get {
            return objc_getAssociatedObject(self, &Self.nativeComponentSyncManagerKey) as? OpenNativeComponentSyncManager
        }
        
        set {
            objc_setAssociatedObject(self,
                                     &Self.nativeComponentSyncManagerKey, newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 获取组件insert同步暂存池管理对象
    func op_getNativeComponentSyncManager() -> OpenNativeComponentSyncManager? {
        /// settings控制是否开启新同层渲染逻辑
        if LarkWebView.op_enableSyncSetting == true {
            if let nativeComponents = op_nativeComponentSyncManager {
                return nativeComponents
            }
            let manager = OpenNativeComponentSyncManager()
            op_nativeComponentSyncManager = manager
            return manager
        } else {
            return nil
        }
        
    }
}
