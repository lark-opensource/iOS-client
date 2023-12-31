//
//  AppLink+NavigationFrom.swift
//  OPFoundation
//
//  Created by lilun.ios on 2021/4/2.
//

import Foundation
import LarkAppLinkSDK
import EENavigator
import ECOProbe
import LKCommonsLogging

extension AppLink {
    /// 返回applink的resource，如果不存在，寻找主window的顶层viewController
    public func navigationFrom() -> UIViewController? {
        if let applinkFromVC = self.fromControler {
            return applinkFromVC
        }
        if let windowTopVC = Navigator.shared.mainSceneWindow?.fromViewController { // Global
            /// 默认在开发模式下面打开assert
            #if DEBUG
                assert(false, "applink should have source viewcontroller, callstack \(Thread.callStackSymbols), url \(self.url)")
            #endif
            Logger.oplog(AppLink.self).warn("applink context from viewcontroller is nil")
            return windowTopVC
        }
        Logger.oplog(AppLink.self).error("can't find navigation from applink")
        return nil
    }
}
