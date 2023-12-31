//
//  AlignPopoverManager.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/11/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI

final class AlignPopoverManager {

    static let shared: AlignPopoverManager = AlignPopoverManager()

    private weak var alignPopoverViewController: AlignPopoverViewController?

    @discardableResult
    func present(viewController: UIViewController,
                 from: UIViewController? = nil,
                 anchor: AlignPopoverAnchor,
                 delegate: AlignPopoverPresentationDelegate? = nil,
                 animated: Bool = true) -> AlignPopoverViewController {
        self.dismiss(animated: false)
        let vc = AlignPopoverViewController(childVC: viewController, anchor: anchor, delegate: delegate)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve

        if animated {
            addCustomTransitionAnimation(in: from?.view.window)
        }
        let from = from ?? anchor.sourceView.window?.rootViewController?.vc.topMost
        from?.vc.safePresent(vc, animated: false) {
            vc.delegate?.didPresent()
        }
        alignPopoverViewController = vc
        return vc
    }

    func update(viewController: UIViewController? = nil, anchor: AlignPopoverAnchor) {
        alignPopoverViewController?.update(childVC: viewController, anchor: anchor)
    }

    func update(sourceView: UIView) {
        if let vc = alignPopoverViewController {
            vc.update(sourceView: sourceView)
        }
    }

    func dismiss(animated: Bool) {
        alignPopoverViewController?.dismiss(animated: animated, completion: { [weak self] in
            self?.alignPopoverViewController?.delegate?.didDismiss()
            self?.alignPopoverViewController = nil
        })
    }

    func addCustomTransitionAnimation(in targetWindow: UIWindow? = nil) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = .fade

        var window: UIWindow?
        if let targetWindow = targetWindow {
            window = targetWindow
        } else if let vc = alignPopoverViewController {
            window = vc.view.window
        } else {
            window = FloatingWindow.current
        }
        window?.layer.add(transition, forKey: kCATransition)
    }

    var isShowing: Bool {
        alignPopoverViewController != nil
    }

    var showingVC: UIViewController? {
        alignPopoverViewController?.childVC
    }
}
