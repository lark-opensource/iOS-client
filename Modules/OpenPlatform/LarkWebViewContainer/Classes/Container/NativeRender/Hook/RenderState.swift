//
//  RenderState.swift
//  LarkWebViewContainer
//
//  Created by baojianjun on 2022/7/21.
//

import Foundation
import LarkSetting
import LKCommonsLogging

/// render object info
@objcMembers
public final class RenderState: NSObject {
    
    // MARK: render
    weak var renderDelegate: LKNativeRenderDelegate?
    public var superviewWillBeRemoved = false
}


enum FeatureGatingKey: String {
    case domChangeFocusFix = "gadget.native_component.dom_change_focus_fix"
}

@objc
public final class RenderFixManager: NSObject {
    
    static let logger = Logger.oplog(LarkWebView.self, category: "NativeComponentFG")
    
    public override init() {
        self.op_nativeComponentDOMChangeFocusFixFG = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.domChangeFocusFix.rawValue))// user:global
        Self.logger.info("FG \(FeatureGatingKey.domChangeFocusFix.rawValue): \(self.op_nativeComponentDOMChangeFocusFixFG)")
        super.init()
    }
    
    // gadget.native_component.dom_change_focus_fix
    private var op_nativeComponentDOMChangeFocusFixFG: Bool
    
    /// hook 遵循WKContentControlled协议的view, 或者 isKindOfClass WKCompositingView的view。
    @objc
    public func hook(nativeView: UIView?, superview: UIView?) {
        
        guard self.op_nativeComponentDOMChangeFocusFixFG else { return }
        guard let nativeView = nativeView, let superview = superview else { return }
        
        let renderState = RenderState()
        if let nativeView = nativeView as? LKNativeRenderDelegate {
            nativeView.renderState = renderState
        }
        
        var tmpSuperView: UIView? = superview
        while viewIsWKView(view: tmpSuperView) {
            tmpSuperView?.lkw_swizzleInstanceClassIsa(#selector(UIView.removeFromSuperview), withHookInstanceMethod: #selector(UIView.hook_removeFromSuperview))
            tmpSuperView?.addNativeRenderState(renderState)
            tmpSuperView = tmpSuperView?.superview
        }
    }
    
    private func viewIsWKView(view: UIView?) -> Bool {
        guard let view = view else { return false }
        let wkViewProtocol = NSProtocolFromString("WKContentControlled")
        let wkView = NSClassFromString("WKCompositingView")
        if let wkView = wkView, view.isKind(of: wkView) {
            return true
        } else if let wkViewProtocol = wkViewProtocol, view.conforms(to: wkViewProtocol) {
            return true
        } else {
            return false
        }
    }
}
