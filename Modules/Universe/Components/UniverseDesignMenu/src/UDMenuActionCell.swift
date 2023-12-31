//
//  UDMenuActionCell
//  UniverseDesignMenu
//
//  Created by qsc on 2020/11/2.
//  Copyright © ByteDance. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignBadge
import SnapKit

final class UDMenuActionCell: UITableViewCell {
    static let ReuseIdentifier = "UDMenuActionCell"

    private lazy var iconImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UDMenuColorTheme.menuItemTitleColor
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.caption1
        label.textColor = UDMenuColorTheme.menuSubTitleColor
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private var isDisabled: Bool = false

    private lazy var borderLine: DividerLine = DividerLine()

    private lazy var textContainer: UIStackView = {
        let textContaienr = UIStackView()
        textContaienr.spacing = MenuCons.titleSubTitleSpacing
        textContaienr.axis = .vertical
        textContaienr.alignment = .leading
        return textContaienr
    }()

    /// 选中cell时按压的浅灰色圆角矩形背景
    private lazy var selectedBGView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = MenuCons.menuItemPressedCornerRadius
        view.isUserInteractionEnabled = false
        return view
    }()

    private var style: UDMenuStyleConfig?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not implemented")
    }

    // MARK: func
    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubViews() {
        self.contentView.addSubview(selectedBGView)
        self.contentView.addSubview(iconImage)
        self.contentView.addSubview(textContainer)
        self.textContainer.addArrangedSubview(titleLabel)
        self.textContainer.addArrangedSubview(subTitleLabel)
    }

    private func setupConstraints() {
        iconImage.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(MenuCons.paddingTop)
            make.leading.equalToSuperview().offset(MenuCons.iconPaddingLeft)
            make.width.height.equalTo(self.style?.menuItemIconWidth ?? MenuCons.iconDefaultWidth)
        }

        textContainer.snp.makeConstraints { make in
            make.leading.equalTo(iconImage.snp.trailing).offset(MenuCons.iconTextSpacing)
            make.trailing.equalToSuperview().inset(MenuCons.textPaddingRight)
            make.top.equalToSuperview().offset(MenuCons.paddingTop)
            make.bottom.equalTo(selectedBGView.snp.bottom).inset(MenuCons.paddingBottom)
        }

        subTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }

        selectedBGView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(MenuCons.menuMargin)
            make.right.equalToSuperview().inset(MenuCons.menuMargin)
            make.top.bottom.equalToSuperview()
        }
    }

    private func setupAppearance() {
        self.contentView.backgroundColor = UDMenuColorTheme.menuItemBackgroundColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted, !isDisabled {
            selectedBGView.backgroundColor = style?.menuItemSelectedBackgroundColor ?? UDMenuColorTheme.menuItemSelectedBackgroundColor
        } else {
            selectedBGView.backgroundColor = .clear
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetProps()
    }

    private func resetProps() {
        iconImage.image = nil
        titleLabel.attributedText = nil
        subTitleLabel.attributedText = nil
        subTitleLabel.isHidden = true
        isDisabled = false
        titleLabel.badge?.removeFromSuperview()
    }

    func configure(action: UDMenuAction, style: UDMenuStyleConfig) {
        self.style = style
        self.isDisabled = action.isDisabled
        self.setTitleLabel(with: action)
        self.setSubTitleLabel(with: action)
        self.setIcon(with: action)
        self.setBadge(with: action)
        self.setBorderLine(with: action)
    }
}

