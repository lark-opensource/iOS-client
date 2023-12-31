//
//  TabContainable+Ext.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/3.
//  


import LarkTab
import LarkContainer
import LarkQuickLaunchInterface

public enum AssociatedKey {
    static var shouldRedirectKey: UInt8 = 0
}

extension TabContainable {
    
    ///获取最外层的TabContainable，例如wiki会返回WikiContainerVC、版本会返回VersionContainerVC
    public var bottomMostTab: TabContainable {
        if let lastTab = self.parent as? TabContainable {
            return lastTab.bottomMostTab
        } else {
            return self
        }
    }
    
    /// "Wiki移动到Space/Space移动到Wiki"的文档在第一次打开有VC的跳转，需要标记起来用于后续判断是否需要加入主导航的最近列表，否则可能会被记录两次
    public var shouldRedirect: Bool {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKey.shouldRedirectKey) as? Bool ?? false
            return value
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.shouldRedirectKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
