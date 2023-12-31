//
//  FeedBadgeStyleConfigureView.swift
//  Lark
//
//  Created by 姚启灏 on 2018/7/2.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkBadge

final class FeedBadgeStyleConfigureView: UIView {
    /// 单选按钮
    var radioImageView: UIImageView = .init(image: nil)
    /// 按钮右边的名字
    var radioTitleLabel: UILabel = .init()
    /// 背景图
    var backgroundView: UIView = .init()
    /// 通知标记图
    var noticeImageView: UIImageView = .init(image: nil)
    /// 通知标题
    var noticeTitleLabel: UILabel = .init()
    /// 通知详情
    var noticeDetailLabel: UILabel = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
        /// 单选按钮
        self.radioImageView = UIImageView()
        self.addSubview(self.radioImageView)
        self.radioImageView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalToSuperview()
        }

        /// 按钮右边的名字
        self.radioTitleLabel = UILabel()
        self.radioTitleLabel.textColor = UIColor.ud.textTitle
        self.radioTitleLabel.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(self.radioTitleLabel)
        self.radioTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(46)
            make.centerY.equalTo(self.radioImageView)
        }

        /// 背景图
        self.backgroundView = UIView()
        self.backgroundView.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        self.backgroundView.layer.borderWidth = 1
        self.backgroundView.layer.masksToBounds = true
        self.backgroundView.layer.cornerRadius = 4
        self.addSubview(self.backgroundView)
        self.backgroundView.snp.makeConstraints { (make) in
            make.left.equalTo(46)
            make.right.equalTo(-16)
            make.height.equalTo(68)
            make.top.equalTo(30)
        }

        /// 通知标记图
        self.noticeImageView = UIImageView()
        self.backgroundView.addSubview(self.noticeImageView)
        self.noticeImageView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        /// 通知标题
        self.noticeTitleLabel = UILabel()
        self.noticeTitleLabel.textColor = UIColor.ud.textTitle
        self.noticeTitleLabel.font = UIFont.systemFont(ofSize: 17)
        self.backgroundView.addSubview(self.noticeTitleLabel)
        self.noticeTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(84)
            make.top.equalTo(11.5)
        }

        /// 通知详情
        self.noticeDetailLabel = UILabel()
        self.noticeDetailLabel.font = UIFont.systemFont(ofSize: 14)
        self.noticeDetailLabel.textColor = UIColor.ud.textPlaceholder
        self.backgroundView.addSubview(self.noticeDetailLabel)
        self.noticeDetailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(noticeTitleLabel.snp.left)
            make.right.equalTo(-16)
            make.bottom.equalTo(-11.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MuteShowConfigureView: UIView {
    /// 单选按钮
    var selectedImageView: UIImageView = .init(image: nil)
    /// 按钮右边的名字
    var titleLabel: UILabel = .init()
    /// 通知标记图
    var imageView: UIImageView = .init(image: nil)
    let badgeView = BadgeView(with: .label(.number(0)))

    /// 通知标题
    var tabLabel: UILabel = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
        /// 单选按钮
        self.selectedImageView = UIImageView()
        self.addSubview(self.selectedImageView)
        self.selectedImageView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalToSuperview()
        }

        /// 按钮右边的名字
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(46)
            make.centerY.equalTo(self.selectedImageView)
        }

        /// 通知标记图
        self.imageView = UIImageView()
        self.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel).offset(14)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        badgeView.isHidden = true
        self.addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.centerX.equalTo(imageView.snp.trailing).offset(2)
            make.centerY.equalTo(imageView.snp.top).offset(2)
        }

        /// 通知标题
        self.tabLabel = UILabel()
        self.tabLabel.textColor = UIColor.ud.textTitle
        self.tabLabel.font = UIFont.systemFont(ofSize: 10)
        self.addSubview(self.tabLabel)
        self.tabLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(imageView)
            make.top.equalTo(imageView.snp.bottom).offset(7)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
