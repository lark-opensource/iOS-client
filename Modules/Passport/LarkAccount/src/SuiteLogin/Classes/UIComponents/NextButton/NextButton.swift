//
//  NextButton.swift
//  SuiteLogin
//
//  Created by lixiaorui on 2019/9/20.
//

import UIKit
import Lottie
import SnapKit
import RxSwift
import UniverseDesignColor

class NextButton: UIButton {

    public enum Style {
        case blue
        case lightBlue
        case white
        case whiteWithBlueOutline
        case roundedRectBlue
        case roundedRectRed
        case roundedRectWhiteWithGrayOutline
    }

    private lazy var indicator: LOTAnimationView = {
        // swiftlint:disable ForceUnwrapping
        let indicator = LOTAnimationView(filePath: BundleConfig.LarkAccountBundle.path(forResource: "data", ofType: "json", inDirectory: "Lottie/button_loading")!)
        // swiftlint:enable ForceUnwrapping

        indicator.backgroundColor = .clear
        indicator.isUserInteractionEnabled = false
        indicator.loopAnimation = true
        return indicator
    }()

    private var style: Style

    private lazy var titleField: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 17)
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private var bgColorsToApply: [UIControl.State.RawValue: UIColor] = [:]

    public var isLoading: Bool = false {
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

    public var title: String {
        didSet {
            guard title != oldValue else { return }
            titleField.isHidden = title.isEmpty
            titleField.text = title
        }
    }

    public override var isEnabled: Bool {
        didSet {
            super.isEnabled = isEnabled
            updateUI()
        }
    }

    public init(title: String, style: Style = .roundedRectBlue) {
        self.title = title
        self.style = style
        super.init(frame: .zero)
        setUpBtn()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 初始化阶段 bounds 为 0 apply 会失败 layout 后再次尝试 apply
        applyBackgroundColor()
    }

    private func setupStyle() {
        switch style {
        case .blue:
            setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
            titleField.textColor = .white
            layer.cornerRadius = Layout.nextButtonHeight48 / 2
        case .lightBlue:
            backgroundColor = UIColor.ud.primaryFillSolid02
            layer.borderWidth = 1.0
            layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            layer.cornerRadius = Layout.nextButtonHeight48 / 2
        case .white:
            backgroundColor = UIColor.ud.bgLogin
            titleField.textColor = UIColor.ud.textPlaceholder
        case .whiteWithBlueOutline:
            backgroundColor = .white
            layer.borderWidth = 1.0
            layer.cornerRadius = Layout.nextButtonHeight48 / 2
        case .roundedRectBlue:
            setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
            layer.cornerRadius = Layout.nextButtonRounedRectCorner
        case .roundedRectRed:
            setBackgroundColor(UIColor.ud.functionDanger600, for: .highlighted)
            layer.cornerRadius = Layout.nextButtonRounedRectCorner
        case .roundedRectWhiteWithGrayOutline:
            backgroundColor = .clear
            setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
            layer.borderWidth = 1.0
            layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            layer.cornerRadius = Layout.nextButtonRounedRectCorner
        }
        
        updateUI()
    }
    
    private func updateUI() {
        switch style {
        case .blue:
            backgroundColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.primaryFillSolid03
        case .lightBlue:
            titleField.textColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.primaryFillSolid03
        case .white: break
        case .whiteWithBlueOutline:
            layer.ud.setBorderColor(isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled)
            titleField.textColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled
        case .roundedRectBlue:
            backgroundColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.fillDisabled
            titleField.textColor = isEnabled ? .white : UIColor.ud.udtokenBtnPriTextDisabled
        case .roundedRectRed:
            backgroundColor = isEnabled ? UIColor.ud.functionDanger500 : UIColor.ud.fillDisabled
            titleField.textColor = UIColor.ud.staticWhite
        case .roundedRectWhiteWithGrayOutline:
            titleField.textColor = isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
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
        indicator.isHidden = true
        
        let wrapper = UIStackView(arrangedSubviews: [stack])
        wrapper.axis = .vertical
        wrapper.alignment = .center
        wrapper.isUserInteractionEnabled = false

        addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: Layout.nextButtonVerticalInset,
                                                             left: Layout.nextButtonHorizontalInset,
                                                             bottom: Layout.nextButtonVerticalInset,
                                                             right: Layout.nextButtonHorizontalInset))
        }

        indicator.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Layout.nextButtonIndicatorWidth,
                                     height: Layout.nextButtonIndicatorWidth))
        }
    }

    override public func setTitle(_ title: String?, for state: UIControl.State) {
        self.title = title ?? ""
    }

    func update(style: Style) {
        self.style = style
        setupStyle()
    }

    // 在 iOS 15.0 上频繁创建图片可能导致 crash：https://bits.bytedance.net/meego/larksuite/issue/detail/2642577?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
    private func image(of color: UIColor, rect: CGRect) -> UIImage? {
        UIGraphicsImageRenderer(size: rect.size).image { context in
            color.setFill()
            context.fill(rect)
        }
    }

    private func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
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

    func resetFont() {
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17)
    }

    struct Layout {
        static let nextButtonHeight48: CGFloat = 48.0
        static let nextButtonIndicatorWidth: CGFloat = 21.0
        static let nextButtonIndicatorSpacing: CGFloat = 4.0
        static let nextButtonRounedRectCorner: CGFloat = Common.Layer.commonButtonRadius
        static let nextButtonVerticalInset: CGFloat = 12.0
        static let nextButtonHorizontalInset: CGFloat = 16.0
    }
}
