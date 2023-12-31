//
//  GuideView.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/11/13.
//

import UIKit
import UniverseDesignColor
import ByteViewCommon
import SnapKit
import UniverseDesignShadow
import Lottie

public enum GuideStyle {
    case plain(content: String, title: String? = nil)
    /// 浅色的Onboarding样式，例：纪要Onboarding
    case lightOnboarding(content: String, title: String? = nil)
    /// GuideView的样式与.plain一致，显示时外部额外添加了蒙层，且仅点击referenceView才执行sureAction
    case focusPlain(content: String)
    case darkPlain(content: String)
    /// 浅色的Tips样式，例：纪要NewAgendaHint；展示起来上面小，下面大；title最多1行，content最多2行，整体宽度最大320
    case stressedPlain(content: String, title: String)
    case operable(contents: [String], index: Int)
    case alert(content: String, title: String? = nil, config: String? = nil)
    case alertWithAnimation(content: String, title: String, animationName: String)
}

public typealias GuideDirection = TriangleView.Direction

extension GuideView {
    enum Layout {
        static var arrowWidth: CGFloat = 10
        static var arrowLength: CGFloat = 24
        static let horizontalEdgeOffset: CGFloat = 4.0
        static let specializedHorizontalEdgeOffset: CGFloat = 8.0
    }
}

public final class GuideView: UIView {

    public var cleanupAction: (() -> Void)?

