//
//  NativeSyncRenderProperties.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/11/1.
//

import Foundation

extension LarkWebView {
    private struct OPWebViewSyncAssociatedKeys {
        static var nativeComponentFixSyncRenderObjsKey = "NativeComponentFixSyncRenderObjsKey"
        static var nativeComponentSyncSettingsEnableKey = "NativeComponentSyncSettingEnableKey"
    }
    
    /// 新同层渲染方案中，存放已经渲染成功组件的NativeRenderObj信息的表对象
    public var fixRenderSyncObjs: [String: NativeRenderObj] {
        get {
            guard let objsMap = objc_getAssociatedObject(self, &OPWebViewSyncAssociatedKeys.nativeComponentFixSyncRenderObjsKey) as? [String: NativeRenderObj] else {
                let objsTmpMap: [String: NativeRenderObj] = [:]
                objc_setAssociatedObject(self, &OPWebViewSyncAssociatedKeys.nativeComponentFixSyncRenderObjsKey, objsTmpMap, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return objsTmpMap
            }
            return objsMap
        }
        set {
            objc_setAssociatedObject(self, &OPWebViewSyncAssociatedKeys.nativeComponentFixSyncRenderObjsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public static var op_enableSyncSetting: Bool? {
        get {
            return objc_getAssociatedObject(self, &OPWebViewSyncAssociatedKeys.nativeComponentSyncSettingsEnableKey) as? Bool
        }
        
        set {
            objc_setAssociatedObject(self, &OPWebViewSyncAssociatedKeys.nativeComponentSyncSettingsEnableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIScrollView {
    private static var nativeComponentSyncHookLayerName: Void?
    public static var op_enableSyncHookLayerName: Bool {
        get {
            return objc_getAssociatedObject(self, &nativeComponentSyncHookLayerName) as? Bool ?? false
        }
        
        set {
            objc_setAssociatedObject(self, &nativeComponentSyncHookLayerName, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private static var nativeComponentSyncSuperviewCompareFix: Void?
    public static var op_enableSyncSuperviewCompareFix: Bool {
        get {
            return objc_getAssociatedObject(self, &nativeComponentSyncSuperviewCompareFix) as? Bool ?? false
        }
        
        set {
            objc_setAssociatedObject(self, &nativeComponentSyncSuperviewCompareFix, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


final class LWCWeakObject<T: AnyObject> {
    weak var weakObject: T?
    init(weakObject: T?) {
        self.weakObject = weakObject
    }
}

extension UIScrollView {
    private struct OPScrollViewSyncAssociatedKeys {
        static var nativeComponentSyncRenderIDKey = "NativeComponentSyncRenderIDKey"
        static var syncRenderObjKey = "syncRenderObjKey"
    }
    
    /// 新同层渲染方案中，WKChildScrollView关联的renderID信息
    var op_renderID: String? {
        get {
            return objc_getAssociatedObject(self, &OPScrollViewSyncAssociatedKeys.nativeComponentSyncRenderIDKey) as? String
        }

        set {
            objc_setAssociatedObject(self,
                &OPScrollViewSyncAssociatedKeys.nativeComponentSyncRenderIDKey, newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var op_sync_hookName_renderObj: LWCWeakObject<NativeRenderObj>? {
        get {
            return objc_getAssociatedObject(self, &OPScrollViewSyncAssociatedKeys.syncRenderObjKey) as? LWCWeakObject<NativeRenderObj>
        }

        set {
            objc_setAssociatedObject(self,
                                     &OPScrollViewSyncAssociatedKeys.syncRenderObjKey, 
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
