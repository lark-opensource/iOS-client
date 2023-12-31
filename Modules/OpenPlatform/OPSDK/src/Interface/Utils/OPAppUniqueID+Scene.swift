//
//  OPUniqueID+Scene.swift
//  OPSDK
//
//  Created by yinyuan on 2021/1/15.
//

import Foundation
import ECOInfra
import OPFoundation

extension OPAppUniqueID {
    
    private static var opWindowKey: Void?

    @objc public var window: UIWindow? {
        get {
            // 新容器直接从 containerContext 中取
            if let window = OPApplicationService.current.getContainer(uniuqeID: self)?.containerContext.window {
                return window
            }
            if let wWindow = objc_getAssociatedObject(self, &OPAppUniqueID.opWindowKey) as? WeakReference<UIWindow> {
                return wWindow.value
            }
            return nil
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &OPAppUniqueID.opWindowKey, WeakReference(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                objc_setAssociatedObject(self, &OPAppUniqueID.opWindowKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
}