extension UDMenuActionCell {
    /// 设置标题标签
    func setTitleLabel(with newAction: UDMenuAction) {
        let defaultColor: UIColor = newAction.titleTextColor ?? style?.menuItemTitleColor ?? UDMenuColorTheme.menuItemTitleColor
        let textColor: UIColor = self.isDisabled ? UDMenuColorTheme.menuTextDisableColor : defaultColor
        let font: UIFont = style?.menuItemTitleFont ?? MenuCons.titleFont
        let titleBaselineOffset = (MenuCons.titleLineHeight - MenuCons.titleFont.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = MenuCons.titleLineHeight
        mutableParagraphStyle.maximumLineHeight = MenuCons.titleLineHeight
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail

        self.titleLabel.attributedText = NSAttributedString(
            string: newAction.title,
            attributes: [
                .baselineOffset : titleBaselineOffset,
                .paragraphStyle : mutableParagraphStyle,
                .font: font,
                .foregroundColor: textColor
            ]
        )
    }

    /// 设置副标题标签
    func setSubTitleLabel(with newAction: UDMenuAction) {
        guard let subTitle = newAction.subTitle else {
            self.subTitleLabel.isHidden = true
            return
        }
        self.subTitleLabel.isHidden = false
        let defaultColor: UIColor = newAction.subTitleTextColor ?? UDMenuColorTheme.menuSubTitleColor
        let textColor: UIColor = self.isDisabled ? UDMenuColorTheme.menuTextDisableColor : defaultColor
        let font: UIFont = style?.menuItemSubTitleFont ?? MenuCons.subTitleFont
        let subTitleBaselineOffset = (MenuCons.subTitleLineHeight - MenuCons.subTitleFont.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = MenuCons.subTitleLineHeight
        mutableParagraphStyle.maximumLineHeight = MenuCons.subTitleLineHeight
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail

        self.subTitleLabel.attributedText = NSAttributedString(
            string: subTitle,
            attributes: [
                .baselineOffset : subTitleBaselineOffset,
                .paragraphStyle : mutableParagraphStyle,
                .font: font,
                .foregroundColor: textColor
            ]
        )
    }

    /// 设置图标
    func setIcon(with newAction: UDMenuAction) {
        if newAction.icon == nil && newAction.customIconHandler == nil {
            assertionFailure("Menu icon should not be empty, Please set Value to UDMenuAction.icon or UDMenuAction.customIconHandler")
            return
        }
        self.setNormalIcon(with: newAction)
        self.setCustomIcon(with: newAction)
    }

    /// 设置默认图标、统一进行染色
    func setNormalIcon(with newAction: UDMenuAction) {
        guard let icon = newAction.icon else { return }
        if isDisabled {
            iconImage.image = icon.ud.withTintColor(style?.menuItemIconDisableColor ?? UDMenuColorTheme.menuIconDisableColor)
        } else {
            iconImage.image = icon.ud.withTintColor(style?.menuItemIconTintColor ?? UDMenuColorTheme.menuItemIconTintColor)
        }
    }

    /// 设置自定义图标，不受统一 Style 影响
    func setCustomIcon(with newAction: UDMenuAction) {
        guard let customIconHandler = newAction.customIconHandler else { return }
        customIconHandler(self.iconImage)
    }

    /// 设置 Badge
    func setBadge(with newAction: UDMenuAction) {
        guard newAction.hasBadge else { return }
        let smallSize = UDBadgeDotSize.small.size
        let offsetX = (smallSize.width / 2.0) + 2.0
        let badge = titleLabel.addBadge(.dot,
                                        anchor: .topRight,
                                        anchorType: .rectangle,
                                        offset: CGSize(width: offsetX, height: 0.0))
        badge.config.dotSize = .small
    }

    /// 设置分割线
    func setBorderLine(with newAction: UDMenuAction) {
        guard newAction.showBottomBorder else {
            self.borderLine.isHidden = true
            return
        }
        self.borderLine.isHidden = false
        self.borderLine.line.backgroundColor = style?.menuItemSeperatorColor
        self.contentView.addSubview(borderLine)
        self.selectedBGView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(MenuCons.menuMargin)
            make.right.equalToSuperview().inset(MenuCons.menuMargin)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-MenuCons.menuDivideViewHeight)
        }
        self.borderLine.snp.makeConstraints { (maker) in
            maker.height.equalTo(MenuCons.menuDivideViewHeight)
            maker.width.equalToSuperview()
            maker.top.equalTo(selectedBGView.snp.bottom)
            maker.bottom.equalToSuperview()
            maker.centerX.equalToSuperview()
        }
    }
}

class DividerLine: UIView {
    lazy var line: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(line)
        line.snp.makeConstraints { make in
            make.height.equalTo(MenuCons.menuDivideLineHeight)
            make.width.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

