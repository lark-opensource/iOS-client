//
//  FocusTagViewLegacy.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2022/12/8.
//

import Foundation
import UIKit
import LarkFocusInterface

public final class FocusTagViewLegacy: UIStackView {

    public enum LayoutStyle {
        case compact
        case normal
    }

    enum TagType {
        case iconOnly
        case iconText
    }

    public var style: LayoutStyle = .normal {
        didSet {
            updateLayoutConstraints()
        }
    }

    private var tagType: TagType = .iconOnly {
        didSet {
            updateLayoutConstraints()
        }
    }

    private var status: ChatterFocusStatus = .init()

    /// 单独设定 icon 的大小
    private var preferredSingleIconSize: CGFloat?

    private lazy var heightConstraint: NSLayoutConstraint = {
        heightAnchor.constraint(equalToConstant: Constraints.height)
    }()

    public var image: UIImage? {
        get { iconView.image }
        set { iconView.image = newValue }
    }

    public func config(with focusStatus: ChatterFocusStatus) {
        self.status = focusStatus
        iconView.config(with: focusStatus)
        tagType = focusStatus.tagInfo.isShowTag ? .iconText : .iconOnly
    }

    // 大部分的 tag 不需要 titleLabel，所以为了延后其加载，使用此变量记录 label 是否已初始化
    private var isTitleInitialized: Bool = false

    private lazy var iconView: FocusImageView = {
        let imageView = FocusImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var focusTitleLabel: UILabel = {
        isTitleInitialized = true
        let label = UILabel()
        label.font = Constraints.tagFont
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    /// iOS 14 之前，UIStackView 无法直接设置背景颜色，所以要加一层 backgroundView
    /// 解释：https://useyourloaf.com/blog/stack-view-background-color-in-ios-14/
    private lazy var backgroundViewUnder14: UIView = {
        let view = UIView()
        insertSubview(view, at: 0)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    /// iOS 14 之后可直接在 UIStackView 上设置背景色，不必添加 backgroundView
    private var tagEffectView: UIView {
        if #available(iOS 14, *) {
            return self
        } else {
            return backgroundViewUnder14
        }
    }

    public init(preferredSingleIconSize: CGFloat) {
        self.preferredSingleIconSize = preferredSingleIconSize
        super.init(frame: .zero)
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addArrangedSubview(iconView)
        // 暂时不添加 titleLabel，延后其创建时间，优化性能
    }

    private func setupConstraints() {
        self.isLayoutMarginsRelativeArrangement = true
        self.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = self.heightAnchor.constraint(equalToConstant: Constraints.height)
        NSLayoutConstraint.activate([heightConstraint])
        updateLayoutConstraints()
    }

    private func setupAppearance() {
        tagEffectView.layer.cornerRadius = Constraints.tagCornerRadius
        self.alignment = .center
    }

    private func updateLayoutConstraints() {
        self.spacing = Constraints.iconTitleSpacing
        heightConstraint.constant = Constraints.height
        if isTitleInitialized {
            focusTitleLabel.removeFromSuperview()
        }
        switch tagType {
        case .iconOnly:
            // container
            self.layoutMargins = .zero
            tagEffectView.backgroundColor = .clear
            // icon
            iconView.snp.remakeConstraints { make in
                make.size.equalTo(preferredSingleIconSize ?? Constraints.singleIconSize)
            }
        case .iconText:
            // container
            self.layoutMargins = UIEdgeInsets(horizontal: Constraints.hMargin, vertical: 0)
            tagEffectView.backgroundColor = status.tagInfo.tagColor.backgroundColor
            // icon
            iconView.snp.remakeConstraints { make in
                make.size.equalTo(Constraints.tagIconSize)
            }
            // label
            self.addArrangedSubview(focusTitleLabel)
            focusTitleLabel.text = status.title
            focusTitleLabel.font = Constraints.tagFont
            focusTitleLabel.textColor = status.tagInfo.tagColor.textColor
        }
    }
}

// MARK: - Constraints Definition

extension FocusTagViewLegacy {

    // swiftlint:disable all
    var Constraints: FocusTagView.Cons.Type {
        switch style {
        case .compact:  return FocusTagView.ConsCompact.self
        case .normal:   return FocusTagView.ConsRegular.self
        }
    }
    // swiftlint:enable all
}
