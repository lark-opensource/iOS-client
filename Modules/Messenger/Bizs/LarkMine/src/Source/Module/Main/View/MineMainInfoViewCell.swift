//
//  MineMainInfoViewCell.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/4/10.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkTag
import UniverseDesignTag
import UniverseDesignColor

final class MineMainInfoViewCell: BaseTableViewCell {

    fileprivate var iconImageView: UIImageView = .init(image: nil)
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var detailLabel: UILabel = .init()
    fileprivate var detailImage: UIImageView = .init(image: nil)
    fileprivate var updateImageTag: UDTag!
    fileprivate var badgeLabel: UILabel = .init()
    fileprivate var redDotView: UIView = .init()
    var badgeId: String?
    var dependency: MineSettingBadgeDependency?
    var badgeNumber: Int = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
        setBackViewLayout(UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8), 8)
        let iconImageView = UIImageView()
        self.iconImageView = iconImageView
        self.iconImageView.contentMode = .center
        self.contentView.addSubview(iconImageView)

        let titleLabel = UILabel()
        titleLabel.textAlignment = .left
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 1
        self.titleLabel = titleLabel
        self.contentView.addSubview(titleLabel)

        let detailImage = UIImageView()
        self.detailImage = detailImage
        self.contentView.addSubview(detailImage)
        detailImage.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(0)
        }

        let detailLabel = UILabel()
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.textAlignment = .right
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.detailLabel = detailLabel
        self.contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.detailImage.snp.left).offset(-5)
            make.centerY.equalTo(iconImageView)
            make.height.equalTo(20)
            make.width.equalTo(0)
        }

        /// 更新提示
        let updateImageTag = TagWrapperView.iconTagView(for: .newVersion)
        self.contentView.addSubview(updateImageTag)
        updateImageTag.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.right.equalTo(-16)
        }
        self.updateImageTag = updateImageTag
        self.updateImageTag.isHidden = true

        /// badge
        self.badgeLabel = UILabel()
        self.badgeLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.badgeLabel.font = UIFont.systemFont(ofSize: 12)
        self.badgeLabel.textAlignment = .center
        self.badgeLabel.backgroundColor = UIColor.ud.colorfulRed
        self.badgeLabel.layer.cornerRadius = 8
        self.badgeLabel.layer.masksToBounds = true
        self.badgeLabel.isHidden = true
        self.contentView.addSubview(self.badgeLabel)
        self.badgeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.width.height.equalTo(16)
            make.right.equalTo(-17.5)
        }

        self.redDotView = UIView()
        self.redDotView.isHidden = true
        self.redDotView.layer.cornerRadius = 4
        self.redDotView.backgroundColor = UIColor.ud.colorfulRed
        self.contentView.addSubview(self.redDotView)
        self.redDotView.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.width.height.equalTo(8)
            make.right.equalToSuperview().offset(-17)
        }

        backgroundColor = .clear
        setBackViewColor(.clear)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(icon: UIImage? = nil,
                    title: String? = nil,
                    addtionText: String? = nil,
                    addtionImage: UIImage? = nil,
                    badgeId: String? = nil,
                    dependency: MineSettingBadgeDependency? = nil,
                    showRedDot: Bool = false,
                    badgeNumber: Int = 0) {
        let content = title ?? ""
        self.iconImageView.image = icon
        self.titleLabel.text = content

        let titleLabelFirstLineCenterOffset = content.lu.height(font: UIFont.systemFont(ofSize: 16), width: CGFloat(MAXFLOAT)) / 2
        self.iconImageView.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.titleLabel.snp.top).offset(titleLabelFirstLineCenterOffset)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }

        setAddtion(text: addtionText)
        setAddtion(image: addtionImage)

        redDotView.isHidden = true
        updateImageTag.isHidden = true
        badgeLabel.isHidden = true

        // 先判断 badge num 类型
        if badgeNumber > 0 {
            badgeLabel.text = "\(badgeNumber)"
            badgeLabel.isHidden = false
        } else if let badgeId = badgeId, let dependency = dependency { // 再判断 badge 路径树规则
            let style = dependency.getBadgeStyle(badgeId: badgeId)
            switch style {
            case .upgrade:
                updateImageTag.isHidden = false
            case .dot:
                redDotView.isHidden = false
            case .label(_):
                break
            case .none:
                break
            }
        } else if showRedDot { // 后判断红点展示
            redDotView.isHidden = false
        }
    }

    private func setAddtion(text: String?) {
        self.detailLabel.text = text
        self.detailLabel.sizeToFit()
        if let text = text, !text.isEmpty {
            self.detailLabel.snp.updateConstraints { make in
                make.width.equalTo(self.detailLabel.frame.width)
            }
            self.titleLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(18)
                make.left.equalTo(48)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(self.detailLabel.snp.left).offset(-12)
            }
        } else {
            self.detailLabel.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
            self.titleLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(18)
                make.left.equalTo(48)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualToSuperview().offset(-20)
            }
        }
    }

    private func setAddtion(image: UIImage?) {
        if let image = image {
            self.detailImage.image = image.ud.withTintColor(UIColor.ud.iconN3)
            self.detailImage.isHidden = false
            self.detailImage.snp.updateConstraints { make in
                make.width.equalTo(16)
            }
        } else {
            self.detailImage.isHidden = true
            self.detailImage.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
