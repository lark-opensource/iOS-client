//
//  ActionSheetVerticalCenterCell.swift
//  ByteView
//
//  Created by LUNNER on 2019/1/8.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import ByteViewUI

class ActionSheetCell: UITableViewCell {

    struct Layout {
        static let leftRightOffset: CGFloat = 16.0
        static let iconSize: CGFloat = 20.0
        static let enlargedIconSize: CGFloat = 32.0
        static let titleLeftOffset: CGFloat = 12.0
        static let titleRightOffset: CGFloat = 12.0
        static let separatorHeightForDefault: CGFloat = 0.5
        static let separatorHeightForIconLabel: CGFloat = 0.5
    }

    private var item: SheetAction?

    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var warningView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        return imageView
    }()

    lazy var bottomSeparator: UIView = {
        let separator = UIView()
        return separator
    }()

    lazy var selectedIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 20, height: 20))
        imageView.isHidden = true
        return imageView
    }()

    lazy var betaLabel: UILabel = {
        let label = UILabel()
        label.text = "Beta"
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = UIColor.ud.udtokenTagNeutralTextNormal
        label.isHidden = true
        return label
    }()

    lazy var badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    lazy var betaBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        view.layer.cornerRadius = 4.0
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        self.backgroundColor = .clear

        contentView.addSubview(iconView)
        contentView.addSubview(warningView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(selectedIconView)
        contentView.addSubview(betaBackgroundView)
        contentView.addSubview(betaLabel)
        contentView.addSubview(badgeView)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalTo(contentView)
        }
        selectedIconView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
        }

        contentView.addSubview(self.bottomSeparator)
        self.bottomSeparator.snp.makeConstraints { (make) in
            make.right.left.bottom.equalToSuperview()
            make.height.equalTo(Layout.separatorHeightForDefault)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        item = actionItem

        let backgroundView = UIView()
        backgroundView.backgroundColor = apperance.backgroundColor
        self.backgroundView = backgroundView

        let selectedBackgroundView = UIView()
        let subView = UIView()
        subView.layer.cornerRadius = 4
        subView.layer.masksToBounds = true
        subView.backgroundColor = apperance.highlightedColor
        selectedBackgroundView.addSubview(subView)
        var offset = 4
        if let isSelectedIndent = item?.isSelectedIndent {
            offset = isSelectedIndent ? 4 : 0
        }
        subView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(offset)
            make.right.equalToSuperview().offset(-offset)
            make.top.bottom.equalToSuperview().inset(0.5)
        }
        self.selectedBackgroundView = selectedBackgroundView

        contentView.addInteraction(type: .hover)

        titleLabel.text = actionItem.title
        titleLabel.textColor = actionItem.titleColor
        titleLabel.textAlignment = .center

        if let titleFontConfig = actionItem.titleFontConfig {
            titleLabel.attributedText = NSAttributedString(string: actionItem.title,
                                                           config: titleFontConfig,
                                                           alignment: .center,
                                                           lineBreakMode: .byTruncatingTail,
                                                           textColor: titleLabel.textColor)
        }

        bottomSeparator.isHidden = !actionItem.showBottomSeparator
        bottomSeparator.backgroundColor = apperance.separatorColor
        selectedIconView.isHidden = !actionItem.isSelected

        switch actionItem.sheetStyle {
        case .default, .cancel:
            configForDefault(with: actionItem, apperance: apperance)
        case .withContent:
            configForWithContent(with: actionItem, apperance: apperance)
        case .iconLabelAndBadge:
            configForIconLabelAndBadge(with: actionItem, apperance: apperance)
        case .iconAndLabel:
            configForIconAndLabel(with: actionItem, apperance: apperance)
        case .warning:
            configForWarning(with: actionItem, apperance: apperance)
        case .iconLabelAndBeta:
            configForIconLabelAndBeta(with: actionItem, apperance: apperance)
        case .callIn:
            configForCallIn(with: actionItem, apperance: apperance)
        }
    }

    private func configForDefault(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        betaBackgroundView.isHidden = true
        betaLabel.isHidden = true
        contentLabel.isHidden = true
        badgeView.isHidden = true
        if let titleMarginInset = actionItem.titleMargin {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.right.equalToSuperview().offset(titleMarginInset.right)
                maker.left.equalToSuperview().offset(-titleMarginInset.left)
                maker.top.equalToSuperview().offset(titleMarginInset.top)
                maker.bottom.equalToSuperview().offset(-titleMarginInset.bottom)
            }
        } else {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.bottom.left.right.equalTo(contentView)
            }
        }
        titleLabel.textAlignment = .center
        bottomSeparator.snp.remakeConstraints { (make) in
            make.right.left.bottom.equalToSuperview()
            make.height.equalTo(Layout.separatorHeightForDefault)
        }
    }

    private func configForWithContent(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        badgeView.isHidden = true
        betaBackgroundView.isHidden = true
        betaLabel.isHidden = true
        contentLabel.isHidden = false
        if let iconImage = actionItem.icon {
            iconView.isHidden = false
            iconView.image = iconImage
            iconView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(actionItem.iconSize)
                maker.left.equalTo(Layout.leftRightOffset)
                maker.centerY.equalTo(titleLabel)
            }
            titleLabel.textAlignment = .left
        } else {
            titleLabel.textAlignment = .center
        }

        if let titleMarginInset = actionItem.titleMargin {
            titleLabel.snp.remakeConstraints { (maker) in
                if iconView.isHidden {
                    maker.left.equalToSuperview().offset(-titleMarginInset.left)
                } else {
                    maker.left.equalTo(iconView.snp.right).offset(titleMarginInset.left)
                }
                maker.right.equalToSuperview().offset(titleMarginInset.right)
                maker.top.equalToSuperview().offset(titleMarginInset.top)
                maker.height.equalTo(actionItem.titleHeight)
            }
        } else {
            titleLabel.snp.remakeConstraints { (maker) in
                if iconView.isHidden {
                    maker.left.equalTo(contentView)
                } else {
                    maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                }
                maker.top.right.equalTo(contentView)
                maker.height.equalTo(actionItem.titleHeight)
            }
        }

        contentLabel.text = actionItem.content
        if let color = actionItem.contentColor {
            contentLabel.textColor = color
        }
        if let config = actionItem.contentFontConfig {
            contentLabel.attributedText = NSAttributedString(string: contentLabel.text ?? "",
                                                             config: config,
                                                             alignment: titleLabel.textAlignment,
                                                             lineBreakMode: .byTruncatingTail,
                                                             textColor: contentLabel.textColor)
        }
        if let contentMarginInset = actionItem.contentMargin {
            contentLabel.snp.remakeConstraints { (maker) in
                if iconView.isHidden {
                    maker.left.equalToSuperview().offset(-contentMarginInset.left)
                } else {
                    maker.left.equalTo(iconView.snp.right).offset(contentMarginInset.left)
                }
                maker.top.equalTo(titleLabel.snp.bottom).offset(contentMarginInset.top)
                maker.right.equalToSuperview().offset(contentMarginInset.right)
                maker.height.equalTo(actionItem.contentHeight)
            }
        } else {
            contentLabel.snp.remakeConstraints { (maker) in
                if iconView.isHidden {
                    maker.left.equalToSuperview()
                } else {
                    maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                }
                maker.top.equalTo(titleLabel.snp.bottom)
                maker.right.equalToSuperview()
                maker.height.equalTo(actionItem.contentHeight)
            }
        }
        bottomSeparator.snp.remakeConstraints { (make) in
            make.right.left.bottom.equalToSuperview()
            make.height.equalTo(Layout.separatorHeightForDefault)
        }
    }

    private func configForIconLabelAndBadge(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        betaBackgroundView.isHidden = true
        betaLabel.isHidden = true
        contentLabel.isHidden = true
        titleLabel.textAlignment = .left
        warningView.isHidden = true
        badgeView.isHidden = false
        if let iconImage = actionItem.icon {
            iconView.isHidden = false
            iconView.image = iconImage
            iconView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(actionItem.iconSize)
                maker.left.equalTo(Layout.leftRightOffset)
                maker.centerY.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { (maker) in
                maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                maker.right.lessThanOrEqualToSuperview()
                maker.centerY.equalToSuperview()
            }
            badgeView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(titleLabel.snp.right).offset(6)
                make.size.equalTo(CGSize(width: 6, height: 6))
            }
        } else {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.left.equalToSuperview().offset(Layout.leftRightOffset)
                maker.right.lessThanOrEqualToSuperview()
                maker.centerY.equalToSuperview()
            }
            badgeView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(titleLabel.snp.right).offset(6)
                make.size.equalTo(CGSize(width: 6, height: 6))
            }
        }
        bottomSeparator.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.separatorHeightForIconLabel)
        }
    }

    private func configForIconAndLabel(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        badgeView.isHidden = true
        betaBackgroundView.isHidden = true
        betaLabel.isHidden = true
        contentLabel.isHidden = true
        titleLabel.textAlignment = .left
        warningView.isHidden = true
        if apperance.contentAlignment == .left {
            if let iconImage = actionItem.icon {
                iconView.isHidden = false
                iconView.image = iconImage
                iconView.snp.remakeConstraints { (maker) in
                    maker.size.equalTo(actionItem.iconSize)
                    maker.left.equalTo(Layout.leftRightOffset)
                    maker.centerY.equalToSuperview()
                }
                titleLabel.snp.remakeConstraints { (maker) in
                    maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                    maker.right.lessThanOrEqualToSuperview()
                    maker.centerY.equalToSuperview()
                }
            } else {
                titleLabel.snp.remakeConstraints { (maker) in
                    maker.left.equalToSuperview().offset(Layout.leftRightOffset)
                    maker.right.lessThanOrEqualToSuperview()
                    maker.centerY.equalToSuperview()
                }
            }
            bottomSeparator.snp.remakeConstraints { (make) in
                make.left.equalTo(titleLabel)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(Layout.separatorHeightForIconLabel)
            }
        } else if apperance.contentAlignment == .center {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = Layout.titleLeftOffset
            contentView.addSubview(stackView)
            stackView.snp.makeConstraints {
                $0.center.equalToSuperview()
            }
            if let iconImage = actionItem.icon {
                iconView.isHidden = false
                iconView.image = iconImage
                iconView.removeFromSuperview()
                stackView.addArrangedSubview(iconView)
                iconView.snp.remakeConstraints { (maker) in
                    maker.size.equalTo(actionItem.iconSize)
                }
                titleLabel.removeFromSuperview()
                stackView.addArrangedSubview(titleLabel)
            } else {
                titleLabel.snp.remakeConstraints { (maker) in
                    maker.center.equalToSuperview()
                }
            }
            bottomSeparator.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(Layout.titleLeftOffset)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(Layout.separatorHeightForIconLabel)
            }
        }
    }

    private func configForWarning(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        badgeView.isHidden = true
        betaBackgroundView.isHidden = true
        contentLabel.isHidden = true
        betaLabel.isHidden = true
        titleLabel.textAlignment = .left
        warningView.isHidden = false
        warningView.image = BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: CGSize(width: 20, height: 20))
        warningView.snp.remakeConstraints { (maker) in
            maker.size.equalTo(Layout.iconSize)
            maker.right.equalTo(-Layout.leftRightOffset)
            maker.centerY.equalToSuperview()
        }
        if let iconImage = actionItem.icon {
            iconView.isHidden = false
            iconView.image = iconImage
            iconView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(actionItem.iconSize)
                maker.left.equalTo(Layout.leftRightOffset)
                maker.centerY.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { (maker) in
                maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                maker.right.lessThanOrEqualTo(warningView.snp.left)
                maker.centerY.equalToSuperview()
            }
        } else {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.left.equalToSuperview().offset(Layout.titleLeftOffset)
                maker.right.lessThanOrEqualTo(warningView.snp.left)
                maker.centerY.equalToSuperview()
            }
        }
        bottomSeparator.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.separatorHeightForIconLabel)
        }
    }

    private func configForIconLabelAndBeta(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        badgeView.isHidden = true
        contentLabel.isHidden = true
        titleLabel.textAlignment = .left
        warningView.isHidden = true
        warningView.image = BundleResources.ByteView.ToolBar.disable_icon.vc.resized(to: CGSize(width: 20, height: 20))
        warningView.snp.remakeConstraints { (maker) in
            maker.size.equalTo(Layout.iconSize)
            maker.right.equalTo(-Layout.leftRightOffset)
            maker.centerY.equalToSuperview()
        }
        if let iconImage = actionItem.icon {
            iconView.isHidden = false
            iconView.image = iconImage
            iconView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(actionItem.iconSize)
                maker.left.equalTo(Layout.leftRightOffset)
                maker.centerY.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { (maker) in
                maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                maker.right.lessThanOrEqualTo(warningView.snp.left)
                maker.centerY.equalToSuperview()
            }
        } else {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.left.equalToSuperview().offset(Layout.titleLeftOffset)
                maker.right.lessThanOrEqualTo(warningView.snp.left)
                maker.centerY.equalToSuperview()
            }
        }
        betaBackgroundView.isHidden = false
        betaLabel.isHidden = false
        betaBackgroundView.snp.remakeConstraints { maker in
            maker.left.equalTo(titleLabel.snp.right).offset(4.0)
            maker.right.equalToSuperview().offset(-16.0)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(18.0)
        }
        betaLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(betaBackgroundView).inset(4.0)
            maker.centerY.height.equalTo(betaBackgroundView)
        }
        bottomSeparator.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.separatorHeightForIconLabel)
        }
    }

    private func configForCallIn(with actionItem: SheetAction, apperance: ActionSheetAppearance) {
        badgeView.isHidden = true
        betaBackgroundView.isHidden = true
        betaLabel.isHidden = true
        contentLabel.isHidden = true
        titleLabel.textAlignment = .left
        warningView.isHidden = true
        selectedIconView.image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 20, height: 20))
        if apperance.contentAlignment == .left {
            if let iconImage = actionItem.icon {
                iconView.isHidden = false
                iconView.image = iconImage
                iconView.snp.remakeConstraints { maker in
                    maker.size.equalTo(Layout.iconSize)
                    maker.left.equalTo(Layout.leftRightOffset)
                    maker.centerY.equalToSuperview()
                }
                titleLabel.snp.remakeConstraints { maker in
                    maker.left.equalTo(iconView.snp.right).offset(Layout.titleLeftOffset)
                    maker.right.lessThanOrEqualToSuperview()
                    maker.centerY.equalToSuperview()
                }
            }
            bottomSeparator.snp.remakeConstraints { make in
                make.left.equalTo(titleLabel)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(Layout.separatorHeightForIconLabel)
            }
        }
    }
}
