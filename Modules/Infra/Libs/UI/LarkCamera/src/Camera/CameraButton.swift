//
//  CameraButton.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/19.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit

public final class CameraButton: UIView {

    public enum LongPressState {
        case began
        case move(_ offset: CGPoint)
        case ended
        case richMaxDuration
    }

    public var onTap: ((_ tapGestureRecognizer: UITapGestureRecognizer) -> Void)?
    public var onLongPress: ((_ status: LongPressState) -> Void)?
    public var isLongPressEnable: Bool = true

    public var isZoomTimeIgnored: Bool = true
    public var duration: CFTimeInterval {
        get { return progressView.maxDuration }
        set { progressView.maxDuration = newValue }
    }
    private var lastLongPressPoint: CGPoint?

    let progressView = CameraProgressView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

    public override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(progressView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(innerOnTap))
        self.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(innerOnLongPress))
        self.addGestureRecognizer(longPress)
        tap.require(toFail: longPress)

        progressView.richMaxDuration = { [weak self] (_) in
            self?.onLongPress?(.richMaxDuration)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func innerOnTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        onTap?(tapGestureRecognizer)
    }

    @objc
    private func innerOnLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {

        guard isLongPressEnable else { return }

        var state: LongPressState?
        switch longPressGestureRecognizer.state {
        case .began:
            lastLongPressPoint = longPressGestureRecognizer.location(in: self)
            progressView.scaleToProgress()
            state = .began
        case .cancelled, .failed, .ended:
            lastLongPressPoint = nil
            progressView.scaleToNarmal()
            state = .ended
        case .changed:
            if let lastLongPressPoint = lastLongPressPoint {
                let currentLongPressPoint = longPressGestureRecognizer.location(in: self)
                let offset: CGPoint = CGPoint(x: currentLongPressPoint.x - lastLongPressPoint.x,
                                              y: currentLongPressPoint.y - lastLongPressPoint.y)
                self.lastLongPressPoint = currentLongPressPoint
                state = .move(offset)
            }
        default:
            break
        }

        guard let longPressState = state else { return }

        if isZoomTimeIgnored {
            onLongPress?(longPressState)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + progressView.zoomDuration) {
                self.onLongPress?(longPressState)
            }
        }
    }
}

final class CameraProgressView: UIView {

    struct AnimationConfig {
        var fillColor: CGColor
        var lineWidth: CGFloat
        var path: CGPath

        init(fillColor: UIColor, lineWidth: CGFloat, center: CGPoint, radius: CGFloat) {
            self.fillColor = fillColor.cgColor
            self.lineWidth = lineWidth
            self.path = UIBezierPath(arcCenter: center,
                                     radius: radius - lineWidth,
                                     startAngle: 0,
                                     endAngle: CGFloat(Double.pi * 2),
                                     clockwise: true).cgPath
        }
    }

    fileprivate var richMaxDuration: ((_ progressView: CameraProgressView) -> Void)?

    private let centerView: UIView = UIView()
    private let progressView: UIView = UIView()

    private let zoomLayer: CAShapeLayer = CAShapeLayer()
    private let progressLayer: CAShapeLayer = CAShapeLayer()
    private var progressPath: UIBezierPath

    private let normalRadius: CGFloat = 35
    private let normalLineWidth: CGFloat = 6
    private var normalCenterColor: UIColor = UIColor(white: 238.0 / 255, alpha: 1)
    private var trackColor: UIColor = UIColor.white

    private let progressRadius: CGFloat = 50
    private let progressLineWidth: CGFloat = 9
    private var progressCenterColor: UIColor = UIColor(white: 238.0 / 255, alpha: 0.5)
    private var progressColor: UIColor = UIColor(red: 54.0 / 255, green: 134.0 / 255, blue: 1, alpha: 1)

    private var isProgressing: Bool = false

    fileprivate var zoomDuration: CFTimeInterval = 0.15
    fileprivate var maxDuration: CFTimeInterval = 15

    private lazy var normalAnimationStruct = AnimationConfig(
        fillColor: normalCenterColor,
        lineWidth: normalLineWidth,
        center: zoomLayer.innerCenter,
        radius: normalRadius)

    private lazy var progressAnimationStruct = AnimationConfig(
        fillColor: progressCenterColor,
        lineWidth: progressLineWidth,
        center: zoomLayer.innerCenter,
        radius: progressRadius)

