//
//  GuideUITool.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/3.
//

import UIKit
import Foundation
public final class GuideUITool {

    // 展示气泡
    public static func displayBubble(hostProvider: UIViewController,
                                     bubbleType: BubbleType,
                                     customWindow: UIWindow? = nil,
                                     makeKey: Bool = true,
                                     viewTapHandler: GuideViewTapHandler? = nil,
                                     dismissHandler: (() -> Void)? = nil) {
        let handler = {
            hostProvider.guideUIManager = nil
            if let dismissHandler = dismissHandler {
                dismissHandler()
            }
        }
        hostProvider.guideUIManager = hostProvider.guideUIManager ?? GuideUIManager()
        hostProvider.guideUIManager?.displayBubble(bubbleType: bubbleType,
                                                   customWindow: customWindow,
                                                   makeKey: makeKey,
                                                   viewTapHandler: viewTapHandler,
                                                   dismissHandler: handler)
    }

    // 展示卡片
    public static func displayDialog(hostProvider: UIViewController,
                                     dialogConfig: DialogConfig,
                                     customWindow: UIWindow? = nil,
                                     makeKey: Bool = true,
                                     dismissHandler: (() -> Void)? = nil) {

        let handler = {
            hostProvider.guideUIManager = nil
            if let dismissHandler = dismissHandler {
                dismissHandler()
            }
        }
        hostProvider.guideUIManager = hostProvider.guideUIManager ?? GuideUIManager()
        hostProvider.guideUIManager?.displayDialog(dialogConfig: dialogConfig,
                                      customWindow: customWindow,
                                      makeKey: makeKey,
                                      dismissHandler: handler)
    }

    // 展示自定义视图
    public static func displayCustomView(hostProvider: UIViewController,
                                     customConfig: GuideCustomConfig,
                                     customWindow: UIWindow? = nil,
                                     makeKey: Bool = true,
                                     dismissHandler: (() -> Void)? = nil) {

        let handler = {
            hostProvider.guideUIManager = nil
            if let dismissHandler = dismissHandler {
                dismissHandler()
            }
        }
        hostProvider.guideUIManager = hostProvider.guideUIManager ?? GuideUIManager()
        hostProvider.guideUIManager?.displayCustomView(customConfig: customConfig,
                                      customWindow: customWindow,
                                      makeKey: makeKey,
                                      dismissHandler: handler)
    }
}

extension GuideUITool {
    // 关闭引导
    public static func closeGuideIfNeeded(hostProvider: UIViewController,
                                          customWindow: UIWindow? = nil) {
        hostProvider.guideUIManager = hostProvider.guideUIManager ?? GuideUIManager()
        hostProvider.guideUIManager?.closeGuideViewsIfNeeded(customWindow: customWindow)
    }
}

extension UIViewController {
    struct Static {
        static var guideUIToolKey = "GuideUIToolKey"
    }
    // 设置展示页面的组件，绑定生命周期
    var guideUIManager: GuideUIManager? {
        get {
            return objc_getAssociatedObject(self, &Static.guideUIToolKey) as? GuideUIManager
        }
        set {
            objc_setAssociatedObject(self, &Static.guideUIToolKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
