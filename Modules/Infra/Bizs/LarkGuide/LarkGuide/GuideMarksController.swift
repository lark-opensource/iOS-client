//
//  GuideMarksController.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/13.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import UIKit

public final class GuideMarksController {

    // MARK: - Private properties
    fileprivate weak var controllerWindow: UIWindow?
    fileprivate var GuideMarksWindow: UIWindow?
    fileprivate(set) lazy var maskViewManager: MaskViewManager = {
        let maskviewManager = MaskViewManager()
        maskviewManager.maskViewManagerDelegate = self
        return maskviewManager
    }()

    fileprivate(set) lazy var flowManager: GuideFlowManager = {
        let flowManager = GuideFlowManager(guideMarksViewController: self.guideMarksViewController)
        return flowManager
    }()

    fileprivate(set) public lazy var helper: GuideMarkHelper! = {
        let guideRootView = self.guideMarksViewController.guideRootView
        return GuideMarkHelper(guideRootView: guideRootView, guideFlowManager: self.flowManager)
    }()

    fileprivate lazy var guideMarksViewController: GuideMarksViewController = {
        let guideMarksViewController = GuideMarksViewController()
        guideMarksViewController.maskViewManager = self.maskViewManager
        guideMarksViewController.guideMarkViewController = self
        guideMarksViewController.updateMarkBlock = { mark in
            self.helper.update(guideMark: &mark, usingView: mark.cutoutView())
            if let lazyCutout = mark.lazyCutoutPath {
                mark.cutoutPath = lazyCutout()
            }
        }
        return guideMarksViewController
    }()

    lazy var guideRootView: GuideRootView = {
        let view = GuideRootView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()

    var guideMarks: [GuideMark]?

    fileprivate var isShow: Bool = false

    public var clickMaskBlock: (() -> Void)?

    // MARK: - Lifecycle
    public init() { }
}

public extension GuideMarksController {

    /// start instruction
    ///
    /// - Parameters:
    ///   - bearViewController: bear viewcontroller
    ///   - guideMarks: [GuideMark] instruction data, number of guideMarks is step count
    ///   - blurEffectStyle: if need blurEffectStyle should set blurEffectStyle
    ///   - color: maskview background color
    /// - Returns: currentRootView
    @discardableResult
    func start(by bearViewController: UIViewController,
                      guideMarks: () -> [GuideMark],
                      blurEffectStyle: UIBlurEffect.Style? = nil,
                      color: UIColor? = #colorLiteral(red: 0.9086670876, green: 0.908688426, blue: 0.9086769819, alpha: 0.65),
                      dismissBlock: (() -> Void)? = nil) -> UIView? {
        if isShow { return nil }
        isShow = true
        self.guideMarks = guideMarks()
        self.clearRootView()
        if let guideMarks = self.guideMarks {
            guard !guideMarks.isEmpty else { return nil }

            controllerWindow = bearViewController.view.window
            GuideMarksWindow = GuideMarksWindow ?? GuideWindow(frame: UIScreen.main.bounds)
            if #available(iOS 13.0, *) {
                GuideMarksWindow?.windowScene = controllerWindow?.windowScene
            }
            guideMarksViewController.attach(to: GuideMarksWindow!, over: bearViewController, at: nil)
            guideMarksViewController.maskViewManager.allowTap = true
            guideMarksViewController.maskViewManager.color = color!
            guideMarksViewController.maskViewManager.blurEffectStyle = blurEffectStyle
            flowManager.startFlow(withGuideMarks: guideMarks)
            flowManager.stopFlowBlock = { [weak self] in
                self?.isShow = false
                dismissBlock?()
            }
        }
        return guideMarksViewController.guideRootView
    }

    func forceStop() {
        self.flowManager.stopFlow()
    }

    func showNextStep() {
        self.flowManager.showNextGuide()
    }

    func getRootView() -> UIView {
        return self.guideMarksViewController.guideRootView
    }

    private func clearRootView() {

        for subview in guideMarksViewController.guideRootView.subviews {
            subview.removeFromSuperview()
        }
        guideMarksViewController.guideRootView.removeFromSuperview()
    }
}

// maskViewManagerDelegate
extension GuideMarksController: MaskViewManagerDelegate {

    func didRecivedSingleTap() {
        self.clickMaskBlock?()
        flowManager.showNextGuide()
    }
}
