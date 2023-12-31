//
//  Checkbox.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2017/1/6.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public enum CheckboxType: CaseIterable {
    case circle
    case square

    /// 类似◎
    case concentric

    static var fillTyps: [CheckboxType] = [.concentric]
}

public enum AnimationType {
//    case stroke, fill, bounce, flat, oneStroke, fade
    case bounce
}

public protocol CheckboxDelegate: AnyObject {
    func didTapCheckbox(_ checkbox: Checkbox)
    func animationDidStopForCheckbox(_ checkbox: Checkbox)
}

open class Checkbox: UIControl {
    public weak var delegate: CheckboxDelegate?

    public private(set) var on: Bool = false

    public var lineWidth: CGFloat = 2.0 {
        didSet {
            self.pathManager.lineWidth = self.lineWidth
            self.reload()
        }
    }

    /// 当Type是concentric时内圆半径，默认：8
    public var innerCycloRadius: CGFloat = 8 {
        didSet {
            self.pathManager.innerCycloRadius = self.innerCycloRadius
            self.reload()
        }
    }

    public var animationDuration: CGFloat = 0.5 {
        didSet {
            self.animationManager.animationDuration = animationDuration
        }
    }

    public var hideBox: Bool = false
    public var onTintColor: UIColor = UIColor.ud.primaryContentDefault {
        didSet {
            self.reload()
        }
    }

    public var onFillColor: UIColor = .clear {
        didSet {
            self.reload()
        }
    }

    public var onCheckColor: UIColor = UIColor.ud.primaryContentDefault {
        didSet {
            self.reload()
        }
    }

    public var offFillColor: UIColor = .clear {
        didSet {
            self.reload()
        }
    }

    public var strokeColor: UIColor = .lightGray {
        didSet {
            self.drawOffBox()
        }
    }

    public var boxType: CheckboxType = .circle {
        didSet {
            self.pathManager.boxType = self.boxType
            self.reload()
        }
    }

    var onAnimationType: AnimationType = .bounce
    var offAnimationType: AnimationType = .bounce
    public var minTouchSize: CGSize = CGSize(width: 44, height: 44)

    fileprivate var onBoxLayer: CAShapeLayer?
    fileprivate var offBoxLayer: CAShapeLayer?
    fileprivate var checkMarkLayer: CAShapeLayer?

    private var animationManager: AnimationManager!
    private var pathManager: PathManager!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private var _prevBounds: CGRect?

    public override func layoutSubviews() {
        self.pathManager.size = self.bounds.height
        if self.bounds.width != self._prevBounds?.width || self.bounds.height != self._prevBounds?.height {
            self.drawOffBox()
        }
        _prevBounds = self.bounds
        super.layoutSubviews()
    }

    public override func draw(_ rect: CGRect) {
        self.setOn(on: self.on, animated: false)
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var found = super.point(inside: point, with: event)

        let minSize = self.minTouchSize
        let width = self.bounds.width
        let height = self.bounds.height
        if !found && (width < minSize.width || height < minSize.height) {
            let increaseWidth = minSize.width - width
            let increaseHeight = minSize.height - height

            let rect = self.bounds.insetBy(dx: -increaseWidth / 2, dy: -increaseHeight / 2)

            found = rect.contains(point)
        }

        return found
    }

