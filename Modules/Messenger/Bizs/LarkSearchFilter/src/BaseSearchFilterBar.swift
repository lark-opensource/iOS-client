//
//  BaseSearchFilterBar.swift
//  LarkSearchFilter
//
//  Created by SolaWing on 2021/3/29.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import LarkContainer
import UniverseDesignIcon

/// 新FilterBar，用于在Lark内展示和控制filter项
/// https://www.figma.com/file/Sh2cFkQDBtp1RyDbwdez4d/%E7%A7%BB%E5%8A%A8%E7%AB%AF%26iPad-Search-Filter?node-id=63%3A0
/// Base Filter Bar只提供容器布局, 不提供具体filter item

public enum FilterBarStyle {
    case dark, light
}

open class BaseSearchFilterBar: UIView {
    public let contentView: UIStackView = UIStackView()
    public let resetView: UIButton = UIButton()
    public let gradientView = GradientView()
    public let scrollView = UIScrollView()
    open var style: FilterBarStyle
    public init(frame: CGRect, style: FilterBarStyle) {
        self.style = style
        super.init(frame: frame)

        let backgroundColor = UIColor.ud.bgBody
        self.backgroundColor = backgroundColor

        scrollView.contentInset = .init(top: 0, left: 16, bottom: 0, right: 24)
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false

        contentView.alignment = .center
        contentView.spacing = 10

        resetView.setTitle(BundleI18n.LarkSearchFilter.Lark_Search_ResetFilter, for: .normal)
        resetView.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        resetView.titleLabel?.font = UIFont.systemFont(ofSize: 14)

        gradientView.colors = [backgroundColor.withAlphaComponent(0), backgroundColor, backgroundColor]
        gradientView.gradientLayer.locations = [0, 0.4, 1]
        gradientView.gradientLayer.startPoint = .init(x: 0, y: 0.5)
        gradientView.gradientLayer.endPoint = .init(x: 1, y: 0.5)

        // layout
        addSubview(scrollView)
        addSubview(resetView)
        addSubview(gradientView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints {
            $0.left.equalToSuperview().priority(799) // 子类可以覆盖
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview().priority(800) // reset出现时打破
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(scrollView)
        }

        resetView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(5)
            $0.right.equalToSuperview().offset(-16)
            resetViewConstraint = $0.left.equalTo(scrollView.snp.right).constraint
        }
        resetView.setContentCompressionResistancePriority(.init(900), for: .horizontal)

        gradientView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalTo(scrollView.snp.right).priority(.high)
            $0.left.equalTo(resetView).offset(-24)
        }

        // bind reset view state
        resetViewConstraint.deactivate()
        resetView.isHidden = true
        gradientView.isHidden = true

