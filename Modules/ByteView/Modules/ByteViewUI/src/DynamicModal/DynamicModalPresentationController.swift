//
//  DynamicModalPresentationController.swift
//  ByteViewUI
//
//  Created by Tobb Huang on 2023/4/21.
//

import Foundation

class DynamicModalPresentationController: NSObject {
    private(set) var regularConfig: DynamicModalConfig
    private(set) var compactConfig: DynamicModalConfig

    weak var adaptiveViewController: UIViewController?

    private var _traitCollection: UITraitCollection?
    var isRegular: Bool {
        _traitCollection?.isRegular ?? VCScene.isRegular
    }

    init(regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig) {
        self.regularConfig = regularConfig
        self.compactConfig = compactConfig
    }
}

extension DynamicModalPresentationController: UIViewControllerTransitioningDelegate {
    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let controller = UIPresentationController(presentedViewController: presented, presenting: presenting)
        controller.delegate = self
        return controller
    }
}

extension DynamicModalPresentationController: UIPopoverPresentationControllerDelegate {
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        let config = self.isRegular ? regularConfig : compactConfig
        return !config.disableSwipeDismiss
    }

    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if let delegate = presentationController.presentedViewController as? DynamicModalDelegate {
            delegate.didAttemptToSwipeDismiss()
        }
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        self._traitCollection = traitCollection
        let presentedViewController = controller.presentedViewController
        if let delegate = presentedViewController as? DynamicModalDelegate {
            delegate.regularCompactStyleDidChange(isRegular: traitCollection.isRegular)
        }

        if regularConfig.presentationStyle == compactConfig.presentationStyle && regularConfig.presentationStyle == .popover {
            return .none
        }

        switch(traitCollection.isRegular, regularConfig.presentationStyle, compactConfig.presentationStyle) {
        case (true, .popover, _):
            return .popover
        case (true, .formSheet, _):
             return .formSheet
        case (false, _, .pageSheet):
            return .pageSheet
        case (true, .fullScreen, _), (false, _, .fullScreen):
            // 背景可以透明
            return .fullScreen
        default:
            // 背景不可透明
            return .overFullScreen
        }
    }

    public func presentationController(_ controller: UIPresentationController,
                                       viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        var presentedViewController = controller.presentedViewController
        let config = self.isRegular ? regularConfig : compactConfig
        if config.needNavigation && !(presentedViewController is NavigationController) {
            if let adaptiveViewController = self.adaptiveViewController {
                presentedViewController = adaptiveViewController
            } else {
                let wrap = NavigationController(rootViewController: presentedViewController)
                self.adaptiveViewController = wrap
                presentedViewController = wrap
            }
        }

        presentedViewController.willMove(toParent: nil)
        presentedViewController.view.removeFromSuperview()
        presentedViewController.removeFromParent()

        if config.presentationStyle == .pan {
            let panVC = PanViewController()
            panVC.push(presentedViewController, animated: false)
            presentedViewController = panVC
        }

        presentedViewController.modalPresentationStyle = style
        return presentedViewController
    }

    public func presentationController(_ presentationController: UIPresentationController,
                                       willPresentWithAdaptiveStyle style: UIModalPresentationStyle,
                                       transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        let config = self.isRegular ? regularConfig : compactConfig
        if config.presentationStyle == .popover, let popoverConfig = config.popoverConfig {
            presentationController.presentedViewController.decoratePopover(with: popoverConfig)
        } else if let size = config.contentSize {
            presentationController.presentedViewController.dynamicModalSize = size
        }
        presentationController.presentForOverFullScreen(transitionCoordinator, config: config)
    }

    public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.containerView?.layer.shouldRasterize = true
        var displayScale: CGFloat = 1.0
        if let scale = _traitCollection?.displayScale {
            displayScale = scale > 0 ? scale : 1.0
        }
        popoverPresentationController.containerView?.layer.rasterizationScale = displayScale
        // 设置popover的自定义阴影
        let shadowColor: UIColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        popoverPresentationController.containerView?.layer.ud.setShadowColor(shadowColor)
        popoverPresentationController.containerView?.layer.shadowRadius = 100
        popoverPresentationController.containerView?.layer.shadowOffset = CGSize(width: 0, height: 10)
        popoverPresentationController.containerView?.layer.shadowOpacity = 1
    }

    public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController,
                                              willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
                                              in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        let config = self.isRegular ? regularConfig : compactConfig
        popoverPresentationController.containerView?.backgroundColor = config.backgroundColor
    }
}

extension DynamicModalPresentationController {
    func updateContentSizeConfig(_ size: CGSize, for category: DynamicModalConfig.Category) {
        if category == .regular || category == .both {
            regularConfig.popoverConfig?.popoverSize = size
            regularConfig.contentSize = size
        }
        if category == .compact || category == .both {
            compactConfig.popoverConfig?.popoverSize = size
            compactConfig.contentSize = size
        }
    }

    func updatePopoverConfig(_ popoverConfig: DynamicModalPopoverConfig, for category: DynamicModalConfig.Category) {
        if category == .regular || category == .both {
            regularConfig.popoverConfig = popoverConfig
        }
        if category == .compact || category == .both {
            compactConfig.popoverConfig = popoverConfig
        }
    }
}

extension UIViewController {
    var dynamicModalSize: CGSize {
        get {
            if let navi = self.navigationController {
                return navi.preferredContentSize
            }
            return self.preferredContentSize
        }
        set {
            if let navi = self.navigationController {
                navi.preferredContentSize = newValue
            } else {
                self.preferredContentSize = newValue
            }
        }
    }

    func decoratePopover(with popoverConfig: DynamicModalPopoverConfig) {
        if let size = popoverConfig.popoverSize {
            dynamicModalSize = size
        }
        popoverPresentationController?.sourceRect = popoverConfig.sourceRect
        popoverPresentationController?.sourceView = popoverConfig.sourceView
        popoverPresentationController?.backgroundColor = popoverConfig.backgroundColor
        popoverPresentationController?.popoverLayoutMargins = popoverConfig.popoverLayoutMargins
        if popoverConfig.hideArrow {
            popoverPresentationController?.popoverBackgroundViewClass = CustomPopoverBackgroundView.self
        }
        if let permittedArrowDirections = popoverConfig.permittedArrowDirections {
            popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        }
    }
}

extension UITraitCollection {
    var isRegular: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
}
