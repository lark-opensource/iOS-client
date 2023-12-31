//
//  LarkWebView+NativeComponent.swift
//  OPPlugin
//
//  Created by yi on 2021/8/24.
//
// 组件管理相关

import Foundation
import WebKit
import LarkWebViewContainer

extension LarkWebView {
    private struct OPWebViewAssociatedKeys {
        static var nativeComponentsKey = "NativeComponentsKey" // 组件管理模块key
        static var nativeComponentsConfigKey = "NativeComponentsConfigKey" // 组件管理模块配置key
        static var nativeComponentTypeManagerKey = "NativeComponentTypeManagerKey" // 组件类型管理key
        static var nativeComponentWKGestureFGKey = "NativeComponentWKGestureFGKey" // 同层组件手势冲突FG的key
        static var nativeComponentGestureFixKey = "NativeComponentGestureFixKey" // 同层组件手势问题修复Key
        static var nativeComponentGestureBlackListKey = "nativeComponentGestureBlackListKey" // 同层组件黑名单手势
        static var nativeComponentGestureConflictKey = "NativeComponentGestureConflictKey" // 同层组件手势冲突具体Key
    }


    // 获取组件管理模块
    public func op_nativeComponentManager() -> OpenNativeComponentManager {
        if let nativeComponents = op_nativeComponents {
            return nativeComponents
        }
        let manager = OpenNativeComponentManager()
        op_nativeComponents = manager
        op_fixGestureFG = LarkWebViewNativeComponentSettings.gesturesFix()
        op_blackListGes = LarkWebViewNativeComponentSettings.blackListGes()
        return manager
    }