        // bind visible
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var resetViewConstraint: Constraint!
    public var resetVisible: Bool {
        get { !resetView.isHidden }
        set {
            guard newValue != resetVisible else { return }
            assert(Thread.isMainThread, "should occur on main thread!")
            resetView.isHidden = !newValue
            gradientView.isHidden = !newValue
            if newValue {
                resetViewConstraint.activate()
            } else {
                resetViewConstraint.deactivate()
            }
        }
    }
    public var touchReset: ControlEvent<Void> { resetView.rx.tap }
    public final class GradientView: UIView {
        public override class var layerClass: AnyClass { CAGradientLayer.self }
        public var gradientLayer: CAGradientLayer { layer as! CAGradientLayer } // swiftlint:disable:this all
        public var colors: [UIColor] = [] {
            didSet {
                gradientLayer.colors = colors.map { $0.resolvedCompatibleColor(with: traitCollection).cgColor }
            }
        }
        public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            if #available(iOS 13.0, *) {
                if !colors.isEmpty && traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                    gradientLayer.colors = colors.map { $0.resolvedCompatibleColor(with: traitCollection).cgColor }
                }
            }
        }
    }
}
extension BaseSearchFilterBar {
    public final class ExpandDownFilledView: UIImageView {
        public var onClick: (() -> Void)?
        public override init(image: UIImage?) {
            super.init(image: image)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            self.addGestureRecognizer(tapGesture)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        func imageTapped(_ sender: UITapGestureRecognizer) {
            onClick?()
        }
        public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            // 增大点击的热区
            let hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -8, bottom: -10, right: -12)
            let relativeFrame = self.bounds
            let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
            return hitFrame.contains(point)
        }
    }

    /// 仅用于推荐筛选器
    public final class TextAvatarCell: UIView {
        public final class ButtonView: UIControl {
            public lazy var leftPartLabel: UILabel = {
                let label = UILabel()
                label.textColor = .ud.textTitle
                label.font = UIFont.systemFont(ofSize: 14)
                return label
            }()

            let avatarView = RoundAvatarStackView(avatarViews: [], avatarWidth: 16, overlappingWidth: 4, showBgColor: false)

            public lazy var rightPartLabel: UILabel = {
                let label = UILabel()
                label.textColor = .ud.textTitle
                label.font = UIFont.systemFont(ofSize: 14)
                return label
            }()

            public override init(frame: CGRect) {
                super.init(frame: frame)

                self.layer.cornerRadius = 6
                self.addSubview(leftPartLabel)
                self.addSubview(avatarView)
                self.addSubview(rightPartLabel)

                leftPartLabel.snp.makeConstraints {
                    $0.left.equalToSuperview().inset(12)
                    $0.centerY.equalToSuperview()
                }
                avatarView.snp.makeConstraints {
                    $0.left.equalTo(leftPartLabel.snp.right)
                    $0.size.equalTo(CGSize(width: 16, height: 16))
                    $0.centerY.equalToSuperview()
                }
                rightPartLabel.snp.makeConstraints {
                    $0.left.equalTo(avatarView.snp.right).offset(4)
                    $0.right.equalToSuperview().inset(12)
                    $0.centerY.equalToSuperview()
                }
            }
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        public lazy var button: ButtonView = {
            let view = ButtonView()
            return view
        }()

        public lazy var dividor: UIView = {
            let view = UIView()
            return view
        }()

        public var style: FilterBarStyle {
            didSet {
                setupStyleAndValue()
            }
        }
        public init(frame: CGRect, style: FilterBarStyle) {
            self.style = style
            super.init(frame: frame)

            self.addSubview(button)
            self.addSubview(dividor)

            button.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.top.bottom.equalToSuperview()
            }

            dividor.snp.makeConstraints {
                $0.left.equalTo(button.snp.right).offset(10)
                $0.right.equalToSuperview()
                $0.size.equalTo(CGSize(width: 2, height: 18))
                $0.centerY.equalToSuperview()
            }
            self.snp.makeConstraints {
                $0.height.equalTo(32).priority(.medium)
            }

            value = nil
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public var value: (breakedTitle: (String, String), avatarViews: [UIView]?)? {
            didSet {
                setupStyleAndValue()
            }
        }
        private func setupStyleAndValue() {
            switch style {
            case .dark:
                button.backgroundColor = .ud.bgBody
                dividor.backgroundColor = .ud.bgBody
            case .light:
                button.backgroundColor = UIColor.ud.bgFiller
                dividor.backgroundColor = UIColor.ud.bgFiller
            }
            if let value = value {
                button.leftPartLabel.text = value.breakedTitle.0
                button.rightPartLabel.text = value.breakedTitle.1
                if let avatarViews = value.avatarViews {
                    button.avatarView.set(avatarViews)
                }
            }
        }
    }
    /// 展示title(提示)或者value
    public final class TextValueCell: UIControl {
        public let label = UILabel()
        public var expandDownFilledView: ExpandDownFilledView = {
            var image = UDIcon.expandDownFilled
            image = image.withRenderingMode(.alwaysOriginal)
            image = image.ud.withTintColor(UIColor.ud.primaryContentDefault)
            var imageView = ExpandDownFilledView(image: image)
            return imageView
        }()
        var shouldHideExpandArrow: Bool
        public var style: FilterBarStyle {
            didSet {
                setupStyleAndValue()
            }
        }
        public init(frame: CGRect, style: FilterBarStyle, shouldHideExpandArrow: Bool) {
            self.style = style
            self.shouldHideExpandArrow = shouldHideExpandArrow
            super.init(frame: frame)

            self.layer.cornerRadius = 6
            label.font = UIFont.systemFont(ofSize: 14)

            self.addSubview(label)

            if shouldHideExpandArrow {
                label.snp.makeConstraints {
                    $0.left.equalToSuperview().inset(16)
                    $0.right.equalToSuperview().inset(12)
                    $0.centerY.equalToSuperview()
                }
            } else {
                self.addSubview(expandDownFilledView)
                label.snp.makeConstraints {
                    $0.left.equalToSuperview().inset(16)
                    $0.centerY.equalToSuperview()
                }
                expandDownFilledView.snp.makeConstraints {
                    $0.left.equalTo(label.snp.right).offset(4)
                    $0.centerY.equalToSuperview()
                    $0.size.equalTo(CGSize(width: 10, height: 10))
                    $0.right.equalToSuperview().inset(12)
                }
            }
            self.snp.makeConstraints {
                $0.height.equalTo(32).priority(.medium)
            }

            value = nil // set style by state
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        public var title: String = ""
        public var value: String? {
            didSet {
                setupStyleAndValue()
            }
        }
        private func setupStyleAndValue() {
            if let value = value {
                switch style {
                case .dark:
                    backgroundColor = .ud.bgBody
                case .light:
                    backgroundColor = UIColor.ud.functionInfoFillSolid02
                }
                label.textColor = UIColor.ud.primaryContentDefault
                label.text = value
                if !shouldHideExpandArrow {
                    var cancelImage = UDIcon.closeBoldOutlined
                    cancelImage = cancelImage.withRenderingMode(.alwaysOriginal)
                    cancelImage = cancelImage.ud.withTintColor(UIColor.ud.primaryContentDefault)
                    expandDownFilledView.image = cancelImage
                    expandDownFilledView.snp.updateConstraints {
                        $0.left.equalTo(label.snp.right).offset(8)
                    }
                }
            } else {
                switch style {
                case .dark:
                    backgroundColor = .ud.bgBody
                case .light:
                    backgroundColor = UIColor.ud.bgFiller
                }
                label.textColor = UIColor.ud.textTitle
                label.text = title
                if !shouldHideExpandArrow {
                    var expandImage = UDIcon.expandDownFilled
                    expandImage = expandImage.withRenderingMode(.alwaysOriginal)
                    expandImage = expandImage.ud.withTintColor(UIColor.ud.iconN2)
                    expandDownFilledView.image = expandImage
                    expandDownFilledView.snp.updateConstraints {
                        $0.left.equalTo(label.snp.right).offset(4)
                    }
                }
            }
        }
        public func switchCancel(cancelEnabled: Bool) {
            self.expandDownFilledView.isUserInteractionEnabled = cancelEnabled
        }
    }
    public final class AvatarsCell: UIControl {
        public lazy var leftPartLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            return label
        }()
        let avatarView = RoundAvatarStackView(avatarViews: [], avatarWidth: 16, overlappingWidth: 4, showBgColor: false)
        public lazy var rightPartLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.ud.primaryContentDefault
            return label
        }()
        public var expandDownFilledView: ExpandDownFilledView = {
            var image = UDIcon.expandDownFilled
            image = image.withRenderingMode(.alwaysOriginal)
            image = image.ud.withTintColor(UIColor.ud.primaryContentDefault)
            var imageView = ExpandDownFilledView(image: image)
            return imageView
        }()
        public var style: FilterBarStyle {
            didSet {
                setStyle()
            }
        }
        public init(frame: CGRect, style: FilterBarStyle) {
            self.style = style
            super.init(frame: frame)

            self.layer.cornerRadius = 6
            avatarView.isUserInteractionEnabled = false

            self.addSubview(leftPartLabel)
            self.addSubview(avatarView)
            self.addSubview(rightPartLabel)
            self.addSubview(expandDownFilledView)

            self.snp.makeConstraints {
                $0.height.equalTo(32).priority(.medium)
            }
            leftPartLabel.snp.makeConstraints {
                $0.left.equalToSuperview().inset(12)
                $0.centerY.equalToSuperview()
            }
            avatarView.snp.makeConstraints {
                $0.left.equalTo(leftPartLabel.snp.right)
                $0.size.equalTo(CGSize(width: 16, height: 16))
                $0.centerY.equalToSuperview()
            }
            rightPartLabel.snp.makeConstraints {
                $0.left.equalTo(avatarView.snp.right).offset(4)
                $0.centerY.equalToSuperview()
            }
            expandDownFilledView.snp.makeConstraints {
                $0.left.equalTo(rightPartLabel.snp.right)
                $0.size.equalTo(CGSize(width: 10, height: 10))
                $0.right.equalToSuperview().inset(12)
                $0.centerY.equalToSuperview()
            }
            value = nil // set style by state
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        public var value: (leftPartTitle: String, avatarViews: [UIView]?, rightPartTitle: String)? {
            didSet {
                setStyle()
                setValue()
            }
        }
        private func setStyle() {
            if let avatarViews = value?.avatarViews, !avatarViews.isEmpty {
                switch style {
                case .dark:
                    backgroundColor = .ud.bgBody
                case .light:
                    backgroundColor = UIColor.ud.functionInfoFillSolid02
                }
                leftPartLabel.textColor = UIColor.ud.primaryContentDefault
                var cancelImage = UDIcon.closeBoldOutlined
                cancelImage = cancelImage.withRenderingMode(.alwaysOriginal)
                cancelImage = cancelImage.ud.withTintColor(UIColor.ud.primaryContentDefault)
                expandDownFilledView.image = cancelImage
                expandDownFilledView.snp.updateConstraints {
                    $0.left.equalTo(rightPartLabel.snp.right).offset(4)
                }
            } else {
                switch style {
                case .dark:
                    backgroundColor = .ud.bgBody
                case .light:
                    backgroundColor = UIColor.ud.bgFiller
                }
                leftPartLabel.textColor = UIColor.ud.textTitle
                var expandImage = UDIcon.expandDownFilled
                expandImage = expandImage.withRenderingMode(.alwaysOriginal)
                expandImage = expandImage.ud.withTintColor(UIColor.ud.iconN2)
                expandDownFilledView.image = expandImage
                expandDownFilledView.snp.updateConstraints {
                    $0.left.equalTo(rightPartLabel.snp.right)
                }
            }
        }
        private func setValue() {
            if let value = value {
                leftPartLabel.text = value.leftPartTitle
                rightPartLabel.text = value.rightPartTitle
                if let avatarViews = value.avatarViews {
                    avatarView.set(avatarViews)
                } else {
                    avatarView.set([])
                }
            }
        }
        public func switchCancel(cancelEnabled: Bool) {
            self.expandDownFilledView.isUserInteractionEnabled = cancelEnabled
        }
    }
}
