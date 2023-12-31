//
//  ProfileSectionNormalCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2022/1/5.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import EENavigator

public struct ProfileSectionNormalCellItem: ProfileSectionCellItem {
    public var title: String = ""
    public var subTitle: String = ""
    public var content: String = ""
    public var showPushIcon: Bool = false
    public var pushLink: String = ""

    public init(title: String = "",
                subTitle: String = "",
                content: String = "",
                showPushIcon: Bool = false,
                pushLink: String = "") {
        self.title = title
        self.subTitle = subTitle
        self.content = content
        self.showPushIcon = showPushIcon
        self.pushLink = pushLink
    }
}

public class ProfileSectionNormalCell: ProfileSectionTabCell {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 4
        label.textAlignment = .left
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.textAlignment = .left
        return label
    }()

    lazy var pushIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return imageView
    }()

    var titleWrapperView = UIView()
    var contentWrapperView = UIView()

    var item: ProfileSectionCellItem?

    override func commonInit() {
        super.commonInit()
        self.contentView.addSubview(titleWrapperView)
        self.contentView.addSubview(contentWrapperView)
        self.titleWrapperView.addSubview(titleLabel)
        self.titleWrapperView.addSubview(subTitleLabel)
        self.contentWrapperView.addSubview(contentLabel)
        self.contentWrapperView.addSubview(pushIconView)
        layoutView()
    }

    public func update(item: ProfileSectionCellItem) {
        self.item = item
        self.layoutView()
    }

    func layoutView() {
        guard let item = item else {
            return
        }

        titleLabel.numberOfLines = item.subTitle.isEmpty ? 4 : 2
        subTitleLabel.isHidden = item.subTitle.isEmpty
        contentLabel.isHidden = item.content.isEmpty
        pushIconView.isHidden = !item.showPushIcon

        titleLabel.text = item.title
        subTitleLabel.text = item.subTitle
        contentLabel.text = item.content

        titleWrapperView.snp.remakeConstraints { make in
            make.top.left.equalToSuperview().offset(Cons.hMargin)
            make.bottom.equalToSuperview().offset(-Cons.hMargin)
            if !item.content.isEmpty || item.showPushIcon {
                make.width.lessThanOrEqualToSuperview().multipliedBy(Cons.leftContentPercentage)
            } else {
                make.right.equalToSuperview().offset(-Cons.hMargin)
            }
        }

        titleLabel.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            if item.subTitle.isEmpty {
                make.bottom.equalToSuperview()
            }
        }

        if !item.subTitle.isEmpty {
            subTitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom)
                make.left.bottom.right.equalToSuperview()
            }
        }

        if !item.content.isEmpty || item.showPushIcon {
            contentWrapperView.isHidden = false
            contentWrapperView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(Cons.hMargin)
                make.bottom.right.equalToSuperview().offset(-Cons.hMargin)
                make.width.lessThanOrEqualToSuperview().multipliedBy(Cons.rightContentPercentage)
            }
        } else {
            contentWrapperView.isHidden = true
        }

        if item.showPushIcon {
            pushIconView.snp.remakeConstraints { make in
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalTo(16)
            }
        }

        contentLabel.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            if item.showPushIcon {
                make.right.equalTo(pushIconView.snp.left).offset(-4)
            } else {
                make.right.equalToSuperview()
            }
        }
    }

    public override func didTap(_ fromVC: UIViewController) {
        super.didTap(fromVC)
        guard let item = item, let url = try? URL.forceCreateURL(string: item.pushLink) else {
            return
        }
        self.navigator?.push(url, from: fromVC)
    }
}

extension ProfileSectionNormalCell {
    enum Cons {
        static var hMargin: CGFloat { 16 }
        static var leftContentPercentage: CGFloat { 194 / 343 }
        static var rightContentPercentage: CGFloat { 97 / 343 }
    }
}
