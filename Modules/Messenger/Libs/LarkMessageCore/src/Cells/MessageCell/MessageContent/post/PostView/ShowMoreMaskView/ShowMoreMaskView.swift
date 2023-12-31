//
//  ShowMoreMaskView.swift
//  LarkThread
//
//  Created by qihongye on 2019/3/5.
//

import UIKit
import Foundation
import LarkInteraction
import UniverseDesignTheme
import UniverseDesignColor

public final class ShowMoreButton: UIControl {
    static var labelFont: UIFont { UIFont.ud.body2 }
    static var labelText: String { BundleI18n.LarkMessageCore.Lark_Legacy_ChatShowMore }
    static let hPadding: CGFloat = 12
    static let vPadding: CGFloat = 8
    public static var caculatedSize: CGSize {
        let labelWidth = max(labelText.lu.width(font: labelFont), 72.auto())
        let labelHeight = labelFont.rowHeight
        let size = CGSize(width: labelWidth + hPadding * 2, height: labelHeight + vPadding * 2)
        return size
    }

    public override var frame: CGRect {
        didSet {
            titleLabel.frame = bounds
            shadowView.frame = bounds
            shapeView.frame = bounds

            let shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 73)

            shadowLayer.shadowPath = shadowPath.cgPath
            shadowLayer.bounds = shadowView.bounds
            shadowLayer.position = shadowView.center

            let mask = CAShapeLayer()
            mask.path = shadowPath.cgPath
            shapeView.layer.mask = mask
        }
    }

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = ShowMoreButton.labelText
        label.font = ShowMoreButton.labelFont
        label.textAlignment = .center
        return label
    }()

    // 用于绘制阴影
    private var shadowView = UIView()
    private var shadowLayer = CALayer()

    // 用于切割圆角
    private var shapeView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(shadowView)
        shadowView.clipsToBounds = false
        shadowView.isUserInteractionEnabled = false

        shadowView.layer.addSublayer(shadowLayer)
        shadowLayer.shadowColor = UIColor.ud.shadowDefaultMd.cgColor
        shadowLayer.shadowOpacity = 1
        shadowLayer.shadowRadius = 10
        shadowLayer.shadowOffset = CGSize(width: 0, height: 5)

        addSubview(shapeView)
        shapeView.clipsToBounds = true
        shapeView.isUserInteractionEnabled = false

        shapeView.layer.backgroundColor = (UIColor.ud.bgFloat & UIColor.ud.bgFloatOverlay).cgColor

        addSubview(titleLabel)

        self.addPointer(
            .init(
                effect: .lift,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (size, size.height / 2)
                }
            )
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        shadowLayer.shadowColor = UIColor.ud.shadowDefaultMd.cgColor
        shapeView.layer.backgroundColor = (UIColor.ud.bgFloat & UIColor.ud.bgFloatOverlay).cgColor
    }
}

public final class ShowMoreMaskView: UIView {

    private var colors: [UIColor] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }()

    public func setBackground(colors: [UIColor]) {
        self.colors = colors
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        self.setBackgroundColors()
        CATransaction.commit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        gradientLayer.frame = bounds
        self.setBackgroundColors()
        CATransaction.commit()
    }

    private func setBackgroundColors() {
        gradientLayer.isHidden = colors.count < 2
        switch colors.count {
        case 1:
            backgroundColor = colors.first
        case 2...:
            backgroundColor = nil
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.locations = colors.enumerated().map { NSNumber(value: Float($0.offset) / Float(colors.count - 1)) }
        default:
            backgroundColor = UIColor.clear
        }
    }
}

public final class ShowMoreButtonMaskView: UIView {
    static var maskHeight: CGFloat {
        return ShowMoreButton.caculatedSize.height + 28
    }

    private var colors: [UIColor] = []
    public var showMoreHandler: (() -> Void)?

    lazy var showMoreButton: ShowMoreButton = {
        let button = ShowMoreButton(frame: .zero)
        button.addTarget(self, action: #selector(showMoreButtonTapped), for: .touchUpInside)
        return button
    }()

    public override var frame: CGRect {
        didSet {
            var buttonFrame = CGRect(origin: .zero, size: ShowMoreButton.caculatedSize)
            buttonFrame.center = bounds.center
            showMoreButton.frame = buttonFrame
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.addSubview(showMoreButton)
        showMoreButton.sizeToFit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }()

    public func setBackground(colors: [UIColor]) {
        self.colors = colors
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        self.setBackgroundColors()
        CATransaction.commit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        gradientLayer.frame = bounds
        self.setBackgroundColors()
        CATransaction.commit()
    }

    private func setBackgroundColors() {
        gradientLayer.isHidden = colors.count < 2
        switch colors.count {
        case 1:
            backgroundColor = colors.first
        case 2...:
            backgroundColor = nil
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.locations = colors.enumerated().map { NSNumber(value: Float($0.offset) / Float(colors.count - 1)) }
        default:
            backgroundColor = UIColor.clear
        }
    }

    @objc
    func showMoreButtonTapped() {
        self.showMoreHandler?()
    }
}
