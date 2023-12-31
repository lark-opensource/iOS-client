//
//  NextButton.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Lottie
import SnapKit
import ByteViewCommon
import ByteViewUI
import UniverseDesignTheme
import UniverseDesignColor

class NextButton: UIButton {

    enum Style {
        case blue
        case lightBlue
        case white
        case whiteWithBlueOutline
        case roundedRectBlue
        case roundedRectWhiteWithGrayOutline
    }

    private lazy var indicator: LOTAnimationView = {
        let indicator = LOTAnimationView(name: "button_loading", bundle: BundleConfig.ByteViewLiveCertBundle)
        indicator.backgroundColor = .clear
        indicator.isUserInteractionEnabled = false
        indicator.loopAnimation = true
        return indicator
    }()

    private var style: Style

    private lazy var titleField: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.isUserInteractionEnabled = false
        return label
    }()

    private var bgColorsToApply: [UIControl.State.RawValue: UIColor] = [:]

    var isLoading: Bool = false {
        didSet {
            guard isLoading != oldValue else { return }
            indicator.isHidden = !isLoading
            if isLoading {
                indicator.play()
                indicator.isHidden = false
                isEnabled = false
            } else {
                indicator.stop()
                indicator.isHidden = true
                isEnabled = true
            }
        }
    }

    var title: String {
        didSet {
            guard title != oldValue else { return }
            titleField.isHidden = title.isEmpty
            titleField.text = title
            titleField.sizeToFit()
        }
    }

    override var isEnabled: Bool {
        didSet {
            super.isEnabled = isEnabled
            setupStyle()
        }
    }

    init(title: String, style: Style = .roundedRectBlue) {
        self.title = title
        self.style = style
        super.init(frame: .zero)
        setUpBtn()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 初始化阶段 bounds 为 0 apply 会失败 layout 后再次尝试 apply
        applyBackgroundColor()
    }

    private func setupStyle() {
        switch style {
        case .blue:
            backgroundColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.primaryFillSolid03
            setInternalBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
            titleField.textColor = UIColor.ud.primaryOnPrimaryFill
            layer.cornerRadius = Layout.nextButtonHeight / 2
        case .lightBlue:
            backgroundColor = UIColor.ud.primaryFillSolid02
            layer.borderWidth = 1.0
            layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            titleField.textColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.primaryFillSolid03
            layer.cornerRadius = Layout.nextButtonHeight / 2
        case .white:
            backgroundColor = .white
            titleField.textColor = UIColor.ud.textPlaceholder
        case .whiteWithBlueOutline:
            backgroundColor = UIColor.ud.primaryOnPrimaryFill
            layer.borderWidth = 1.0
            layer.ud.setBorderColor(isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.primaryFillSolid03)
            titleField.textColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.primaryFillSolid03
            layer.cornerRadius = Layout.nextButtonHeight / 2
        case .roundedRectBlue:
            backgroundColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.fillDisabled
            self.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
            titleField.textColor = UIColor.ud.primaryOnPrimaryFill
            layer.cornerRadius = Layout.nextButtonRounedRectCorner
        case .roundedRectWhiteWithGrayOutline:
            backgroundColor = .white
            layer.borderWidth = 1.0
            layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            titleField.textColor = isEnabled ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder
            layer.cornerRadius = Layout.nextButtonRounedRectCorner
        }
    }

    private func setUpBtn() {

        setupStyle()

        let stack = UIStackView(arrangedSubviews: [indicator, titleField])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.spacing = Layout.nextButtonIndicatorSpacing
        stack.backgroundColor = .clear
        stack.isUserInteractionEnabled = false

        addSubview(stack)

        titleField.text = title
        titleField.sizeToFit()
        indicator.isHidden = true

        stack.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        indicator.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Layout.nextButtonIndicatorWidth,
                                     height: Layout.nextButtonIndicatorWidth))
        }
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        self.title = title ?? ""
    }

    func update(style: Style) {
        self.style = style
        setupStyle()
    }

    private func image(of color: UIColor, rect: CGRect) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        let render = UIGraphicsImageRenderer(bounds: rect, format: format)
        let image = render.image { context in
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fill(rect)
        }
        return image
    }

    private func setInternalBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        bgColorsToApply[state.rawValue] = color
        clipsToBounds = true
        applyBackgroundColor()
    }

    private func applyBackgroundColor() {
        guard !bgColorsToApply.isEmpty else {
            return
        }
        let bgColors = bgColorsToApply
        bgColors.forEach { (state, color) in
            if let image = image(of: color, rect: bounds) {
                setBackgroundImage(image, for: UIControl.State(rawValue: state))
                bgColorsToApply.removeValue(forKey: state)
            }
        }
    }

    struct Layout {
        static let nextButtonHeight: CGFloat = 50.0
        static let nextButtonHeight48: CGFloat = 48.0
        static let nextButtonIndicatorWidth: CGFloat = 21.0
        static let nextButtonIndicatorSpacing: CGFloat = 4.0
        static let nextButtonRounedRectCorner: CGFloat = 4.0
    }
}
