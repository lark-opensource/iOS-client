//
//  OpenOverlayComponentManager.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/9.
//
// 非同层组件能力实现类

import Foundation
import LKCommonsLogging
import ECOProbe

final class OpenOverlayComponentManager: NSObject {
    
    static private let logger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "LarkWebviewNativeComponent")

    // 管理视图实例
    private var views: NSMapTable<NSString, UIView> = NSMapTable(keyOptions: [.copyIn], valueOptions: [.weakMemory], capacity: 10)

    // 插入一个组件
    func insertComponentView(view: UIView, container: UIView, stringID: String) -> Bool {
        if stringID.isEmpty {
            Self.logger.error("OverlayComponentManager, insertComponentView fail, stringID is empty")
            return false
        }
        if (views.object(forKey: stringID as NSString) != nil) {
            Self.logger.warn("OverlayComponentManager, insertComponentView fail, stringID exist")
            return false
        }
        container.addSubview(view)
        views.setObject(view, forKey: stringID as NSString)

        return true
    }

    // 移除一个组件
    func removeComponentView(stringID: String) -> Bool {
        if stringID.isEmpty {
            Self.logger.error("OverlayComponentManager, removeComponentView fail, stringID is empty")
            return false
        }
        if let view = findComponentView(stringID: stringID) {
            view.resignFirstResponder()
            view.removeFromSuperview()
        } else {
            Self.logger.warn("OverlayComponentManager, removeComponentView, view already removed")
        }
        views.removeObject(forKey: stringID as NSString)
        return true
    }

    func findComponentView(stringID: String) -> UIView? {
        if stringID.isEmpty {
            Self.logger.error("OverlayComponentManager, findComponentView fail, stringID is empty")
            return nil
        }
        return views.object(forKey: stringID as NSString)
    }
}