    // 组件管理模块
    fileprivate var op_nativeComponents: OpenNativeComponentManager? {
        get {
            return objc_getAssociatedObject(self, &OPWebViewAssociatedKeys.nativeComponentsKey) as? OpenNativeComponentManager
        }

        set {
            objc_setAssociatedObject(self,
                &OPWebViewAssociatedKeys.nativeComponentsKey, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 注册native组件，只对传入webview实例生效
    public func op_registerNativeComponents(_ components: [OpenNativeBaseComponent.Type]) {
        if op_typeManager == nil {
            op_typeManager = OpenComponentTypeManager()
        }
        op_typeManager?.register(components: components)
    }

    // 组件类型管理器
    var op_typeManager: OpenComponentTypeManager? {
        get {
            return objc_getAssociatedObject(self, &OPWebViewAssociatedKeys.nativeComponentTypeManagerKey) as? OpenComponentTypeManager
        }

        set {
            objc_setAssociatedObject(self,
                &OPWebViewAssociatedKeys.nativeComponentTypeManagerKey, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}

/**
 WKContentView中的所有手势
"UIWebTouchEventsGestureRecognizer"
"_UITouchDurationObservingGestureRecognizer"
"_UIRelationshipGestureRecognizer"
"_UIContextualMenuGestureRecognizer"
"UITapAndAHalfRecognizer"
"WKTouchActionGestureRecognizer"
"UIVariableDelayLoupeGesture"
"WKSyntheticTapGestureRecognizer" // 不可被修改
"WKMouseGestureRecognizer"
"UITextTapRecognizer"
"WKHighlightLongPressGestureRecognizer"
"UITapGestureRecognizer"
"UISwipeGestureRecognizer"
"WKDeferringGestureRecognizer"
"UILongPressGestureRecognizer"
"_UISecondaryClickDriverGestureRecognizer"

 iPad独有的几个:
 UITextMultiTapRecognizer
 UITextLoupePanGestureRecognizer
 _UIPointerInteractionHoverGestureRecognizer
 _UIPointerInteractionPressGestureRecognizer
*/
public extension LarkWebView {
    /// hook方法
    @objc func lkwn_point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        updateNatieComponentViewsGestureResponde(point: point, event: event)
        return self.lkwn_point(inside: point, with: event)
    }

    /// 判断是否需要禁用WKContentView中的手势, 确保同层组件中自定义view的手势能够正确相应
    fileprivate func updateNatieComponentViewsGestureResponde(point: CGPoint, event: UIEvent?) {
        var arr = [UIView]()
        let manager = op_nativeComponentManager()
        // 获取所有需要响应自定义手势的view
        for nativeComponentWrapper in manager.componentMap.values {
            if let customViews = nativeComponentWrapper.nativeComponent.respondCustomGestureViews() {
                arr += customViews
            }
        }
        
        if op_fixGestureFG, arr.isEmpty {
            // 走恢复逻辑
            restoreFixGesturesIfNeeded()
            return
        }

        var enableWebView = true
        for disableView in arr {
            let convertPoint = self.convert(point, to: disableView)
            if disableView.point(inside: convertPoint, with: event) {
                // 只要手势落在需要响应自身手势的view上时, 就禁用WKContentView手势;
                enableWebView = false
                break
            }
        }
        
        if op_fixGestureFG {
            fixWebviewGesture(enableWebView)
            return
        }

        updateWebviewGesture(enableWebView)
    }

    /// 设置WKContentView中手势是否可用
    fileprivate func updateWebviewGesture(_ enable: Bool) {
        for view1 in self.scrollView.subviews {
            let name = NSStringFromClass(type(of: view1))
            if let gestures = view1.gestureRecognizers, name.hasPrefix("WK") {
                for g in gestures {
                    g.isEnabled = enable
                }
            }
        }
    }
}

// MARK: - Native Component Gestures Fix

fileprivate extension LarkWebView {
    
    struct NativeComponentGestureObj {
        var ges: UIGestureRecognizer
        let originState: Bool
    }
    
    /// 修复上述逻辑会影响LarkWebView所有手势状态的问题.
    func fixWebviewGesture(_ enable: Bool) {
        if enable {
            restoreFixGesturesIfNeeded()
        } else {
            disableGesturesIfNeeded()
        }
    }
    
    func disableGesturesIfNeeded() {
        guard op_forbiddenGestures.isEmpty else {
            return
        }
        for view1 in self.scrollView.subviews {
            let name = NSStringFromClass(type(of: view1))
            if let gestures = view1.gestureRecognizers, name.hasPrefix("WK") {
                for g in gestures where g.op_native_isKind(of: op_blackListGes) {
                    let obj = NativeComponentGestureObj(ges: g, originState: g.isEnabled)
                    op_forbiddenGestures.append(obj)
                    g.isEnabled = false
                }
            }
        }
    }
    
    func restoreFixGesturesIfNeeded() {
        if !op_forbiddenGestures.isEmpty {
            op_forbiddenGestures.forEach { forbiddenGesObj in
                forbiddenGesObj.ges.isEnabled = forbiddenGesObj.originState
            }
            op_forbiddenGestures.removeAll()
        }
    }
    
    // 同层手势修复FG
    var op_fixGestureFG: Bool {
        get {
            return objc_getAssociatedObject(self, &OPWebViewAssociatedKeys.nativeComponentGestureFixKey) as? Bool ?? false
        }

        set {
            objc_setAssociatedObject(self, &OPWebViewAssociatedKeys.nativeComponentGestureFixKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    // 同层黑名单手势
    var op_blackListGes: [String] {
        get {
            return objc_getAssociatedObject(self, &OPWebViewAssociatedKeys.nativeComponentGestureBlackListKey) as? [String] ?? [String]()
        }

        set {
            objc_setAssociatedObject(self,
                &OPWebViewAssociatedKeys.nativeComponentGestureBlackListKey, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var op_forbiddenGestures: [NativeComponentGestureObj] {
        get {
            if let forbiddenGestures = objc_getAssociatedObject(self, &OPWebViewAssociatedKeys.nativeComponentGestureConflictKey) as? [NativeComponentGestureObj] {
                return forbiddenGestures
            } else {
                let forbiddenGestures = [NativeComponentGestureObj]()
                objc_setAssociatedObject(self,
                    &OPWebViewAssociatedKeys.nativeComponentGestureConflictKey, forbiddenGestures,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return forbiddenGestures
            }
        }

        set {
            objc_setAssociatedObject(self,
                &OPWebViewAssociatedKeys.nativeComponentGestureConflictKey, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

fileprivate extension UIGestureRecognizer {
    func op_native_isKind(of classNames: [String]?) -> Bool {
        if let classNames = classNames {
            if classNames.isEmpty {
                return false
            }
            for clsName in classNames {
                let string = NSStringFromClass(type(of: self))
                if string == clsName {
                    return true
                }
            }
        }
        return false
    }
}
