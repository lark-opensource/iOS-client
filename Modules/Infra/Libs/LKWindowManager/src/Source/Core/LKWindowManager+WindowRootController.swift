//
//  LKBaseViewController.swift
//  LKWindowManager
//
//  Created by 白镜吾 on 2022/10/27.
//

import Foundation
import UIKit

open class LKWindowRootView: UIView {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        if hitView == self {
            return nil
        }
        return hitView
    }
}

open class LKWindowRootController: UIViewController {

    var currentDeviceOrientation: UIDeviceOrientation = Utility.getCurrentDeviceOrientation()

    var interfaceOrientations: UIInterfaceOrientationMask = Utility.getCurrentOrientationMask()

    private let virtualWindowVCs = NSHashTable<UIViewController>.weakObjects()

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        Utility.execOnlyUnderIOS16 {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.observeOrientationDidChangeNotification),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.observeOrientationDidChangeNotification),
                                                   name: UIApplication.didChangeStatusBarOrientationNotification,
                                                   object: nil)
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return interfaceOrientations
    }

    open override var shouldAutorotate: Bool {
        return true
    }

    open override func loadView() {
        self.view = LKWindowRootView()
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.willTransition(to: newCollection, with: coordinator)
        }
        
        guard self.isViewLoaded else {
            super.willTransition(to: newCollection, with: coordinator)
            return
        }

        guard UIDevice.current.userInterfaceIdiom == .phone else {
            super.willTransition(to: newCollection, with: coordinator)
            return
        }

        if #available(iOS 16.0, *),
           self.traitCollection.hasDifferentColorAppearance(comparedTo: newCollection) {
            super.willTransition(to: newCollection, with: coordinator)
            return
        }

        rotateViewControllerIfNeeded()

        super.willTransition(to: newCollection, with: coordinator)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.viewWillTransition(to: size, with: coordinator)
        }

        super.viewWillTransition(to: size, with: coordinator)

    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.traitCollectionDidChange(previousTraitCollection)
        }
        super.traitCollectionDidChange(previousTraitCollection)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func observeOrientationDidChangeNotification() {
        self.rotateViewControllerIfNeeded()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.beginAppearanceTransition(true, animated: animated)
        }

        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        guard let transitionCoordinator = self.transitionCoordinator else {
            self.rotateViewControllerIfNeeded()
            return
        }
        self.willTransition(to: self.traitCollection, with: transitionCoordinator)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.endAppearanceTransition()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.beginAppearanceTransition(false, animated: animated)
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.virtualWindowVCs.allObjects.forEach { vc in
            vc.endAppearanceTransition()
        }
    }

    public func addVirtualWindowVC(_ vc: UIViewController) {
        self.virtualWindowVCs.add(vc)
    }
}

extension LKWindowRootController {

    func rotateViewControllerIfNeeded() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        let newOrientationMask = Utility.getCurrentOrientationMask()
        let newDeviceOrientation = Utility.getCurrentDeviceOrientation()

        if #available(iOS 16.0, *),
           let windowScene = UIApplication.shared.connectedScenes.first(where: {
               $0.session.role == .windowApplication
           }) as? UIWindowScene,
           let window = (view.window as? LKWindow) {
            self.interfaceOrientations = newOrientationMask
            Utility.focusRotateIfNeeded(to: newOrientationMask, window: window, windowScene: windowScene)
        } else {
            guard (interfaceOrientations.rawValue != newOrientationMask.rawValue) || (currentDeviceOrientation.rawValue != newDeviceOrientation.rawValue) else { return }
            self.currentDeviceOrientation = newDeviceOrientation
            self.interfaceOrientations = newOrientationMask
            Utility.focusRotateIfNeeded(to: newDeviceOrientation)
        }
    }
}