    private var innerCenter: CGPoint {
        return CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }

    override init(frame: CGRect) {

        let makeCircle: (_ arcCenter: CGPoint,
            _ radius: CGFloat,
            _ startAngle: CGFloat) -> UIBezierPath = { (center, radius, startAngle) in
            let endAngle = startAngle + CGFloat(Double.pi * 2)
            return UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        }
        progressPath = makeCircle(progressLayer.innerCenter,
                                  progressRadius - progressLineWidth,
                                  -CGFloat(Double.pi / 2))

        super.init(frame: frame)

        zoomLayer.frame = CGRect(origin: .zero, size: CGSize(width: progressRadius, height: progressRadius))
        zoomLayer.fillColor = normalCenterColor.cgColor
        zoomLayer.strokeColor = trackColor.cgColor
        zoomLayer.lineWidth = normalLineWidth
        zoomLayer.path = makeCircle(zoomLayer.innerCenter, normalRadius - normalLineWidth, 0).cgPath

        progressLayer.frame = zoomLayer.frame
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = progressLineWidth
        progressLayer.lineCap = .round
        progressLayer.path = makeCircle(progressLayer.innerCenter,
                                        progressRadius - progressLineWidth,
                                        -CGFloat(Double.pi / 2)).cgPath
        progressLayer.zPosition = zoomLayer.zPosition + 1
        progressLayer.isHidden = true
        layer.addSublayer(progressLayer)

        self.layer.addSublayer(zoomLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// zoom out
    fileprivate func scaleToProgress() {
        isProgressing = true
        scaleAnimation(from: normalAnimationStruct, toValue: progressAnimationStruct)
    }

    /// zoom in
    fileprivate func scaleToNarmal() {
        isProgressing = false
        scaleAnimation(from: progressAnimationStruct, toValue: normalAnimationStruct)
        progressLayer.removeAllAnimations()
        progressLayer.isHidden = true
    }

     /// zoom animation
    fileprivate func scaleAnimation(from: AnimationConfig, toValue: AnimationConfig) {
        let backgroundColorAnimation: CABasicAnimation = CABasicAnimation(keyPath: "fillColor")
        backgroundColorAnimation.fromValue = from.fillColor
        backgroundColorAnimation.toValue = toValue.fillColor

        let lineWidthAnimation: CABasicAnimation = CABasicAnimation(keyPath: "lineWidth")
        lineWidthAnimation.fromValue = from.lineWidth
        lineWidthAnimation.toValue = toValue.lineWidth

        let pathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = from.path
        pathAnimation.toValue = toValue.path

        let group = CAAnimationGroup()
        group.animations = [backgroundColorAnimation, lineWidthAnimation, pathAnimation]
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration = zoomDuration
        group.delegate = self
        zoomLayer.add(group, forKey: "zoom")
    }

    /// progress animation
    fileprivate func startProgress() {
        progressLayer.isHidden = false

        let pathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.fromValue = 0
        pathAnimation.toValue = 1
        pathAnimation.duration = maxDuration
        pathAnimation.delegate = self

        progressLayer.add(pathAnimation, forKey: "progress")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        zoomLayer.setCenter(innerCenter)
        progressLayer.setCenter(innerCenter)
    }

    private func frame(with radius: CGFloat) -> CGRect {
        let center = innerCenter
        var frame = CGRect.zero
        frame.origin = CGPoint(x: center.x - radius, y: center.y - radius)
        frame.size = CGSize(width: radius, height: radius)
        return frame
    }
}

extension CameraProgressView: CAAnimationDelegate {
    func animationDidStart(_ anim: CAAnimation) {
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag else { return }
        switch anim.duration {
        case zoomDuration:
            if isProgressing {
                startProgress()
            } else {
                zoomLayer.removeAllAnimations()
            }
        case maxDuration:
            richMaxDuration?(self)
        default:
            break
        }
    }
}

// MARK: CAShapeLayer Extension
fileprivate extension CAShapeLayer {
    var innerCenter: CGPoint {
        return CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }

    func setCenter(_ center: CGPoint) {
        let oldAnchor = self.anchorPoint
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        position = center
        anchorPoint = oldAnchor
    }
}
