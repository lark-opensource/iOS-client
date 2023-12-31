//
//  ConfigAreaCell.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/23.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class ListTableCell: UITableViewCell {
    static var identifier: String = "identifier"

    private var icon: UIImage? {
        didSet {
            guard let icon = icon else {
                iconView.isHidden = true
                return
            }
            iconView.isHidden = false
            iconView.image = icon
        }
    }

    private var title: String? {
        didSet {
            guard let title = title else {
                titleLabel.isHidden = true
                return
            }
            titleLabel.isHidden = false
            titleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .baselineOffset: titleBaselineOffset,
                    .paragraphStyle: titleMutableParagraphStyle,
                    .font: ShareCons.configTitleFont,
                    .foregroundColor: ShareColor.configTitleColor
                ]
              )
        }
    }

    private var subTitle: String? {
        didSet {
            guard let subTitle = subTitle else {
                subTitleLabel.isHidden = true
                return
            }
            subTitleLabel.isHidden = false
            subTitleLabel.attributedText = NSAttributedString(
                string: subTitle,
                attributes: [
                    .baselineOffset: subTitleBaselineOffset,
                    .paragraphStyle: subTitleMutableParagraphStyle,
                    .font: ShareCons.configSubTitleFont,
                    .foregroundColor: ShareColor.configSubTitleColor
                ]
              )
        }
    }

    private var customView: UIView? = UIView() {
        didSet {
            guard let customView = customView else {
                self.rightCustomView.isHidden = true
                return
            }
            oldValue?.removeFromSuperview()
            self.rightCustomView.isHidden = false
            self.rightCustomView.addSubview(customView)
            customView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview()
            }
        }
    }
    private let titleBaselineOffset = (ShareCons.configTitleFontHeight - ShareCons.configTitleFont.lineHeight) / 2.0 / 2.0
    private let titleMutableParagraphStyle: NSMutableParagraphStyle = {
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = ShareCons.configTitleFontHeight
        mutableParagraphStyle.maximumLineHeight = ShareCons.configTitleFontHeight
        mutableParagraphStyle.alignment = .left
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail
        return mutableParagraphStyle
    }()

    private let subTitleBaselineOffset = (ShareCons.configSubTitleFontHeight - ShareCons.configSubTitleFont.lineHeight) / 2.0 / 2.0
    private let subTitleMutableParagraphStyle: NSMutableParagraphStyle = {
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = ShareCons.configSubTitleFontHeight
        mutableParagraphStyle.maximumLineHeight = ShareCons.configSubTitleFontHeight
        mutableParagraphStyle.alignment = .left
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail
        return mutableParagraphStyle
    }()

    private lazy var iconView: UIImageView = {
        let icon = UIImageView()
        return icon
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.numberOfLines = 1
        return label
    }()

    private lazy var rightIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.getIconByKey(.rightBoldOutlined,
                                         iconColor: ShareColor.configRightIconColor)
        return icon
    }()

    private lazy var mainContainer: UIStackView = {
        let mainContainer = UIStackView()
        mainContainer.axis = .horizontal
        mainContainer.spacing = ShareCons.configDefaultSpacing
        mainContainer.alignment = .center
        return mainContainer
    }()

    private lazy var titleContainer: UIStackView = {
        let titleContainer = UIStackView()
        titleContainer.axis = .vertical
        titleContainer.spacing = ShareCons.configtitleSubtitleSpacing
        titleContainer.alignment = .leading
        return titleContainer
    }()

    private lazy var rightCustomView: UIView = {
        let customView = UIView()
        return customView
    }()

    private var divideLine: UIView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    // MARK: func
    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubViews() {
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(subTitleLabel)
        mainContainer.addArrangedSubview(iconView)
        mainContainer.addArrangedSubview(titleContainer)
        mainContainer.addArrangedSubview(rightCustomView)
        mainContainer.addArrangedSubview(rightIcon)
        self.contentView.addSubview(mainContainer)
        self.contentView.addSubview(divideLine)

    }

    private func setupConstraints() {
        mainContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ShareCons.defaultSpacing)
            make.trailing.equalToSuperview().inset(ShareCons.defaultSpacing)
            make.top.equalToSuperview().offset(ShareCons.configTitleTopAndBottomMargin)
            make.bottom.equalToSuperview().inset(ShareCons.configTitleTopAndBottomMargin)
        }
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(ShareCons.configLeftIconWidth)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        titleContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
        }
        rightCustomView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.width.lessThanOrEqualTo(ShareCons.configCustomViewWidth)
        }
        rightIcon.snp.makeConstraints { make in
            make.width.height.equalTo(ShareCons.configRightIconWidth)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        divideLine.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(ShareCons.panelDivideLineHeight)
            make.leading.equalTo(titleContainer.snp.leading)
        }
    }

    private func setupAppearance() {
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        self.backgroundColor = ShareColor.configBackgroundColor
        self.divideLine.backgroundColor = ShareColor.panelDivideLineColor
        self.rightCustomView.isHidden = true
        let selectBackground = UIView()
        selectBackground.backgroundColor = ShareColor.configCellPressColor
        self.selectedBackgroundView = selectBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.icon = nil
        self.title = nil
        self.subTitle = nil
        self.rightCustomView.isHidden = true
        self.customView?.removeFromSuperview()
        self.rightIcon.isHidden = false
        self.divideLine.isHidden = false
    }

    func configure(item: ShareSettingItem, isDivideLineHidden: Bool = false) {
        self.icon = item.icon
        self.title = item.title
        self.subTitle = item.subTitle
        self.customView = item.customView
        self.rightIcon.isHidden = item.handler == nil
        self.divideLine.isHidden = isDivideLineHidden
        self.isUserInteractionEnabled = !self.rightIcon.isHidden
    }

}
