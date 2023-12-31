//
//  LarkWebView+SyncRender.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/11/1.
//

import Foundation
import UIKit
import WebKit

extension UIScrollView {
    @objc func hook_setScrollEnabled(isScrollEnabled: Bool) {
        if let nativeView = op_sync_hookName_renderObj?.weakObject?.nativeView,
           nativeView.superview == self {
            self.hook_setScrollEnabled(isScrollEnabled: false)
        } else {
            self.hook_setScrollEnabled(isScrollEnabled: isScrollEnabled)
        }
    }
}

// MARK: 同层组件渲染同步方案升级接口实现
extension LarkWebView: LarkWebNativeSyncRenderInterface {
    public func insertComponentSync(view: UIView, atIndex index: String, existContainer: UIScrollView?, completion: ((Bool) -> Void)?) {
        // if object has been inserted. ignore it
        if let scrollview = fixRenderSyncObjs[index]?.scrollView, (!UIScrollView.op_enableSyncSuperviewCompareFix || existContainer == nil) {
            if view.superview == scrollview {
                scrollview.isScrollEnabled = false
                completion?(true)
                return
            }
        }
        
        let inputContainer: UIScrollView? = UIScrollView.op_enableSyncSuperviewCompareFix ? existContainer : nil
        guard let scrollView = inputContainer ?? self.op_getNativeComponentSyncManager()?.scrollViewPool.object(forKey: index as NSString) else {
            completion?(false)
            return
        }
        
        scrollView.isScrollEnabled = false
        let obj = NativeRenderObj()
        obj.scrollView = scrollView
        obj.nativeView = view
        obj.viewId = index
        obj.webview = self
        
        /// 设置UIScrollView的dealloc hook
        fixRenderSyncObjs[index] = obj
        
        scrollView.setContentOffset(CGPoint.zero, animated: false)
        if UIScrollView.op_enableSyncHookLayerName {
            // hook isScrollEnabled, 避免WebKit的设值, 使得同层组件变得可滚动
            scrollView.lkw_swizzleInstanceClassIsa(#selector(setter: UIScrollView.isScrollEnabled), withHookInstanceMethod: #selector(UIScrollView.hook_setScrollEnabled(isScrollEnabled:)))
            scrollView.op_sync_hookName_renderObj = LWCWeakObject(weakObject: obj)
        } else {
            scrollView.lkw_syncRenderObject = obj
        }
        var frame = view.frame
        frame.origin = CGPoint.zero
        frame.size = scrollView.frame.size
        view.frame = frame
        scrollView.addSubview(view)
        
        self.renderFixManager.hook(nativeView: view, superview: scrollView)
        
        // 添加size大小修改时的回调监听，将让native视图组件与scrollview大小保持一致。
        scrollView.lkwContentSizeObservation = scrollView.observe(\.contentSize,
                                                                  options: [.new, .old]) { [weak view, weak scrollView] _, change in
            if change.newValue != nil, let strongScrollView = scrollView {
                view?.frame = strongScrollView.bounds
            }
        }

        self.lkw_hook()
        completion?(true)
    }
    
    public func removeComponentSync(index: String) -> Bool {
        op_getNativeComponentSyncManager()?.popAPIContextPoolIfNeeded(renderId: index)
        if let obj = fixRenderSyncObjs.removeValue(forKey: index) {
            obj.nativeView?.removeFromSuperview()
            return true
        }
        return false
    }
}

// MARK: render
extension NativeRenderObj {
    
    @objc public func renderSyncAgain() {
        NativeSyncPriorityManager.shared.executeAllTaskIfNeeded()
        if let exist = NativeSyncPriorityManager.shared.isContainsTask(renderId: viewId), exist {
            self.prRenderSyncAgain()
        } else {
            DispatchQueue.main.async {
                self.prRenderSyncAgain()
            }
        }
    }
    
    private func prRenderSyncAgain() {
        if let nativeView = nativeView {
            webview?.insertComponentSync(view: nativeView, atIndex: viewId, existContainer: nil, completion: nil)
        }
    }
}
