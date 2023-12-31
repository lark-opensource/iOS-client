//
//  LongPicBackInterceptor.swift
//  SKBrowser
//
//  Created by huayufan on 2020/12/19.
//  

import SKCommon
import SKFoundation
import SKUIKit

protocol BackInterceptor {
    func disablePopGestureAndBackAction(hook closure: @escaping () -> Void)
    func restorePopGestureAndBackAction()
}

// 拦截导航栏返回点击和侧滑事件
final class LongPicBackInterceptor: BackInterceptor {
    private weak var navigator: BrowserNavigator?
    private var callback: (() -> Void)?
    // 保存导出长图片时导航栏返回按钮的事件
    private var backItemConfig: (target: Any, selector: Selector)?
    
    init(navigator: BrowserNavigator?) {
        self.navigator = navigator
    }
    
    func disablePopGestureAndBackAction(hook closure: @escaping () -> Void) {
        self.callback = closure
        interceptNaviBackEvent()
    }

    func restorePopGestureAndBackAction() {
        interceptNaviBackEvent(isRestore: true)
    }
    
}


extension LongPicBackInterceptor {
    
    /// 拦截导航栏返回点击和侧滑事件
    /// - Parameter isRestore: 恢复or拦截
    private func interceptNaviBackEvent(isRestore: Bool = false) {
        guard let baseViewController = navigator?.currentBrowserVC as? BaseViewController else {
           DocsLogger.error("currentBrowserVC convert fail")
           return
        }
        guard let item = baseViewController.navigationBar.leadingButtonBar.itemViews.first as? SKBarButton else {
            DocsLogger.error("navigationBar itemView convert fail")
            return
        }
        let allActionNames = item.actions(forTarget: baseViewController, forControlEvent: .touchUpInside)
        let backAction = #selector(BaseViewController.backBarButtonItemAction)
        // 控制侧滑事件
        baseViewController.naviPopGestureRecognizerEnabled = isRestore
        if isRestore {
            // 恢复返回事件
            if allActionNames == nil || allActionNames?.contains(backAction.description) == false,
               let backItemConfig = backItemConfig {
                 item.addTarget(backItemConfig.target, action: backItemConfig.selector, for: .touchUpInside)
                 self.backItemConfig = nil
            }
        } else {
            // 暂时移除返回事件&添加自定义事件
            if allActionNames?.contains(backAction.description) == true {
                item.removeTarget(baseViewController, action: backAction, for: .touchUpInside)
                backItemConfig = (target: baseViewController, selector: backAction)
                item.addTarget(self, action: #selector(hookBackAction), for: .touchUpInside)
            }
        }
        
    }
    
    @objc
    private func hookBackAction() {
        self.callback?()
    }
}