    public override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                self.pathManager.size = frame.height
                self.drawOffBox()
            }
        }
    }

    func commonInit() {
        self.backgroundColor = UIColor.clear

        self.initPathManager()
        self.initAnimationManager()

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapCheckBox)))
    }

    func initPathManager() {
        self.pathManager = PathManager()
        self.pathManager.lineWidth = self.lineWidth
        self.pathManager.innerCycloRadius = self.innerCycloRadius
        self.pathManager.boxType = self.boxType
    }

    func initAnimationManager() {
        self.animationManager = AnimationManager(animationDuration: self.animationDuration)
    }

    @objc
    func handleTapCheckBox(recognizer: UITapGestureRecognizer) {
        self.setOn(on: !self.on, animated: true)
        self.delegate?.didTapCheckbox(self)
        self.sendActions(for: .valueChanged)
    }

    public func setOn(on: Bool, animated: Bool = false) {
        self.on = on

        self.drawEntireCheckBox()

        if on {
            if animated {
                self.addOnAnimation()
            }
        } else {
            if animated {
                self.addOffAnimation()
            } else {
                self.onBoxLayer?.removeFromSuperlayer()
                self.checkMarkLayer?.removeFromSuperlayer()
            }
        }
    }

    func addOnAnimation() {
        if self.animationDuration < 0.001 {
            return
        }

        switch self.onAnimationType {
        case .bounce:
            let amplitude = self.boxType == .square ? 0.20 : 0.35
            let wiggle = self.animationManager.fillAnimation(withBounces: 1, amplitude: CGFloat(amplitude), reverse: false)
            wiggle.delegate = self

            let opacity = self.animationManager.opacityAnimation(reverse: false)
            opacity.duration = CFTimeInterval(self.animationDuration / CGFloat(1.4))

            self.onBoxLayer?.add(opacity, forKey: "opacity")
            onBoxLayer?.opacity = 1.0
            self.checkMarkLayer?.add(wiggle, forKey: "transform")
            checkMarkLayer?.transform = CATransform3DMakeScale(1, 1, 1)
        }
    }

    func addOffAnimation() {
        if self.animationDuration < 0.001 {
            self.onBoxLayer?.removeFromSuperlayer()
            self.checkMarkLayer?.removeFromSuperlayer()
            return
        }

        switch self.offAnimationType {
        case .bounce:
            let amplitude = self.boxType == .square ? 0.20 : 0.35
            let wiggle = self.animationManager.fillAnimation(withBounces: 1, amplitude: CGFloat(amplitude), reverse: true)
            wiggle.duration = CFTimeInterval(self.animationDuration / CGFloat(1.1))

            let opacity = self.animationManager.opacityAnimation(reverse: true)
            opacity.delegate = self

            self.onBoxLayer?.add(opacity, forKey: "opacity")
            onBoxLayer?.opacity = 0.0
            self.checkMarkLayer?.add(wiggle, forKey: "transform")
            checkMarkLayer?.transform = CATransform3DMakeScale(0, 0, 0)
        }
    }

    func drawEntireCheckBox() {
        if !self.hideBox {
            if self.offBoxLayer == nil || (self.offBoxLayer!.path?.boundingBox.height ?? 0) <= CGFloat(0.001) {
                self.drawOffBox()
            }
            if self.on {
                self.drawOnBox()
            }
        }

        if self.on {
            self.drawCheckMark()
        }
    }

    func drawOffBox() {
        self.offBoxLayer?.removeFromSuperlayer()
        self.offBoxLayer = CAShapeLayer()
        self.offBoxLayer?.frame = self.bounds
        let path = self.pathManager.pathForBox()
        self.offBoxLayer?.path = path.cgPath
        self.offBoxLayer?.fillColor = self.offFillColor.resolvedCompatibleColor(with: traitCollection).cgColor
        self.offBoxLayer?.strokeColor = self.strokeColor.resolvedCompatibleColor(with: traitCollection).cgColor
        self.offBoxLayer?.lineWidth = self.lineWidth

        self.layer.addSublayer(self.offBoxLayer!)
    }

    func drawOnBox() {
        self.onBoxLayer?.removeFromSuperlayer()

        self.onBoxLayer = CAShapeLayer()
        self.onBoxLayer?.frame = self.bounds
        self.onBoxLayer?.path = self.pathManager.pathForBox().cgPath
        self.onBoxLayer?.lineWidth = self.lineWidth
        self.onBoxLayer?.fillColor = self.onFillColor.resolvedCompatibleColor(with: traitCollection).cgColor
        self.onBoxLayer?.strokeColor = self.onTintColor.resolvedCompatibleColor(with: traitCollection).cgColor

        self.layer.addSublayer(self.onBoxLayer!)
    }

    func drawCheckMark() {
        let fillColor = CheckboxType.fillTyps.contains(boxType) ? self.onCheckColor : UIColor.clear
        self.checkMarkLayer?.removeFromSuperlayer()
        self.checkMarkLayer = CAShapeLayer()
        self.checkMarkLayer?.frame = self.bounds
        self.checkMarkLayer?.path = self.pathManager.pathForCheckMark().cgPath
        self.checkMarkLayer?.strokeColor = self.onCheckColor.resolvedCompatibleColor(with: traitCollection).cgColor
        self.checkMarkLayer?.lineWidth = self.lineWidth
        self.checkMarkLayer?.fillColor = fillColor.resolvedCompatibleColor(with: traitCollection).cgColor
        self.checkMarkLayer?.lineCap = .round
        self.checkMarkLayer?.lineJoin = .round
        self.layer.addSublayer(self.checkMarkLayer!)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.offBoxLayer?.removeFromSuperlayer()
                self.offBoxLayer = nil
                self.setOn(on: self.on, animated: false)
            }
        }
    }

    func reload() {
        self.offBoxLayer?.removeFromSuperlayer()
        self.offBoxLayer = nil

        self.onBoxLayer?.removeFromSuperlayer()
        self.offBoxLayer = nil

        self.checkMarkLayer?.removeFromSuperlayer()
        self.checkMarkLayer = nil

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

extension Checkbox: CAAnimationDelegate {
    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            if !self.on {
                self.onBoxLayer?.removeFromSuperlayer()
                self.checkMarkLayer?.removeFromSuperlayer()
            }

            self.delegate?.animationDidStopForCheckbox(self)
        }
    }
}