    public private(set) lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgPricolor
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// stressedPlain样式下左侧显示的竖线
    private let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.I200
        view.layer.cornerRadius = 1.0
        view.layer.masksToBounds = true
        return view
    }()

    /// lightOnboarding样式下左上角显示的icon
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIDependencyManager.dependency?.imageByKey("StatusFlashOfInspiration")
        return imageView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .center
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var operationView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var indicatorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .vertical)
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        return label
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        button.vc.setBackgroundColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8), for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 11, bottom: 8, right: 11)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_SkipButton, for: .normal)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.75), for: .normal)
        button.layer.cornerRadius = 6
        return button
    }()

    private lazy var innerArrowView: TriangleView = {
        let view = TriangleView()
        view.color = UIColor.ud.bgPricolor
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var arrowView: TriangleView = {
        let view = TriangleView()
        view.color = UIColor.ud.bgPricolor
        view.backgroundColor = UIColor.clear
        view.layer.ud.setShadow(type: .s4Down)
        return view
    }()

    private lazy var animationContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.primaryOnPrimaryFill
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    private lazy var animationView: LOTAnimationView = {
        let view = LOTAnimationView(name: "", bundle: .localResources)
        return view
    }()

    private var style: GuideStyle = .plain(content: "") {
        didSet {
            updateContent()
        }
    }

    private weak var referenceView: UIView?
    public var sureAction: ((GuideStyle) -> Void)?
    public var skipAction: ((GuideStyle) -> Void)?
    private var distance: CGFloat = 0

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        DispatchQueue.main.async {
            self.updateMaskLayer()
        }
    }

    public func sure() {
        sureAction?(style)
    }

    private func initialize() {
        backgroundColor = UIColor.clear

        addSubview(contentView)
        contentView.addSubview(lineView)
        contentView.addSubview(iconView)
        contentView.addSubview(stackView)
        animationContainerView.addSubview(animationView)
        stackView.addArrangedSubview(animationContainerView)
        stackView.setCustomSpacing(20, after: animationContainerView)
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(operationView)
        operationView.addSubview(indicatorLabel)
        operationView.addSubview(nextButton)
        operationView.addSubview(skipButton)
        addSubview(arrowView)
        addSubview(innerArrowView)

        lineView.snp.remakeConstraints {
            $0.left.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
            $0.width.equalTo(2)
        }

        iconView.snp.remakeConstraints {
            $0.left.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(14)
            $0.size.equalTo(22)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.top.left.right.equalToSuperview()
        }

        stackView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview().inset(16)
        }

        operationView.snp.remakeConstraints { (make) in
            make.height.equalTo(36)
        }

        indicatorLabel.snp.remakeConstraints { (make) in
            make.left.centerY.equalToSuperview()
        }

        skipButton.snp.remakeConstraints { (make) in
            make.left.greaterThanOrEqualTo(indicatorLabel.snp.right).offset(8)
            make.top.bottom.equalTo(nextButton)
        }

        nextButton.snp.remakeConstraints { (make) in
            make.left.equalTo(skipButton.snp.right).offset(8)
            make.right.top.equalToSuperview()
            make.width.equalTo(80)
            make.bottom.equalToSuperview()
        }

        style = { style }()
        skipButton.addTarget(self, action: #selector(didClickSkip(_:)), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didClickNext(_:)), for: .touchUpInside)
    }

    @objc private func didClickSkip(_ sender: UIButton) {
        self.skipAction?(self.style)
    }

    @objc private func didClickNext(_ sender: UIButton) {
        switch self.style {
        case .plain, .lightOnboarding, .darkPlain, .focusPlain, .stressedPlain:
            break
        case .alert, .alertWithAnimation:
            self.sure()
        case let .operable(contents, index: index):
            self.sure()
            let count = contents.count
            let isLast = (index == count - 1)
            if !isLast {
                self.style = .operable(contents: contents, index: index + 1)
            }
        }
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTestView = super.hitTest(point, with: event)
        switch style {
        case .plain, .lightOnboarding, .darkPlain, .stressedPlain:
            if hitTestView != nil {
                sure()
            }
            return nil
        case .focusPlain:
            if let rv = self.referenceView, let hv = hitTestView, rv.bounds.contains(hv.convert(point, to: rv)) {
                sure()
                return hitTestView
            } else {
                return UIView() // 阻断点击
            }
        case .operable, .alert, .alertWithAnimation:
            return hitTestView
        }
    }

    private func updateLayoutForAlert() {
        isHidden = false
        animationContainerView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(230)
        }

        animationView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(18)
            make.left.right.equalToSuperview().inset(12)
        }

        titleLabel.snp.remakeConstraints { (make) in
            make.height.equalTo(28)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(20)
        }

        label.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(20)
        }

        operationView.snp.remakeConstraints { (make) in
            make.height.equalTo(48)
            make.left.right.equalToSuperview()
        }

        nextButton.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }

        contentView.snp.remakeConstraints { make in
            make.width.equalTo(300)
            make.center.equalToSuperview()
        }
    }

    // nolint: long_function
    public func updateLayout(referenceView: UIView?, distance: CGFloat? = nil, arrowDirection: TriangleView.Direction? = nil) {
        if case .alertWithAnimation = style {
            self.updateLayoutForAlert()
            return
        }
        if let referenceView = referenceView, referenceView.superview != nil, superview != nil {
            isHidden = false
            let maxWidth: CGFloat = {
                switch style {
                case .lightOnboarding: return 288
                case .darkPlain, .stressedPlain: return 320
                default: return 300
                }
            }()
            let minWidth: CGFloat = {
                switch style {
                case .stressedPlain: return 160
                default: return 0
                }
            }()
            let arrowDistance = distance ?? self.distance
            self.distance = arrowDistance
            if let arrowDirection = arrowDirection {
                arrowView.direction = arrowDirection
                innerArrowView.direction = arrowDirection
            }
            titleLabel.snp.remakeConstraints {
                if case .stressedPlain = style {
                    $0.height.equalTo(18)
                } else {
                    $0.height.equalTo(28)
                }
            }
            label.snp.remakeConstraints { _ in }
            if !operationView.isHidden {
                operationView.snp.remakeConstraints { (make) in
                    make.height.equalTo(36)
                    make.left.right.equalToSuperview()
                }
            }
            if !nextButton.isHidden {
                nextButton.snp.remakeConstraints { make in
                    make.left.equalTo(skipButton.snp.right).offset(8)
                    make.right.top.equalToSuperview()
                    make.width.equalTo(80)
                    make.bottom.equalToSuperview()
                }
            }

            let horizontalEdgeOffset: CGFloat = {
                switch style {
                case .lightOnboarding, .stressedPlain: return Layout.specializedHorizontalEdgeOffset
                default: return Layout.horizontalEdgeOffset
                }
            }()

            let arrowLength: CGFloat
            let arrowWidth: CGFloat
            let verticalOffset: CGFloat
            switch style {
            case .darkPlain:
                arrowLength = 16
                arrowWidth = 6
                verticalOffset = 0
            default:
                arrowLength = Layout.arrowLength
                arrowWidth = Layout.arrowWidth
                verticalOffset = 1
            }
            switch arrowView.direction {
            case .top:
                contentView.snp.remakeConstraints { (make) in
                    make.centerX.equalTo(referenceView).priority(.lower)
                    make.right.lessThanOrEqualToSuperview().inset(horizontalEdgeOffset)
                    make.left.greaterThanOrEqualToSuperview().inset(horizontalEdgeOffset)
                    // TODO: 去掉 innerArrowView 后删除 offset 逻辑，下同
                    make.bottom.equalTo(arrowView.snp.top).offset(verticalOffset)
                    make.width.lessThanOrEqualTo(maxWidth)
                    make.width.greaterThanOrEqualTo(minWidth)
                }
                arrowView.snp.remakeConstraints { (make) in
                    make.width.equalTo(arrowLength)
                    make.height.equalTo(arrowWidth)
                    make.bottom.equalTo(referenceView.snp.top).offset(-arrowDistance)
                    make.centerX.equalTo(referenceView)
                }
                innerArrowView.snp.remakeConstraints {
                    $0.width.equalTo(arrowLength - 2)
                    $0.height.equalTo(arrowWidth - 1)
                    $0.bottom.equalTo(arrowView.snp.bottom).offset(-2)
                    $0.centerX.equalTo(arrowView)
                }
            case .bottom:
                contentView.snp.remakeConstraints { (make) in
                    make.centerX.equalTo(referenceView).priority(.lower)
                    make.right.lessThanOrEqualToSuperview().inset(horizontalEdgeOffset)
                    make.left.greaterThanOrEqualToSuperview().inset(horizontalEdgeOffset)
                    make.top.equalTo(arrowView.snp.bottom).offset(-verticalOffset)
                    make.width.lessThanOrEqualTo(maxWidth)
                    make.width.greaterThanOrEqualTo(minWidth)
                }
                arrowView.snp.remakeConstraints { (make) in
                    make.width.equalTo(arrowLength)
                    make.height.equalTo(arrowWidth)
                    make.top.equalTo(referenceView.snp.bottom).offset(arrowDistance)
                    make.centerX.equalTo(referenceView)
                }
                innerArrowView.snp.remakeConstraints {
                    $0.width.equalTo(arrowLength - 2)
                    $0.height.equalTo(arrowWidth - 1)
                    $0.top.equalTo(arrowView.snp.top).offset(2)
                    $0.centerX.equalTo(arrowView)
                }
            case .right:
                contentView.snp.remakeConstraints { (make) in
                    make.left.equalTo(arrowView.snp.right)
                    make.centerY.equalTo(referenceView)
                    make.width.lessThanOrEqualTo(maxWidth)
                    make.width.greaterThanOrEqualTo(minWidth)
                }
                arrowView.snp.remakeConstraints { (make) in
                    make.width.equalTo(arrowWidth)
                    make.height.equalTo(arrowLength)
                    make.centerY.equalTo(referenceView)
                    make.left.equalTo(referenceView.snp.right).offset(arrowDistance)
                }
                innerArrowView.snp.remakeConstraints {
                    $0.width.equalTo(arrowWidth - 2)
                    $0.height.equalTo(arrowLength - 1)
                    $0.left.equalTo(arrowView.snp.left).offset(2)
                    $0.centerY.equalTo(arrowView)
                }
            case .left:
                contentView.snp.remakeConstraints { (make) in
                    make.right.equalTo(arrowView.snp.left)
                    make.centerY.equalTo(referenceView)
                    make.width.lessThanOrEqualTo(maxWidth)
                    make.width.greaterThanOrEqualTo(minWidth)
                }
                arrowView.snp.remakeConstraints { (make) in
                    make.width.equalTo(arrowWidth)
                    make.height.equalTo(arrowLength)
                    make.centerY.equalTo(referenceView)
                    make.right.equalTo(referenceView.snp.left).offset(-arrowDistance)
                }
                innerArrowView.snp.remakeConstraints {
                    $0.width.equalTo(arrowWidth - 2)
                    $0.height.equalTo(arrowLength - 1)
                    $0.right.equalTo(arrowView.snp.right).offset(-2)
                    $0.centerY.equalTo(arrowView)
                }
            case .centerBottom:
                contentView.snp.remakeConstraints { (make) in
                    make.centerX.equalTo(referenceView)
                    make.top.equalTo(arrowView.snp.bottom)
                    make.width.lessThanOrEqualTo(maxWidth)
                    make.width.greaterThanOrEqualTo(minWidth)
                }
                arrowView.snp.remakeConstraints { (make) in
                    make.width.equalTo(arrowLength)
                    make.height.equalTo(arrowWidth)
                    make.top.equalTo(referenceView.snp.centerY).offset(arrowDistance)
                    make.centerX.equalTo(referenceView)
                }
                innerArrowView.snp.remakeConstraints {
                    $0.width.equalTo(arrowLength - 2)
                    $0.height.equalTo(arrowWidth - 1)
                    $0.top.equalTo(arrowView.snp.top).offset(-2)
                    $0.centerX.equalTo(arrowView)
                }
            }
            arrowView.setNeedsDisplay()
            innerArrowView.setNeedsDisplay()
            layoutIfNeeded()
            updateMaskLayer()
        }
    }

    public func setStyle(_ style: GuideStyle,
                         on direction: GuideDirection,
                         of referenceView: UIView,
                         forcesSingleLine: Bool = false,
                         distance: CGFloat? = nil) {
        self.style = style
        self.referenceView = referenceView
        isHidden = true

        updateAppearance()
        if forcesSingleLine {
            label.numberOfLines = 1
        } else if case .stressedPlain = style {
            label.numberOfLines = 2
        } else {
            label.numberOfLines = 0
        }

        arrowView.direction = direction
        innerArrowView.direction = direction
        updateLayout(referenceView: referenceView, distance: distance)
    }

    private func updateAppearance() {
        let bcColor: UIColor
        let tintColor: UIColor
        contentView.layer.ud.setShadow(type: .s4Down)
        switch style {
        case .plain, .focusPlain:
            bcColor = .clear
            tintColor = UIColor.ud.bgPricolor
            contentView.layer.borderColor = UIColor.black.cgColor
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 8
        case .lightOnboarding:
            bcColor = .clear
            tintColor = UIColor.ud.O50
            titleLabel.textColor = .ud.O600
            label.textColor = .ud.O600.withAlphaComponent(0.8)
            contentView.layer.borderColor = UIColor.ud.O200.cgColor
            contentView.layer.borderWidth = 1.0
            contentView.layer.cornerRadius = 6
        case .operable:
            bcColor = UIColor.ud.N1000.withAlphaComponent(0.6)
            tintColor = UIColor.ud.bgPricolor
            titleLabel.textColor = .ud.textCaption
            label.textColor = .ud.textTitle
            contentView.layer.borderColor = UIColor.black.cgColor
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 8
        case .alert:
            bcColor = .clear
            tintColor = UIColor.ud.primaryFillHover
            contentView.layer.ud.setShadowColor(UIColor.ud.bgPricolor.withAlphaComponent(0.3))
            contentView.layer.shadowOffset = CGSize(width: 0.0, height: 12.0)
            contentView.layer.shadowRadius = 24
            contentView.layer.shadowOpacity = 1.0
            contentView.layer.borderColor = UIColor.black.cgColor
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 8
        case .alertWithAnimation:
            bcColor = .ud.bgMask
            tintColor = UIColor.ud.B400
            contentView.layer.ud.setShadowColor(UIColor.ud.bgPricolor.withAlphaComponent(0.3))
            contentView.layer.shadowOffset = CGSize(width: 0.0, height: 12.0)
            contentView.layer.shadowRadius = 8
            contentView.layer.shadowOpacity = 1.0
            contentView.layer.borderColor = UIColor.black.cgColor
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 8
        case .darkPlain:
            bcColor = .clear
            tintColor = UIColor.ud.bgTips
            contentView.layer.borderColor = UIColor.black.cgColor
            contentView.layer.borderWidth = 0
            contentView.layer.cornerRadius = 8
        case .stressedPlain:
            bcColor = .clear
            tintColor = UIColor.ud.bgFloat
            titleLabel.textColor = .ud.textCaption
            label.textColor = .ud.textTitle
            contentView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
            contentView.layer.borderWidth = 1.0
            contentView.layer.cornerRadius = 8
        }
        if case .darkPlain = style {
            stackView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(12)
                make.top.bottom.equalToSuperview().inset(8)
            }
        } else if case .stressedPlain = style {
            stackView.snp.remakeConstraints {
                $0.left.equalToSuperview().offset(22)
                $0.right.equalToSuperview().inset(12)
                $0.top.bottom.equalToSuperview().inset(10)
            }
        } else if case .alertWithAnimation = style {
            stackView.snp.remakeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(20)
            }
        } else  if case .lightOnboarding = style {
            stackView.snp.remakeConstraints {
                $0.left.equalToSuperview().offset(40)
                $0.right.equalToSuperview().inset(16)
                $0.top.equalToSuperview().inset(10)
                $0.bottom.equalToSuperview().inset(12)
            }
        } else {
            stackView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(20)
                make.top.bottom.equalToSuperview().inset(16)
            }
        }
        backgroundColor = bcColor
        contentView.backgroundColor = tintColor
        switch style {
        case .stressedPlain:
            arrowView.color = UIColor.ud.lineBorderCard
            let configuredTintColor = UIColor.dynamic(light: UIColor(red: 0.996, green: 0.996, blue: 0.996, alpha: 1.0),
                                                      dark: UIColor(red: 0.157, green: 0.157, blue: 0.157, alpha: 1.0))
            innerArrowView.color = configuredTintColor
        case .lightOnboarding:
            let configuredTintColor = UIColor.dynamic(light: UIColor(red: 0.988, green: 0.949, blue: 0.902, alpha: 1.0),
                                                      dark: UIColor(red: 0.196, green: 0.133, blue: 0.039, alpha: 1.0))
            arrowView.color = UIColor.ud.O200
            innerArrowView.color = configuredTintColor
        default:
            arrowView.color = tintColor
            innerArrowView.color = UIColor.clear
        }

        if case .stressedPlain = style {
            lineView.isHidden = false
        } else {
            lineView.isHidden = true
        }
        if case .lightOnboarding = style {
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
    }

    private func updateContent() {
        arrowView.isHidden = false
        innerArrowView.isHidden = false
        titleLabel.isHidden = true
        animationContainerView.isHidden = true
        switch style {
        case let .plain(content, title):
            label.attributedText = NSAttributedString(string: content, config: .hAssist)
            label.lineBreakMode = .byTruncatingTail
            operationView.isHidden = true
            if let title = title {
                titleLabel.text = title
                titleLabel.attributedText = NSAttributedString(string: title, config: .h2)
                titleLabel.isHidden = false
                stackView.alignment = .leading
            }
        case let .lightOnboarding(content, title):
            label.attributedText = NSAttributedString(string: content, config: .r_14_22)
            label.lineBreakMode = .byTruncatingTail
            operationView.isHidden = true
            if let title = title {
                titleLabel.text = title
                titleLabel.attributedText = NSAttributedString(string: title, config: .m_17_26)
                titleLabel.isHidden = false
                stackView.alignment = .leading
            }
            stackView.setCustomSpacing(4, after: titleLabel)
            contentView.layer.ud.setShadow(type: .s4Down)
            contentView.layer.shadowOpacity = 1.0
            contentView.layer.shadowOffset = CGSize(width: 0, height: 6)
            contentView.layer.shadowRadius = 2
            contentView.layer.masksToBounds = false
        case let .focusPlain(content):
            label.attributedText = NSAttributedString(string: content, config: .hAssist)
            operationView.isHidden = true
        case let .darkPlain(content):
            label.attributedText = NSAttributedString(string: content, config: .tinyAssist)
            operationView.isHidden = true
            innerArrowView.isHidden = true
        case let .stressedPlain(content, title):
            label.attributedText = NSAttributedString(string: content, config: .m_14_22)
            label.lineBreakMode = .byTruncatingTail
            operationView.isHidden = true
            titleLabel.text = title
            titleLabel.attributedText = NSAttributedString(string: title, config: .r_12_18)
            titleLabel.isHidden = false
            stackView.setCustomSpacing(0, after: titleLabel)
            stackView.alignment = .leading
            contentView.layer.ud.setShadow(type: .s4Down)
            contentView.layer.shadowOpacity = 1.0
            contentView.layer.shadowOffset = CGSize(width: 0, height: 6)
            contentView.layer.shadowRadius = 2
            contentView.layer.masksToBounds = false
        case let .alert(content, title, config):
            label.attributedText = NSAttributedString(string: content, config: .hAssist)
            operationView.isHidden = false
            indicatorLabel.text = ""
            indicatorLabel.isHidden = false
            skipButton.isHidden = true
            nextButton.isHidden = false
            if let title = title {
                titleLabel.text = title
                titleLabel.attributedText = NSAttributedString(string: title, config: .h2)
                titleLabel.isHidden = false
                indicatorLabel.isHidden = true
                skipButton.isHidden = true
            }

            if let buttonName = config {
                nextButton.setAttributedTitle(.init(string: buttonName,
                                                    config: .boldBodyAssist,
                                                    textColor: UIColor.ud.primaryContentDefault),
                                              for: .normal)
            } else {
                nextButton.setAttributedTitle(.init(string: I18n.View_G_GotItButton,
                                                config: .boldBodyAssist,
                                                textColor: UIColor.ud.primaryContentDefault),
                                          for: .normal)
            }
        case let .alertWithAnimation(content, title, animationName):
            label.attributedText = NSAttributedString(string: content, config: .hAssist)
            operationView.isHidden = false
            indicatorLabel.isHidden = true
            skipButton.isHidden = true
            nextButton.isHidden = false
            titleLabel.text = title
            titleLabel.attributedText = NSAttributedString(string: title, config: .h2)
            titleLabel.isHidden = false
            nextButton.setAttributedTitle(.init(string: I18n.View_G_GotItButton,
                                                config: .h3,
                                                textColor: UIColor.ud.primaryContentDefault),
                                          for: .normal)
            animationView.setAnimation(named: animationName, bundle: .localResources)
            animationView.loopAnimation = true
            animationView.play()
            animationContainerView.isHidden = false
            arrowView.isHidden = true
            innerArrowView.isHidden = true
        case .operable(let contents, let index):
            let count = contents.count
            guard index < count else {
                return
            }

            let content = contents[index]
            label.attributedText = NSAttributedString(string: content, config: .hAssist)
            operationView.isHidden = false
            let isLast = (index == count - 1)
            indicatorLabel.text = "\(index + 1)/\(count)"
            indicatorLabel.isHidden = false
            skipButton.isHidden = isLast
            nextButton.isHidden = false
            nextButton.setAttributedTitle(.init(string: isLast ? I18n.View_G_GotItButton : I18n.View_G_NextOne,
                                                config: .boldBodyAssist,
                                                textColor: UIColor.ud.primaryContentDefault),
                                          for: .normal)
        }
    }

    private func updateMaskLayer() {
        guard let referenceView = self.referenceView,
              case .operable = style else {
            self.layer.mask = nil
            return
        }

        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.layer.bounds

        let path = UIBezierPath(rect: self.layer.bounds)
        maskLayer.fillRule = .evenOdd

        let inset: CGFloat = 4.0
        let radius = referenceView.bounds.height / 2.0 - inset
        let frame = referenceView.convert(referenceView.bounds, to: self)
        let rect = CGRect(x: frame.midX - radius,
                          y: frame.midY - radius,
                          width: radius * 2,
                          height: radius * 2)
        path.append(UIBezierPath(ovalIn: rect))
        maskLayer.path = path.cgPath

        self.layer.mask = maskLayer
        maskLayer.ud.setFillColor(UIColor.ud.N1000)
    }
}

private extension ConstraintPriority {
    static var lower: ConstraintPriority {
        // 249.0
        return ConstraintPriority(ConstraintPriority.low.value - 1)
    }
}
