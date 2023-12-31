import Foundation
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignDialog
import UniverseDesignToast
import UIKit
import ECOInfra

/**
 * 由于 UD基建 未能及时提供相关能力对 OC 的支持
 * 这里提供一些临时的OC上的解决方案，待 UD基建 对 OC 支持后删除本文件
 * ⚠️⚠️本文件是临时方案，不保证适用于任意场景，只对有限经过测试的场景支持⚠️⚠️
 */

extension UIColor {
    
    @available(iOS 13.0, *)
    private static var op_lightTrait = UITraitCollection(userInterfaceStyle: .light)
    @available(iOS 13.0, *)
    private static var op_darkTrait = UITraitCollection(userInterfaceStyle: .dark)
    
    /// Return a non-dynamic color (always in light mode) from input.
    @objc
    public var op_nonDynamic: UIColor {
        return op_alwaysLight
    }

    /// Return a non-dynamic always in light mode.
    @objc
    public var op_alwaysLight: UIColor {
        if #available(iOS 13.0, *) {
            return self.resolvedColor(with: UIColor.op_lightTrait)
        } else {
            return self
        }
    }

    /// Return a non-dynamic always in dark mode.
    @objc
    public var op_alwaysDark: UIColor {
        if #available(iOS 13.0, *) {
            return self.resolvedColor(with: UIColor.op_darkTrait)
        } else {
            return self
        }
    }
    
    @objc
    public static func op_dynamicColor(light: UIColor?, dark: UIColor?) -> UIColor? {
        if let dark = dark, let light = light {
            return UIColor.dynamic(light: light, dark: dark)
        }
        return light
    }
    
}

extension UIImage {
    
    @objc
    public static func op_dynamicImage(light: UIImage?, dark: UIImage?) -> UIImage? {
        if let dark = dark, let light = light {
            return UIImage.dynamic(light: light, dark: dark)
        }
        return light
    }
}

private class OPUDTraitObserver: UIView {
    
    private lazy var callbackMap: [String: OPDynamicValueSetter] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func registerCallback(_ callback: @escaping OPDynamicValueSetter,
                          forKey key: String) {
        callbackMap[key] = callback
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                for callback in callbackMap.values {
                    DispatchQueue.main.async {
                        callback(self.traitCollection)
                    }
                }
            }
        }
    }
}

public typealias OPDynamicValueSetter = (UITraitCollection) -> Void

extension UIView {

    private struct OPAssociatedKeys {
        static var traitObserverKey = "OPUDTraitObserverKey"
    }

    private var opTraitObserver: OPUDTraitObserver? {
        get {
            guard #available(iOS 13.0, *) else { return nil }
            return objc_getAssociatedObject(
                self, &OPAssociatedKeys.traitObserverKey
            ) as? OPUDTraitObserver
        }
        set {
            guard #available(iOS 13.0, *) else { return }
            guard newValue != opTraitObserver else { return }
            let oldTraitObserver = opTraitObserver
            oldTraitObserver?.removeFromSuperview()
            if let newTraitObserver = newValue {
                newTraitObserver.isHidden = true
                insertSubview(newTraitObserver, at: 0)
                objc_setAssociatedObject(
                    self,
                    &OPAssociatedKeys.traitObserverKey,
                    newTraitObserver,
                    .OBJC_ASSOCIATION_RETAIN
                )
            }
        }
    }
    
    @objc public func opSetDynamic(handler: @escaping OPDynamicValueSetter) {
        // Get trait observer object
        if opTraitObserver == nil {
            opTraitObserver = OPUDTraitObserver()
        }
        // Call immediately to set the property
        handler(traitCollection)
        // Save the closure for trait collection changing
        opTraitObserver?.registerCallback(handler, forKey: UUID().uuidString)
    }
}

/// 等 UDDialog 支持 OC 后直接换成 UDDialog
@objcMembers
public final class UDDialogForOC: NSObject {
    
    public static func presentDialog(
        from: UIViewController,
        title: String? = nil,
        content: String? = nil,
        cancelTitle: String? = nil,
        cancelDismissCompletion: (() -> Void)? = nil,
        confirmTitle: String? = nil,
        confirmDismissCompletion: (() -> Void)? = nil
        ) {
        guard let from = OPUnsafeObject(from) else {
            return
        }
        let dialog = UDDialog()
        if let title = title {
            dialog.setTitle(text: title)
        }
        if let content = content {
            dialog.setContent(text: content)
        }
        if let cancelTitle = cancelTitle {
            dialog.addSecondaryButton(
                text: cancelTitle,
                dismissCompletion: cancelDismissCompletion
            )
        }
        if let confirmTitle = confirmTitle {
            dialog.addPrimaryButton(
                text: confirmTitle,
                dismissCompletion: confirmDismissCompletion
            )
        }
        
        if from.supportedInterfaceOrientations != .portrait {
            dialog.isAutorotatable = true
        }
        
        from.present(dialog, animated: true, completion: nil)
    }
    
}

/// 等 UDToast 支持 OC 后直接换成 UDToast
@objcMembers
public final class UDToastForOC: NSObject {
    
    private var loading: UDToast?
    
    public static func showSuccess(with text: String?, on view: UIView?) {
        guard let view = view ?? OPWindowHelper.fincMainSceneWindow(), let text = text else {
            return
        }
        
        UDToast.showSuccess(with: text, on: view)
    }
    
    public static func showFailure(with text: String?, on view: UIView?) {
        guard let view = view ?? OPWindowHelper.fincMainSceneWindow(), let text = text else {
            return
        }
        
        UDToast.showFailure(with: text, on: view)
    }
    
    public static func showTips(with text: String?, on view: UIView?) {
        guard let view = view ?? OPWindowHelper.fincMainSceneWindow(), let text = text else {
            return
        }
        
        UDToast.showTips(with: text, on: view)
    }
    
    public static func showLoading(with text: String?, on view: UIView?) -> UDToastForOC? {
        guard let view = view ?? OPWindowHelper.fincMainSceneWindow(), let text = text else {
            return nil
        }
        let instance = UDToastForOC()
        instance.loading = UDToast.showLoading(with: text, on: view)
        return instance
    }
    
    public func remove() {
        guard let loading = loading else {
            return
        }
        loading.remove()
    }
    
}

@objcMembers
public final class UDRotation: NSObject {
    public static func isAutorotate(from viewController: UIViewController?) -> Bool {
        guard let viewController = viewController else {
            return false
        }
        
        if viewController.supportedInterfaceOrientations != .portrait {
            if #available(iOS 16.0, *) {
                return true
            } else {
                return viewController.shouldAutorotate
            }
        }
        return false
    }

    public static func supportedInterfaceOrientations(from viewController: UIViewController?) -> UIInterfaceOrientationMask {
        guard let viewController = viewController else {
            return .portrait
        }
        return viewController.supportedInterfaceOrientations
    }
}
