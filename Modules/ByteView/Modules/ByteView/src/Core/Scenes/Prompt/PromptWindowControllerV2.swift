//
//  PromptWindowControllerV2.swift
//  ByteView
//
//  Created by wangpeiran on 2022/10/18.
//

import Foundation
import ByteViewUI
import ByteViewCommon

final class PromptWindowControllerV2 {
    static let shared = PromptWindowControllerV2()
    private var window: FollowVcWindow?
    weak var currentVC: UIViewController?

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount),
                                               name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount() {
        DispatchQueue.main.async {
            self.cleanWindow()
        }
    }

    func showVC(vc: UIViewController) {
        DispatchQueue.main.async {
            self.window = self.makeWindowIfNeeded()
            self.window?.rootViewController = vc
            self.currentVC = vc
            self.presentWindow(animated: true)
        }
    }

    func dismissVC() {
        DispatchQueue.main.async {
            self.dismissWindow(animated: true)
        }
    }
}

// MARK: - Window

private extension PromptWindowControllerV2 {
    func makeWindowIfNeeded() -> FollowVcWindow {
        if let window = window {
            return window
        } else {
            let window = VCScene.createWindow(FollowVcWindow.self, tag: .prompt)
            self.window = window
            window.backgroundColor = UIColor.clear
            window.windowLevel = UIWindow.Level.alert
            window.isHidden = false
            return window
        }
    }

    func cleanWindow() {
        currentVC = nil
        window?.rootViewController = nil
        window?.isHidden = true
        window = nil
    }

    func presentWindow(animated: Bool, completion: (() -> Void)? = nil) {
        guard let window = window else { return }
        if animated {
            let maxY = window.frame.height
            window.transform = CGAffineTransform(translationX: 0.0, y: -maxY)
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseInOut, animations: {
                window.transform = .identity
                window.alpha = 1.0
            }, completion: { _ in
                completion?()
            })
        } else {
            completion?()
        }
    }

    func dismissWindow(animated: Bool, completion: (() -> Void)? = nil) {
        guard let window = self.window else {
            completion?()
            return
        }
        let wrapper: (Bool) -> Void = { _ in
            self.cleanWindow()
            completion?()
        }
        if animated {
            let maxY = window.frame.height
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseInOut, animations: {
                window.transform = CGAffineTransform(translationX: 0.0, y: -maxY)
                window.alpha = 0.0
            }, completion: wrapper)
        } else {
            wrapper(true)
        }
    }
}
