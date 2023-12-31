//
//  FloatingLabel.swift
//  floatingAccount
//
//  Created by ByteDance on 2022/7/21.
//

import Foundation
import UIKit

// Label的方式
enum FloatingPolicy {
    case floating
    case cut
    case ellision
}

class FloatingLabel: UIView {
    private lazy var nameLabel = UILabel()
    private lazy var labelMask = UIImageView()
    private var animationOnPlaying: Bool = false
    private lazy var copyLabel: UILabel = UILabel()
    private lazy var copyMask = UIImageView()
    private let colorSpace: CGColorSpace = .init(name: CGColorSpace.sRGB)!
    private var useAnimationDuration: Bool = true
    // 动画持续长度
    var animationDuration: Double = 6.0 {
        didSet {
            useAnimationDuration = true
        }
    }
    // 动画播放速度
    var animationSpd: Double = 10.0 {
        didSet {
            useAnimationDuration = false
        }
    }
    // 文字滚动时，前后两个文本之间的距离
    var loggingDist: Float = 20 {
        didSet {
            updateLabel()
        }
    }
    // 文本在到达左侧时停顿的时间
    var waitInterval: Double = 0.5 {
        didSet {
            updateLabel()
        }
    }
    //为true时为相对长度，为false时为绝对长度
    private var useRelativeShadow: Bool = true
    // 两侧阴影相对文本的长度
    var shadowRelativeLength: Float = 0.1 {
        didSet {
            useRelativeShadow = true
            updateLabel()
        }
    }
    //两侧阴影的绝对长度
    var shadowLength: Float = 1 {
        didSet {
            useRelativeShadow = false
            updateLabel()
        }
    }
    // 显示策略
    var policy: FloatingPolicy = .floating {
        didSet {
            updateLabel()
        }
    }
    override var bounds: CGRect {
        didSet {
            updateLabel()
        }
    }
    // 文本内容
    var text: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
            if animationOnPlaying {
                copyLabel.text = newValue
            }
            updateLabel()
        }
    }
    var attributedText: NSAttributedString? {
        get {
            return nameLabel.attributedText
        }
        set {
            nameLabel.attributedText = newValue
            if animationOnPlaying {
                copyLabel.attributedText = newValue
            }
            updateLabel()
        }
    }

    // 文本颜色
    var textColor: UIColor? {
        get {
            return nameLabel.textColor
        }
        set {
            nameLabel.textColor = newValue
            if animationOnPlaying {
                copyLabel.textColor = newValue
            }
        }
    }
    var font: UIFont? {
        get {
            return nameLabel.font
        }
        set {
            nameLabel.font = newValue
            if animationOnPlaying {
                copyLabel.font = newValue
            }
            updateLabel()
        }
    }
    var textAlignment: NSTextAlignment {
        get {
            return nameLabel.textAlignment
        }
        set {
            nameLabel.textAlignment = newValue
            if animationOnPlaying {
                copyLabel.textAlignment = newValue
            }
            updateLabel()
        }
    }
    init(frame f: CGRect, textColor tc: UIColor, animationDuration duration: Double, loggingDist: Float,
         waitInterval: Double, shadowLength: Float, policy: FloatingPolicy) {
        super.init(frame: f)
        self.labelMask.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height)
        self.animationDuration = duration
        self.loggingDist = loggingDist
        self.waitInterval = waitInterval
        self.shadowRelativeLength = shadowLength
        self.policy = policy
        self.shared_init(frame: f)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.shared_init(frame: frame)
    }
    init() {
        super.init(frame: .zero)
        self.shared_init(frame: .zero)
    }
    private var testFrame: CGRect = CGRect()
    private func shared_init(frame: CGRect) {
        self.labelMask.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        self.addSubview(nameLabel)
        self.nameLabel.textAlignment = .left
        self.nameLabel.lineBreakMode = .byTruncatingHead
        self.nameLabel.adjustsFontSizeToFitWidth = true
        self.nameLabel.minimumScaleFactor = 0.8
        self.nameLabel.layer.backgroundColor = .init(colorSpace: colorSpace, components: [0, 0, 0, 0])
        self.labelMask.layer.backgroundColor = .init(colorSpace: colorSpace, components: [0, 0, 0, 0])
        self.nameLabel.mask = self.labelMask
        self.nameLabel.adjustsFontSizeToFitWidth = true
        self.testFrame = self.nameLabel.frame
    }
    private func generateMaskLayer(width w: Int, hegiht h: Int) -> CAGradientLayer {
        let maskLayer = CAGradientLayer()
        var currentSRL: Float = shadowRelativeLength
        if !useRelativeShadow && frame.width != 0 {
            currentSRL = shadowLength / Float(frame.width)
        }
        maskLayer.colors = [
            CGColor(colorSpace: colorSpace, components: [0, 0, 0, 0]),
            CGColor(colorSpace: colorSpace, components: [0, 0, 0, 1]),
            CGColor(colorSpace: colorSpace, components: [0, 0, 0, 1]),
            CGColor(colorSpace: colorSpace, components: [0, 0, 0, 0])
        ].compactMap({ $0 })
        maskLayer.locations = [
            0,
            NSNumber(value: currentSRL),
            NSNumber(value: 1 - currentSRL)
        ]
        maskLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        maskLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: w,
            height: h
        )
        return maskLayer
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    //此处async用于修复由悬浮窗切换至全屏时字幕疯狂滚动的问题，如无其他解决方案请勿改动
    private func updateLabel() {
        if text == nil {
            return
        }
        DispatchQueue.main.async {
            self.updateLabelAction()
        }
    }
    private func updateLabelAction() {
        let textLength = calTextLength()
        var currentSRL: Float = shadowRelativeLength
        if !useRelativeShadow && frame.width != 0 {
            currentSRL = shadowLength / Float(frame.width)
        }
        nameLabel.transform = .identity
        nameLabel.layer.backgroundColor = .init(colorSpace: colorSpace, components: [0, 0, 0, 0])
        switch policy {
        case .floating:
            nameLabel.frame = CGRect(
                x: 0,
                y: 0,
                width: Int(textLength + 1),
                height: Int(frame.height)
            )
        case .cut:
            nameLabel.frame = CGRect(
                x: 0,
                y: 0,
                width: max(Int(textLength + 1), Int(frame.width)),
                height: Int(frame.height)
            )
        case .ellision:
            nameLabel.frame = CGRect(
                x: 0,
                y: 0,
                width: Int(frame.width),
                height: Int(frame.height)
            )
        }
        labelMask.transform = .identity
        labelMask.frame = CGRect(
            x: 0,
            y: 0,
            width: Int(frame.width),
            height: Int(frame.height)
        )
        if textLength > Float(frame.width) && policy == .floating && frame.width > 0 {
            nameLabel.textAlignment = .left
            if animationOnPlaying {
                copyLabel.textAlignment = .left
            }
        }
        if nameLabel.textAlignment == .center {
            nameLabel.frame = CGRect(
                x: -nameLabel.frame.width / 2 + frame.width / 2,
                y: 0,
                width: nameLabel.frame.width,
                height: nameLabel.frame.height
            )
            labelMask.frame = CGRect(
                x: nameLabel.frame.width / 2 - frame.width / 2,
                y: 0,
                width: frame.width,
                height: frame.height
            )
        }
        labelMask.backgroundColor = .init(white: 0, alpha: 0)
        if let sublayers = labelMask.layer.sublayers {
            sublayers[0].removeFromSuperlayer()
            labelMask.layer.addSublayer(generateMaskLayer(width: Int(frame.width), hegiht: Int(frame.height)))
        } else {
            labelMask.layer.addSublayer(generateMaskLayer(width: Int(frame.width), hegiht: Int(frame.height)))
        }
        if textLength < Float(frame.width) || policy != .floating {
            copyLabel.text = ""
            if let sublayers = labelMask.layer.sublayers, let gradientLayer = sublayers[0] as? CAGradientLayer {
                gradientLayer.locations = [
                    0,
                    NSNumber(value: currentSRL),
                    1
                ]
            }
        }
        if animationOnPlaying {
            stopAnimation()
        } else if textLength > Float(frame.width) {
            addSubview(copyLabel)
            copyLabel.mask = copyMask
            copyMask.layer.backgroundColor = .init(colorSpace: colorSpace, components: [0, 0, 0, 0])
        }
        // labelMask在不同政策下的显示不同
        if policy != .floating {
            if let sublayers = labelMask.layer.sublayers {
                sublayers[0].removeFromSuperlayer()
                labelMask.backgroundColor = .init(white: 0, alpha: 1)
            }
        }
        if textLength > Float(frame.width) && policy == .floating {
            updateCopy()
            startAnimation()
        }
    }
    // 计算文字本身的长度
    private func calTextLength() -> Float {
        if text == nil {
            return 0
        }
        return Float(self.nameLabel.intrinsicContentSize.width)
    }
    // 开始动画
    func startAnimation() {
        if animationOnPlaying {
            return
        }
        var currentSRL: Float = shadowRelativeLength
        if !useRelativeShadow && frame.width != 0 {
            currentSRL = shadowLength / Float(frame.width)
        }
        let textLength = Int(calTextLength())
        var duration: Double = animationDuration
        if !useAnimationDuration {
            duration = Double(textLength) / animationSpd
        }
        let forwardLength = textLength + Int(loggingDist)
        let relativeAnime = duration / (duration + waitInterval)
        let relativeInt = waitInterval / (duration + waitInterval)
        let animationOptions: UIView.AnimationOptions = .curveLinear
        let keyframeAnimationOptions: UIView.KeyframeAnimationOptions = UIView.KeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        UIView.animateKeyframes(withDuration: duration + waitInterval, delay: waitInterval, options: [.repeat, keyframeAnimationOptions]) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: relativeAnime) {
                self.nameLabel.transform = CGAffineTransform(translationX: CGFloat(-forwardLength), y: 0)
                self.labelMask.transform = CGAffineTransform(translationX: CGFloat(forwardLength), y: 0)
                self.copyLabel.transform = CGAffineTransform(translationX: CGFloat(0), y: 0)
                self.copyMask.transform = CGAffineTransform(translationX: CGFloat(0), y: 0)
            }
            UIView.addKeyframe(withRelativeStartTime: relativeAnime, relativeDuration: 0) {
                if let sublayers = self.copyMask.layer.sublayers, let gradientLayer = sublayers[0] as? CAGradientLayer {
                    gradientLayer.locations = [
                        0,
                        NSNumber(value: currentSRL),
                        1
                    ]
                }
            }
            UIView.addKeyframe(withRelativeStartTime: relativeAnime, relativeDuration: relativeInt) {
            }
        }
        animationOnPlaying = true
    }
    // 制作复制label
    private func copyFromNameLabel(toCopy label: UILabel) {
        label.frame = nameLabel.frame
        label.text = nameLabel.text
        label.attributedText = nameLabel.attributedText
        label.textAlignment = nameLabel.textAlignment
        label.textColor = nameLabel.textColor
        label.font = nameLabel.font
        label.contentScaleFactor = nameLabel.contentScaleFactor
        label.layer.backgroundColor = nameLabel.layer.backgroundColor
        label.adjustsFontSizeToFitWidth = nameLabel.adjustsFontSizeToFitWidth
        label.minimumScaleFactor = nameLabel.minimumScaleFactor
        label.lineBreakMode = nameLabel.lineBreakMode
    }
    // 更新复制label
    private func updateCopy() {
        let textLength = Int(calTextLength())
        copyFromNameLabel(toCopy: copyLabel)
        copyLabel.transform = CGAffineTransform(
            translationX: CGFloat(textLength + Int(loggingDist)),
            y: 0
        )
        copyMask.frame = labelMask.frame
        copyMask.transform = CGAffineTransform(translationX: CGFloat(-textLength - Int(loggingDist)), y: 0)
        if let sublayers = copyMask.layer.sublayers {
            sublayers[0].removeFromSuperlayer()
            copyMask.layer.addSublayer(generateMaskLayer(width: Int(frame.width), hegiht: Int(frame.height)))
        } else {
            copyMask.layer.addSublayer(generateMaskLayer(width: Int(frame.width), hegiht: Int(frame.height)))
        }
    }
    // 停止全部动画
    private func stopAnimation() {
        nameLabel.layer.removeAllAnimations()
        labelMask.layer.removeAllAnimations()
        copyLabel.layer.removeAllAnimations()
        copyMask.layer.removeAllAnimations()
        animationOnPlaying = false
    }
}
