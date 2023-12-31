//
//  NativeSyncRenderHook.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/10/19.
//

import ECOInfra
import ECOProbe
import LarkSetting
import LKCommonsLogging

public final class NativeComponentInsertSyncHook {
    private static let logger = Logger.oplog(NativeComponentInsertSyncHook.self, category: "NativeComponentInsertSyncHook")
    
    /// MARK: 新同层渲染框架开关（只执行一次）
    private static let hookUIScrollViewOnce: Void = {
        if (ECOSetting.gadgetNativeComponentSyncIOSSyncEnable()) {
            logger.info("try hook UIScrollView for insert native component synchronously")
            LarkWebView.op_enableSyncSetting = UIScrollView.enableScrollViewHook()
            UIScrollView.op_enableSyncHookLayerName = ECOSetting.nativeComponentSyncHookLayerNameEnable()
            UIScrollView.op_enableSyncSuperviewCompareFix = ECOSetting.nativeComponentSyncSuperviewCompareFixEnable()
        } else {
            logger.info("close hook UIScrollView for insert native component synchronously")
        }
    }()
    
    public static func tryHookUIScrollView() {
        NativeComponentInsertSyncHook.hookUIScrollViewOnce
    }
}

// MARK: hook for native render sync update
extension UIScrollView: SyncRenderDelegate {
    private static let logger = Logger.oplog(UIScrollView.self, category: "NativeComponentInsertSync")
    
    private struct OPLarkWebViewAssociateKeys {
        static var nativeComponentLarkWebViewKey: String = "NativeComponentLarkWebViewKey"
    }
    
    /// 开启同层渲染同步方案hook UIScrollView
    fileprivate static func enableScrollViewHook() -> Bool {
        /// MARK: 该方法内部不保护多次调用，如果多次调用，容易导致原方法与hook方法imp来回切换，
        /// 所以该方法只会在NativeComponentInsertSyncHook类中由静态属性初始化来保证只会被调用一次
        if UIScrollView.lkw_swizzleOriginInstanceMethod(#selector(UIScrollView.didMoveToSuperview), withHookInstanceMethod: #selector(UIScrollView.op_hook_didMoveToSuperview)) == false {
            Self.logger.error("UIScrollView enableScrollViewHook lkw_swizzleOriginInstanceMethod didMoveToSuperview failed")
            return false
        }
        return true
    }

    @objc func op_hook_didMoveToSuperview() {
        guard let scrollViewClass = NSClassFromString("WKChildScrollView") else {
            self.op_hook_didMoveToSuperview()
            return
        }

        if self.isKind(of: scrollViewClass) {
            if let superview = self.superview, viewIsWKView(view: superview) {
                if UIScrollView.op_enableSyncHookLayerName {
                    // hook layer
                    let layer = superview.layer
                    if layer.name != nil {
                        let _ = self.setupNativeComponentInsertSync()
                    } else {
                        layer.syncRenderDelegate = LWCWeakObject(weakObject: self)
                    }
                } else {
                    NativeSyncPriorityManager.shared.addTask {
                        return self.setupNativeComponentInsertSync()
                    }
                }
            }
        }
        self.op_hook_didMoveToSuperview()
    }
    
    func viewIsWKView(view: UIView) -> Bool {
        let wkViewProtocol = NSProtocolFromString("WKContentControlled")
        let wkViewClass: AnyClass? = NSClassFromString("WKCompositingView")
        
        if let wkViewClass = wkViewClass, view.isKind(of: wkViewClass) {
            return true
        } else if let wkViewProtocol = wkViewProtocol, view.conforms(to: wkViewProtocol) {
            return true
        } else {
            return false
        }
    }
    
    func setupNativeComponentInsertSync() -> String? {
        guard let superview = self.superview, let className = superview.layer.name else {
            /// WKCompositingView的layerName为空
            return nil
        }
        
        if let _ = className.range(of: "scroll") {
            /// WKChildScrollView为tt-scrollview渲染，找不到renderId字段
            return nil
        }
        
        guard let startRange = className.range(of: "renderId#") else {
            /// WKChildScrollView的layerName格式不匹配，找不到renderId字段
            return nil
        }
        
        /// WKCompositing.layer.name字段中包含renderID
        Self.logger.info("setupNativeComponentInsertSync layer name in WKCompositingView find renderId successfully!")
        
        /// 截取renderId
        let endIndex = className.index(startRange.upperBound, offsetBy: 6)
        let renderId: String = String(className[startRange.upperBound..<endIndex])
        let webview = findLarkWebView(view: self)
        guard let manager = webview?.op_getNativeComponentSyncManager() else {
            /// FG关闭，同步插入管理者不存在
            Self.logger.error("setupNativeComponentInsertSync sync manager does not exist")
            return nil
        }
        
        /// UIScrollView 已经生成（同步方案满足条件之一）
        self.op_renderID = renderId
        manager.pushScrollViewPool(self)
        return renderId
    }
    
    /// Hook UIScrollView的WillMoveToSuperview的方法，目的是为了在UIScrollView init的时机找到这个当前的LarkWebView
    func findLarkWebView(view: UIView) -> LarkWebView? {
        guard var superview = view.superview else {
            return nil
        }
        
        while (!viewIsLarkWebView(view: superview)) {
            if let tmpSuperview = superview.superview {
                superview = tmpSuperview
            } else {
                break;
            }
        }
        
        return superview as? LarkWebView
        
    }
    
    /// 检查当前view是否为LarkWebView
    private func viewIsLarkWebView(view: UIView) -> Bool {
        return view.isKind(of: LarkWebView.self)
    }
}

protocol SyncRenderDelegate: AnyObject {
    func setupNativeComponentInsertSync() -> String?
}

extension CALayer {
    
    @objc func op_hook_setName(_ name: String) {
        self.op_hook_setName(name)
        if let delegate = syncRenderDelegate?.weakObject {
            let _ = delegate.setupNativeComponentInsertSync()
            self.syncRenderDelegate = nil
        }
    }
    
    private static var kHookState: Void?
    var syncHookState: Bool {
        get {
            return objc_getAssociatedObject(self, &Self.kHookState) as? Bool ?? false
        }
        
        set {
            objc_setAssociatedObject(self,
                                     &Self.kHookState,
                                     newValue,
                                     .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    
    private static var kSyncRenderDelegate: Void?
    var syncRenderDelegate: LWCWeakObject<UIScrollView>? {
        get {
            return objc_getAssociatedObject(self, &Self.kSyncRenderDelegate) as? LWCWeakObject<UIScrollView>
        }
        
        set {
            if !syncHookState {
                syncHookState = true
                let _ = self.lkw_swizzleInstanceClassIsa(#selector(setter: CALayer.name), withHookInstanceMethod: #selector(CALayer.op_hook_setName(_:)))
                
            }
            objc_setAssociatedObject(self,
                                     &Self.kSyncRenderDelegate,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
