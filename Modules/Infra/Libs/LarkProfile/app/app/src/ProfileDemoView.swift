//
//  ProfileDemoView.swift
//  LarkProfileDev
//
//  Created by Hayden Wang on 2021/7/7.
//

import Foundation
import UIKit
import LarkProfile
import UniverseDesignColor
import UniverseDesignFont
import LarkTag
import RichLabel

class ProfileDemoView: UIView {

    /// Header 容器
    lazy var headerView = UIView()

    /// 可拉伸背景图
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    /// 个人信息容器
    private lazy var infoContentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        view.layer.cornerRadius = Cons.infoCornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    lazy var avatarView: ProfileAvatarView = {
        let avatar = ProfileAvatarView()
        avatar.borderColor = UIColor.ud.bgFloat
        avatar.borderWidth = 2.5
        avatar.layer.shadowOpacity = 1
        avatar.layer.shadowRadius = 3
        avatar.layer.shadowOffset = CGSize(width: 0, height: 3)
        avatar.ud.setLayerShadowColor(UIColor.ud.shadowDefaultSm)
        return avatar
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        let font = Cons.nameFont
        label.font = font
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 0
        return label
    }()

    private lazy var infoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 4
        return stack
    }()

    lazy var segmentedView: SegmentedTableView = {
        let tableView = SegmentedTableView()
        return tableView
    }()

    /// 公司
    lazy var companyView = CompanyAuthView()

    /// Badge

    lazy var tagContainer = UIView()

    lazy var tagView: TagWrapperView = {
        let view = TagWrapperView()
        return view
    }()

    /// 个人签名
    private lazy var statusContainer = UIView()

    lazy var statusLabel: LKLabel = {
        let label = LKLabel()
        let font = Cons.statusFont
        label.font = font
        label.lineSpacing = font.figmaHeight - font.pointSize
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.backgroundColor = .clear
        return label
    }()

    /// CTA buttons
    private lazy var buttonsContainer: UIView = {
        let view = UIView()
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 5
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.ud.setLayerShadowColor(UIColor.ud.shadowDefaultSm)
        return view
    }()

    lazy var buttonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 7
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(segmentedView)
        headerView.addSubview(backgroundImageView)
        headerView.addSubview(infoContentView)
        headerView.addSubview(avatarView)
        infoContentView.addSubview(nameLabel)
        infoContentView.addSubview(infoStack)
        tagContainer.addSubview(tagView)
        statusContainer.addSubview(statusLabel)
        buttonsContainer.addSubview(buttonsStack)
        infoStack.addArrangedSubview(companyView)
        infoStack.addArrangedSubview(tagContainer)
        infoStack.addArrangedSubview(statusContainer)
        infoStack.addArrangedSubview(buttonsContainer)
    }

    private func setupConstraints() {
        segmentedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(infoContentView.snp.top).offset(Cons.infoCornerRadius)
        }
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.centerY.equalTo(infoContentView.snp.top)
            make.width.height.equalTo(Cons.avatarSize)
        }
        infoContentView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(Cons.bgImageHeight - Cons.infoCornerRadius)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.avatarSize / 2 + 12)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(16)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
        }
        buttonsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        tagView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.leading.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        statusLabel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(4)
        }
    }

    private func setupAppearance() {
        nameLabel.text = "乔夏木乔夏木乔夏木乔夏木乔夏木乔夏木乔夏木乔夏木"
        statusLabel.text = "希望你在意外得到一件心仪之物时，还能有孩子般的雀跃和欣喜。在无奈失去一件所恋之物时，努力学长者"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
//        nameLabel.preferredMaxLayoutWidth = bounds.width - 2 * Cons.hMargin
        statusLabel.preferredMaxLayoutWidth = bounds.width - 2 * Cons.hMargin
//        if let text = nameLabel.text {
//            nameLabel.text = text
//        } else if let attrText = nameLabel.attributedText {
//            nameLabel.attributedText = attrText
//        }
        if let text = statusLabel.text {
            statusLabel.text = text
        } else if let attrText = statusLabel.attributedText {
            statusLabel.attributedText = attrText
        }
    }
}

extension ProfileDemoView {

    enum Cons {
        static var infoCornerRadius: CGFloat { 16 }
        static var nameFont: UIFont { UIFont.ud.title0 }
        static var statusFont: UIFont { UIFont.ud.body2 }
        static var avatarSize: CGFloat { 108 }
        static var hMargin: CGFloat { 16 }
        static var bgImageHeight: CGFloat { 196 }
    }
}
