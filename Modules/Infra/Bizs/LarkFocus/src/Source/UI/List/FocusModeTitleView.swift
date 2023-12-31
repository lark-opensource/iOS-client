//
//  FocusTitleView.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import FigmaKit
import LarkInteraction
import UniverseDesignTag
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignLoading

final class FocusTitleView: UIView {

    func showLoading(_ message: String) {
        silentTag.isHidden = true
        subtitleLabel.text = message
    }

    var selectionState: FocusModeCellState = .closed {
        didSet {
            if oldValue != selectionState {
                changeSelectionState()
            }
        }
    }

    var isExpanded: Bool = false {
        didSet { changeExpansionState() }
    }

    private lazy var colorView: LinearGradientView = {
        let view = LinearGradientView()
        view.colors = Cons.selectedColors
        view.direction = .leftToRight
        return view
    }()

    lazy var iconView: FocusImageView = {
        let imageView = FocusImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var contentContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 2
        return label
    }()

    private lazy var subtitleView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    lazy var silentTag: SilentTagView = {
        let tagView = SilentTagView()
        return tagView
    }()

    lazy var expandButton: UIButton = {
        let button = ExtendedButton()
        button.extendInsets = UIEdgeInsets(top: 20, left: 4, bottom: 20, right: 20)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(colorView)
        addSubview(iconView)
        addSubview(contentContainer)
        addSubview(expandButton)
        contentContainer.addArrangedSubview(titleLabel)
        contentContainer.addArrangedSubview(subtitleView)
        subtitleView.addArrangedSubview(subtitleLabel)
        subtitleView.addArrangedSubview(silentTag)
        let padding = UIView()
        padding.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        padding.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleView.addArrangedSubview(padding)
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
    }

    private func setupConstraints() {
        self.snp.makeConstraints { make in
            make.height.equalTo(80).priority(999)
        }
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(24)
        }
        contentContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-64)
        }
        expandButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
            make.trailing.equalToSuperview().offset(-16)
        }
        contentContainer.spacing = 5
        subtitleView.setCustomSpacing(8, after: subtitleLabel)
    }

    private func setupAppearance() {
        backgroundColor = UIColor.ud.bgFloat
        changeExpansionState()
        changeSelectionState()
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .highlight))
            expandButton.addLKInteraction(action)
        }
    }

    private func changeExpansionState() {
        setButtonState()
    }

    private func changeSelectionState() {
        setButtonState()
        changeTitleViewColorForCurrentState()
    }

    private func setButtonState() {
        switch (isExpanded, selectionState.isSelected) {
        case (false, false):
            expandButton.setImage(Cons.moreIcon.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
            expandButton.backgroundColor = .clear
        case (false, true):
            expandButton.setImage(Cons.moreIcon.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill), for: .normal)
            expandButton.backgroundColor = .clear
        case (true, false):
            expandButton.setImage(Cons.foldIcon.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
            expandButton.backgroundColor = UIColor.ud.fillHover
        case (true, true):
            expandButton.setImage(Cons.foldIcon.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill), for: .normal)
            expandButton.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.2)
        }
    }

    private func changeTitleViewColorForCurrentState() {
        switch selectionState {
        case .closed:
            // 已关闭状态
            colorView.colors = Cons.normalColors
            titleLabel.textColor = UIColor.ud.textTitle
            subtitleLabel.textColor = UIColor.ud.textPlaceholder
        case .closing:
            // 关闭中状态（淡蓝色）
            colorView.colors = Cons.loadingColors
            titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.7)
            subtitleLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.7)
            subtitleLabel.text = BundleI18n.LarkFocus.Lark_Profile_TurningOffStatus_LoadingState
            silentTag.isHidden = true
        case .opened:
            // 已开启状态
            colorView.colors = Cons.selectedColors
            titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            subtitleLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        case .opening:
            // 开启中状态
            colorView.colors = Cons.normalColors
            titleLabel.textColor = UIColor.ud.udtokenComponentTextDisabledLoading
            subtitleLabel.textColor = UIColor.ud.udtokenComponentTextDisabledLoading
            subtitleLabel.text = BundleI18n.LarkFocus.Lark_Profile_TurningOnStatus_LoadingState
            silentTag.isHidden = true
        case .reopening:
            // 重新开启状态
            colorView.colors = Cons.loadingColors
            titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.7)
            subtitleLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.7)
            subtitleLabel.text = BundleI18n.LarkFocus.Lark_Profile_TurningOnStatus_LoadingState
            silentTag.isHidden = true
        }
        silentTag.isSelected = selectionState.isSelected
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Dark mode changes.
        changeTitleViewColorForCurrentState()
    }
}

extension FocusTitleView {

    enum Cons {
        static var moreIcon: UIImage {
            UDIcon.moreOutlined.ud.resized(to: CGSize(width: 20, height: 20))
        }
        static var foldIcon: UIImage {
            UDIcon.upOutlined.ud.resized(to: CGSize(width: 20, height: 20))
        }
        static var selectedColors: [UIColor] {
            [UIColor.ud.B400 & UIColor.ud.colorfulBlue,
             UIColor.ud.colorfulBlue & UIColor.ud.B400]
        }
        static var normalColors: [UIColor] {
            [UIColor.ud.bgFloat]
        }
        static var loadingColors: [UIColor] {
            // [UIColor.ud.B300]
            // 使用相同的 loading 色
            return selectedColors
        }
    }
}
