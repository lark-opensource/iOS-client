//
//  PanViewController.swift
//  ByteRtcRenderDemo
//
//  Created by huangshun on 2019/10/12.
//  Copyright © 2019 huangshun. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public final class PanViewController: UIViewController {

    var beginTop: CGFloat = 0.0

    var stack: [PanWare] = []

    var currentLayout: RoadLayout = .shrink

    var belowWare: PanWare? {
        return stack.last
    }

    var aboveWare: PanWare? {
        guard stack.count >= 2 else { return nil }
        return stack[stack.count - 2]
    }

    public var belowViewController: UIViewController? {
        belowWare?.viewController
    }

    public var aboveViewController: UIViewController? {
        aboveWare?.viewController
    }

    public var viewControllers: [UIViewController] {
        return stack.map { $0.viewController }
    }

    public var isStackEmpty: Bool {
        return stack.isEmpty
    }

    public lazy var touchView: UIView = {
        let touchView = UIView(frame: .zero)
        touchView.addGestureRecognizer(tapGesture)
        touchView.frame = view.bounds
        touchView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return touchView
    }()

    lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(handlePanGesture(gesture:)))
        return panGesture
    }()

    lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(handleTapGesture(gesture:)))
        return tapGesture
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(touchView)
        navigationController?.navigationBar.isHidden = true
        navigationController?.isNavigationBarHidden = true
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        resetBelowWareLayout()
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return belowWare?.viewController.preferredStatusBarStyle ?? .default
    }

    public override var prefersStatusBarHidden: Bool {
        return belowWare?.viewController.prefersStatusBarHidden ?? false
    }

    func insertWare(_ ware: PanWare?, below: PanWare?) {
        guard let aboveWare = ware, let belowWare = below else {
            return
        }
        view.insertSubview(aboveWare.wrapper, belowSubview: belowWare.wrapper)
        aboveWare.resetLayout(currentLayout, view: view)
    }

    func addChildWare(_ ware: PanWare?) {
        guard let add = ware else { return }
        addChild(add.viewController)
        view.addSubview(add.wrapper)
        add.viewController.didMove(toParent: self)
        add.wrapper.addGestureRecognizer(panGesture)
        panGesture.delegate = add.gestureDelegate
    }

    func removeChildWare(_ ware: PanWare?) {
        guard let remove = ware else { return }
        remove.viewController.willMove(toParent: nil)
        remove.viewController.removeFromParent()
        remove.wrapper.removeFromSuperview()
        remove.wrapper.removeGestureRecognizer(panGesture)
    }

    func makeWare(with viewController: UIViewController) -> PanWare {
        let ware = PanWare(wrapper: PanWrapperView(frame: .zero), viewController: viewController)
        ware.viewController.view.frame = ware.wrapper.contentView.bounds
        ware.viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        ware.wrapper.contentView.addSubview(ware.viewController.view)
        return ware
    }

    func checkLayout(_ ware: PanWare) {
        guard !stack.isEmpty else {
            currentLayout = ware.panProxy.defaultLayout
            return
        }
        let becomeLayout = ware.panProxy.defaultLayout
        switch (currentLayout, becomeLayout) {
        case (.expand, _): currentLayout = .expand
        default: currentLayout = becomeLayout
        }
    }

    func addPushCommit(_ ware: PanWare, from: PanWare?, animated: Bool) {
        ware.updateLayoutUnderBottom(view, layout: currentLayout)
        view.layoutIfNeeded()

        let springDamping = ware.panProxy.springDamping
        let options = ware.panProxy.transitionAnimationOptions

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: 0,
            options: options,
            animations: {
                ware.resetLayout(self.currentLayout, view: self.view)
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.removeChildWare(from)
        })
    }

    func addPopCommit(_ fromWare: PanWare?, toWare: PanWare?, complete: (() -> Void)? = nil) {
        fromWare?.updateLayoutUnderBottom(view, layout: currentLayout)

        let springDamping = fromWare?.panProxy.springDamping ?? 0
        let options = fromWare?.panProxy.transitionAnimationOptions ?? []

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: 0,
            options: options,
            animations: {
                if self.stack.isEmpty {
                    self.view.superview?.backgroundColor = UIColor.clear
                }
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.removeChildWare(fromWare)
                guard self.stack.isEmpty else {
                    complete?()
                    return
                }
                self.presentingViewController?.dismiss(
                    animated: false,
                    completion: complete
                )
        })
    }

    override public var shouldAutorotate: Bool {
        if let child = belowWare?.viewController {
            return child.shouldAutorotate
        }
        return super.shouldAutorotate
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let child = belowWare?.viewController {
            return child.supportedInterfaceOrientations
        }
        return .allButUpsideDown
    }

    private var lastFrame: CGRect = .zero
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if lastFrame != self.view.frame {
            self.lastFrame = self.view.frame
            resetBelowWareLayout()
        }
    }

    private func resetBelowWareLayout() {
        if Thread.isMainThread {
            self.belowWare?.resetLayout(self.currentLayout, view: self.view)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.belowWare?.resetLayout(self.currentLayout, view: self.view)
            }
        }
    }

}
