//
//  DynamicModalBooter.swift
//  ByteViewUI
//
//  Created by Tobb Huang on 2023/4/21.
//

import Foundation
import ByteViewCommon

public extension UIViewController {

    func presentDynamicModal(_ vc: UIViewController, regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig,
                             animated: Bool = true, completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(Thread.isMainThread, "presentDynamicModal must called in main thread")
        Logger.ui.info("presentDynamicModal \(vc) \(regularConfig.presentationStyle) \(compactConfig.presentationStyle)")
        var presentedVC = vc
        switch (regularConfig.presentationStyle, compactConfig.presentationStyle) {
        // 涉及到popover、pagesheet，均需要用Popover相关配置
        case (.popover, _), (_, .pageSheet):
            // popover无法在delegate中添加navi（相关方法不会被系统调用），原因未知
            if regularConfig.needNavigation {
                presentedVC = NavigationController(rootViewController: presentedVC)
            }
            prepareForPopover(presentedVC, regularConfig: regularConfig, compactConfig: compactConfig)
        default:
            prepareForNonPopover(presentedVC, regularConfig: regularConfig, compactConfig: compactConfig)
        }
        self.vc.safePresent(presentedVC, animated: animated) {
            completion?(.success(Void()))
        }
    }

    func presentDynamicModal(_ vc: UIViewController, config: DynamicModalConfig,
                             animated: Bool = true, completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(Thread.isMainThread, "presentDynamicModal must called in main thread")
        Logger.ui.info("presentDynamicModal \(vc) \(config.presentationStyle)")
        var presentedVC = vc
        switch config.presentationStyle {
        case .popover:
            prepareForPopover(presentedVC, regularConfig: config, compactConfig: config)
        case .pan:
            prepareForNonPopover(presentedVC, regularConfig: config, compactConfig: config)
        default:
            if config.needNavigation {
                presentedVC = NavigationController(rootViewController: presentedVC)
            }
            presentedVC.modalPresentationStyle = config.presentationStyle.systemModalStyle
            presentedVC.modalPresentationCapturesStatusBarAppearance = true
        }
        self.vc.safePresent(presentedVC, animated: animated) {
            completion?(.success(Void()))
        }
    }
}

extension UIViewController {

    private static var presentationControllerHolderKey = "dynamicModalPresentationControllerHolder"
    var dmPresentationController: DynamicModalPresentationController? {
        get { objc_getAssociatedObject(self, &Self.presentationControllerHolderKey) as? DynamicModalPresentationController }
        set { objc_setAssociatedObject(self, &Self.presentationControllerHolderKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    private func prepareForPopover(_ vc: UIViewController, regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig) {
        vc.modalPresentationStyle = .popover

        if let popoverConfig = regularConfig.popoverConfig ?? compactConfig.popoverConfig {
            vc.decoratePopover(with: popoverConfig)
        }
        let dmPresentationController = DynamicModalPresentationController(regularConfig: regularConfig, compactConfig: compactConfig)
        vc.dmPresentationController = dmPresentationController
        vc.popoverPresentationController?.delegate = dmPresentationController
    }

    private func prepareForNonPopover(_ vc: UIViewController, regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig) {
        let dmPresentationController = DynamicModalPresentationController(regularConfig: regularConfig, compactConfig: compactConfig)
        vc.dmPresentationController = dmPresentationController
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = dmPresentationController
        vc.modalPresentationCapturesStatusBarAppearance = true
    }
}
