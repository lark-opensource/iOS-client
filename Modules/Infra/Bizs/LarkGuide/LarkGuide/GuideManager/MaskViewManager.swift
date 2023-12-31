//
//  maskViewManager.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/13.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import UIKit

public final class MaskViewManager: NSObject {

    internal lazy var maskView: MaskView = MaskView()

    private lazy var maskStyleManager: MaskStyleManager = {
        return self.updateMaskStyleManager()
    }()

    public var blurEffectStyle: UIBlurEffect.Style? {
        didSet {
            maskStyleManager = updateMaskStyleManager()
        }
    }

    internal weak var maskViewManagerDelegate: MaskViewManagerDelegate?

    // maskView backgroundColor
    public var color: UIColor = #colorLiteral(red: 0.9086670876, green: 0.908688426, blue: 0.9086769819, alpha: 0.65)

    public var cutoutPath: UIBezierPath? {
        get {
            return maskView.cutoutPath
        }

        set {
            maskView.cutoutPath = newValue
        }
    }

    private lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(handleSingleTap(_:)))

        return gestureRecognizer
    }()

    public var allowTap: Bool {
        get {
            return self.singleTapGestureRecognizer.view != nil
        }

        set {
            if newValue == true {
                self.maskView.addGestureRecognizer(self.singleTapGestureRecognizer)
            } else {
                self.maskView.removeGestureRecognizer(self.singleTapGestureRecognizer)
            }
        }
    }

    func showCutoutPath(_ show: Bool, withDuration duration: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        maskStyleManager.showCutout(show, withDuration: duration, completion: completion)
    }

    func showOverlay(_ show: Bool, completion: ((Bool) -> Void)?) {
        maskStyleManager.showOverlay(show, withDuration: 0.2,
                                        completion: completion)
        if !show {
            self.maskView.removeFromSuperview()
            self.maskView = MaskView()
        }
    }

    private func updateMaskStyleManager() -> MaskStyleManager {
        if let style = blurEffectStyle, !UIAccessibility.isReduceTransparencyEnabled {
            let blurringMaskStyleManager = BlurringMaskStyleManager(style: style)
            updateDependencies(of: blurringMaskStyleManager)
            return blurringMaskStyleManager
        } else {
            let translucentMaskStyleManager = TranslucentMaskStyleManager(color: color)
            updateDependencies(of: translucentMaskStyleManager)
            return translucentMaskStyleManager
        }
    }

    private func updateDependencies(of maskAnimator: BlurringMaskStyleManager) {
        maskAnimator.maskView = self.maskView
    }

    private func updateDependencies(of maskAnimator: TranslucentMaskStyleManager) {
        maskAnimator.maskView = self.maskView
    }

    // GestureRecognizer
    @objc
    fileprivate func handleSingleTap (_ sender: AnyObject?) {
        self.maskViewManagerDelegate?.didRecivedSingleTap()
    }
}

internal protocol MaskViewManagerDelegate: AnyObject {
    func didRecivedSingleTap()
}
