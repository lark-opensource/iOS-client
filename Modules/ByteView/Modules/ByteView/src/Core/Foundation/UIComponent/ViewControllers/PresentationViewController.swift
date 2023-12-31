//
//  PresentationViewController.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/10/11.
//

import UIKit
import ByteViewCommon
import ByteViewUI
import ByteViewTracker

class PresentationViewController: UIViewController, FloatingWindowTransitioning, FloatableViewController {

    static let logger = Logger.ui
    private var fullScreenFactory: (() -> UIViewController)!
    private var floatingFactory: (() -> UIViewController)!
    private lazy var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))

    private weak var currentVC: UIViewController?

    private var transitioningObject: FloatingWindowTransitioning? {
        currentVC as? FloatingWindowTransitioning
    }

    let router: Router

    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        Self.logger.info("handle tap")
        VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: "click"])
        router.setWindowFloating(false)
    }

    override var childForStatusBarStyle: UIViewController? {
        return currentVC ?? super.childForStatusBarStyle
    }

    override var childForStatusBarHidden: UIViewController? {
        return currentVC ?? super.childForStatusBarHidden
    }

    override var shouldAutorotate: Bool {
        return currentVC?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard !Display.pad else {
            return .all
        }
        return currentVC?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    private lazy var logDescription = metadataDescription(of: self)
    init(router: Router, fullScreenFactory: @escaping () -> UIViewController, floatingFactory: @escaping () -> UIViewController) {
        self.router = router
        super.init(nibName: nil, bundle: nil)
        self.floatingFactory = floatingFactory
        self.fullScreenFactory = fullScreenFactory
        Self.logger.info("init \(logDescription)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.logger.info("deinit \(logDescription)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        exchangeChild(isFloating: router.isFloating)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        router.window?.bringWatermarkToFront()
    }

    private func exchangeChild(isFloating: Bool) {
        let vc: UIViewController
        if isFloating {
            vc = floatingFactory()
            Self.logger.info("add tap")
            vc.view.addGestureRecognizer(tap)
            if let w = self.view.window {
                Toast.hideToasts(in: w)
            }
        } else {
            vc = fullScreenFactory()
            Self.logger.info("remove tap")
            vc.view.removeGestureRecognizer(tap)
        }
        let from = self.currentVC
        self.addChild(vc)
        currentVC = vc
        from?.willMove(toParent: nil)

        vc.view.frame = self.view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)

        if let w = self.view.window, w.isKeyWindow {
            self.setNeedsStatusBarAppearanceUpdate()
        }

        from?.view.removeFromSuperview()
        from?.removeFromParent()
    }

    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        if let vc = self.currentVC as? InMeetContainerViewController {
            vc.floatingWindowWillTransition(to: frame, isFloating: isFloating)
        }
        exchangeChild(isFloating: isFloating)
        transitioningObject?.floatingWindowWillTransition(to: frame, isFloating: isFloating)
    }

    func floatingWindowWillChange(to isFloating: Bool) {
        if let vc = self.currentVC as? InMeetContainerViewController {
            vc.floatingWindowWillChange(to: isFloating)
        }
    }

    func floatingWindowDidChange(to isFloating: Bool) {
        if let vc = self.currentVC as? InMeetContainerViewController {
            vc.floatingWindowDidChange(to: isFloating)
        }
    }

    func animateAlongsideFloatingWindowTransition(to frame: CGRect, isFloating: Bool) {
        transitioningObject?.animateAlongsideFloatingWindowTransition(to: frame, isFloating: isFloating)
    }

    func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool) {
        transitioningObject?.floatingWindowDidTransition(to: frame, isFloating: isFloating)
    }
}
