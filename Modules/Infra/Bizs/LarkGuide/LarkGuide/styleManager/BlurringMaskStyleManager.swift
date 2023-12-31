//
//  BlurringMaskStyleManager.swift
//  LarkChat
//
//  Created by sniper on 2018/11/20.
//

import Foundation
import UIKit

final class BlurringMaskStyleManager: MaskStyleManager {

    weak var maskView: MaskView? {
        didSet {
            sizeTransitionOverlay = UIVisualEffectView(effect: blurEffect)
            sizeTransitionOverlay?.translatesAutoresizingMaskIntoConstraints = false
            sizeTransitionOverlay?.isHidden = true

            maskView?.holder.addSubview(sizeTransitionOverlay!)
            sizeTransitionOverlay?.fillSuperview()
        }
    }

    private var mask: BlurMaskView {
        let view = BlurMaskView()
        view.backgroundColor = UIColor.clear

        guard let overlay = self.maskView,
            let cutoutPath = self.maskView?.cutoutPath else {
                return view
        }

        let path = UIBezierPath(rect: overlay.bounds)
        path.append(cutoutPath)
        path.usesEvenOddFillRule = true

        view.shapeLayer.path = path.cgPath
        view.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd

        return view
    }

    private var sizeTransitionOverlay: UIView?

    private var cutoutMaskView: (background: MaskSnapshotView, foreground: MaskSnapshotView)?

    private var isOverlayHidden: Bool = true

    private var subMask: UIView?

    private let style: UIBlurEffect.Style

    private var blurEffect: UIVisualEffect {
        return UIBlurEffect(style: style)
    }

    // MARK: Initialization
    init(style: UIBlurEffect.Style) {
        self.style = style
    }

    private func setUpOverlay() {
        guard let cutoutOverlays = self.makeSnapshotOverlays() else { return }

        self.cutoutMaskView = cutoutOverlays

        subMask = UIVisualEffectView(effect: blurEffect)
        subMask?.translatesAutoresizingMaskIntoConstraints = false
    }

    private func makeSnapshotView() -> MaskSnapshotView? {
        guard let maskView = maskView else {
                return nil
        }

        let view = MaskSnapshotView(frame: maskView.bounds)
        let backgroundEffectView = UIVisualEffectView(effect: blurEffect)
        backgroundEffectView.frame = maskView.bounds
        backgroundEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false

        view.visualEffectView = backgroundEffectView

        return view
    }

    private func makeSnapshotOverlays() -> (background: MaskSnapshotView,
        foreground: MaskSnapshotView)? {
            guard let background = makeSnapshotView(),
                let foreground = makeSnapshotView() else {
                    return nil
            }
            return (background: background, foreground: foreground)
    }

    func showOverlay(_ show: Bool, withDuration duration: TimeInterval, completion: ((Bool) -> Void)?) {
        sizeTransitionOverlay?.isHidden = true
        let subviews = maskView?.holder.subviews

        setUpOverlay()

        guard let overlay = maskView,
            let subOverlay = subMask as? UIVisualEffectView else {
                completion?(false)
                return
        }

        overlay.isHidden = false
        overlay.alpha = 1.0

        subOverlay.frame = overlay.bounds
        subOverlay.effect = (show || isOverlayHidden) ? nil : blurEffect

        subviews?.forEach { if $0 !== sizeTransitionOverlay { $0.removeFromSuperview() } }
        overlay.holder.addSubview(subOverlay)

        UIView.animate(withDuration: duration, animations: {
            subOverlay.effect = show ? self.blurEffect : nil
            overlay.ornaments.alpha = show ? 1.0 : 0.0
            self.isOverlayHidden = !show
        }, completion: { success in
            if !show {
                subOverlay.removeFromSuperview()
                overlay.alpha = 0.0
            }
            completion?(success)
        })
    }

    func showCutout(_ show: Bool, withDuration duration: TimeInterval, completion: ((Bool) -> Void)?) {

        let subviews = maskView?.holder.subviews

        setUpOverlay()
        sizeTransitionOverlay?.isHidden = true
        guard let overlay = maskView,
            let background = cutoutMaskView?.background,
            let foreground = cutoutMaskView?.foreground else {
                completion?(false)
                return
        }

        background.frame = overlay.bounds
        foreground.frame = overlay.bounds

        background.visualEffectView.effect = show ? self.blurEffect : nil
        foreground.visualEffectView.effect = self.blurEffect
        foreground.mask = self.mask

        subviews?.forEach { if $0 !== sizeTransitionOverlay { $0.removeFromSuperview() } }

        overlay.holder.addSubview(background)
        overlay.holder.addSubview(foreground)

        UIView.animate(withDuration: duration, animations: {
            if duration > 0 {
                background.visualEffectView?.effect = show ? nil : self.blurEffect
            }
        }, completion: { success in
            background.removeFromSuperview()
            completion?(success)
        })
    }
}
