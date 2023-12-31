//
//  GuideMasksViewController.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/13.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

public final class GuideMarksViewController: UIViewController {

    private weak var viewControllerDisplayedUnder: UIViewController?

    var maskViewManager: MaskViewManager = MaskViewManager()

    var currentMark: GuideMark?

    var currentBodyViewClass: viewClass?

    var currentBodyView: UIView?

    weak var guideMarkViewController: GuideMarksController?

    let layoutHelper: CustomViewLayoutHelper = CustomViewLayoutHelper()

    var updateMarkBlock: ((inout GuideMark) -> Void)?

    var screenshotView: UIImageView?

    var startingOrientation: UIInterfaceOrientation?

    lazy var guideRootView: GuideRootView = {
        let view = GuideRootView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startingOrientation = UIApplication.shared.statusBarOrientation
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        rotateOrientation(orientation: UIApplication.shared.statusBarOrientation)
    }

    func rotateOrientation(orientation: UIInterfaceOrientation) {
        var transform = CGAffineTransform.identity
        if self.startingOrientation == .portrait {
            switch orientation {
            case .landscapeLeft:
                transform = CGAffineTransform(rotationAngle: CGFloat(M_PI/2.0))
                break
            case .landscapeRight:
                transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI/2.0))
                break
            case .portrait:
                transform = .identity
                break
            case .portraitUpsideDown:
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                break
            default:
                break
            }
        } else if self.startingOrientation == .portraitUpsideDown {
            switch orientation {
            case .landscapeLeft:
                transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI/2.0))
                break
            case .landscapeRight:
                transform = CGAffineTransform(rotationAngle: CGFloat(M_PI/2.0))
                break
            case .portrait:
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                break
            case .portraitUpsideDown:
                transform = .identity
                break
            default:
                break
            }
        } else if self.startingOrientation == .landscapeLeft {
            switch orientation {
            case .landscapeLeft:
                transform = .identity
                break
            case .landscapeRight:
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                break
            case .portrait:
                transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI/2.0))
                break
            case .portraitUpsideDown:
                transform = CGAffineTransform(rotationAngle: CGFloat(M_PI/2.0))
                break
            default:
                break
            }
        } else if self.startingOrientation == .landscapeRight {
            switch orientation {
            case .landscapeLeft:
                transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                break
            case .landscapeRight:
                transform = .identity
                break
            case .portrait:
                transform = CGAffineTransform(rotationAngle: CGFloat(M_PI/2.0))
                break
            case .portraitUpsideDown:
                transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI/2.0))
                break
            default:
                break
            }
        }
        self.view.window?.transform = transform
    }

    public override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willAnimateRotation(to: toInterfaceOrientation, duration: duration)
    }

    func attach(to window: UIWindow, over viewController: UIViewController,
                at windowLevel: UIWindow.Level? = nil) {

        window.windowLevel = UIWindow.Level.statusBar - 1

        viewControllerDisplayedUnder = viewController

        view.addSubview(guideRootView)
        guideRootView.fillSuperview()

        addMaskView()

        window.rootViewController = self
        window.isHidden = false
    }

    func detachFromWindow() {

        guideRootView.removeFromSuperview()
        let window = view.window
        window?.isHidden = true
        window?.rootViewController = nil
        window?.accessibilityIdentifier = nil
        view.removeFromSuperview()
    }

    func addMaskView() {
        guideRootView.addSubview(maskViewManager.maskView)
        maskViewManager.maskView.fillSuperview()
    }

    func addCustomBodyIfHave() {
        guard let currentBodyClass = self.currentMark?.bodyViewClass else {
            self.currentMark?.layoutFinish?()
            return
        }
        var convertedFrame: CGRect?
        if let cutoutView = currentMark?.cutoutView() {
            convertedFrame = guideRootView.convert(cutoutView.frame, from: cutoutView.superview)
        }

        if let cutoutBezier = currentMark?.cutoutPath {
            convertedFrame = cutoutBezier.bounds
        }

        if let lazyCutoutBezier = currentMark?.lazyCutoutPath {
            convertedFrame = lazyCutoutBezier()?.bounds
        }

        self.currentBodyViewClass = currentBodyClass.init(focusPoint: currentMark?.cutoutPoint, focusArea: convertedFrame)
        self.currentBodyViewClass?.show(to: maskViewManager.maskView, mark: currentMark, guideMarkController: self.guideMarkViewController, complete: { [weak self] in
            self?.currentMark?.layoutFinish?()
        })
        if let bodyView = self.currentBodyViewClass as? BodyViewClass<GuideAtUserView> {
            bodyView.setup()?.clickBlock = { [weak self] (_) in
                self?.guideMarkViewController?.showNextStep()
                self?.currentMark?.bodyViewClick?()
            }
        }
        if let bodyView = self.currentBodyViewClass as? BodyViewClass<SwitchUserGuideView> {
            bodyView.setup()?.clickBlock = { [weak self] in
                self?.guideMarkViewController?.showNextStep()
            }
        }
    }

    func addBodyView() {
        addCustomBodyIfHave()
    }

    func show (byMark guideMark: GuideMark) {

        guideMark.startAction { [weak self] in
            guard let `self` = self else { return }
            if let screenshot = self.viewControllerDisplayedUnder?.view.window?.lu.screenshot() {
                self.screenshotView = UIImageView(image: screenshot)
                self.view.insertSubview(self.screenshotView!, at: 0)
            }
            self.currentMark = guideMark
            self.updateMarkBlock?(&self.currentMark!)
            self.maskViewManager.maskView.cutoutPath = self.currentMark!.cutoutPath
            if guideMark.displayOverCutoutPath {
                self.maskViewManager.showCutoutPath(true, withDuration: 0.2, completion: { [weak self] _ in
                    self?.addBodyView()
                })

            }
        }
    }

    func hide (completion: (() -> Void)? = nil) {
        screenshotView?.removeFromSuperview()
        screenshotView = nil
        maskViewManager.showCutoutPath(false, withDuration: 0.2, completion: { [weak self] _ in
            self?.currentBodyViewClass?.dismiss()
            self?.currentBodyViewClass = nil
            self?.currentMark?.endAction {
                completion?()
            }
        })
    }

    func prepareShowMaskView(_ completion: @escaping () -> Void) {
        maskViewManager.showOverlay(true) { _ in
            completion()
        }
    }
}
