//
//  MineTranslateDisplayCell.swift
//  LarkMine
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox

struct MineTranslateDisplayModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var status: Bool
    /// 目标语言的国际化文案
    var translateDoc: String?
    /// 原文文案
    var originDoc: String
    var switchHandler: MineTranslateSwitchHandler
}

/// 译文展示效果
final class MineTranslateDisplayCell: MineTranslateBaseCell {
    /// 是否选中
    private let leftSelectImageView = UDCheckBox(boxType: .single)
    private let rightSelectImageView = UDCheckBox(boxType: .single)
    private let leftSelectConfigView = UIView()
    private let rightSelectConfigView = UIView()
    private let originLabel = UILabel()
    private let leftTranslationLabel = UILabel()
    private let rightTranslationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        /// 灰色背景
        let leftGrayContentView = UIView()
        leftGrayContentView.layer.cornerRadius = 5
        leftGrayContentView.layer.masksToBounds = true
        leftGrayContentView.backgroundColor = UIColor.ud.bgFloatOverlay
        self.contentView.addSubview(leftGrayContentView)
        leftGrayContentView.snp.makeConstraints { (make) in
            make.top.equalTo(24)
            make.left.greaterThanOrEqualTo(16)
            make.centerX.equalToSuperview().multipliedBy(0.5)
        }
        /// 原文内容
        originLabel.numberOfLines = 2
        originLabel.font = UIFont.systemFont(ofSize: 16)
        originLabel.text = BundleI18n.LarkMine.Lark_Chat_TranslateStyleDemoOriginal
        originLabel.textColor = UIColor.ud.textTitle
        leftGrayContentView.addSubview(originLabel)
        originLabel.snp.makeConstraints { (make) in
            make.top.equalTo(12)
            make.left.equalTo(12)
            make.right.equalTo(-12)
        }
        /// 翻译分割线
        let spaceLine = UIView()
        spaceLine.backgroundColor = UIColor.ud.lineDividerDefault
        leftGrayContentView.addSubview(spaceLine)
        spaceLine.snp.makeConstraints { (make) in
            make.top.equalTo(originLabel.snp.bottom).offset(8)
            make.left.equalTo(10)
            make.right.equalTo(-12)
            make.height.equalTo(1)
        }
        /// 译文内容
        leftTranslationLabel.numberOfLines = 2
        leftTranslationLabel.font = UIFont.systemFont(ofSize: 16)
        leftTranslationLabel.text = BundleI18n.LarkMine.Lark_Chat_TranslateStyleDemoTranslation
        leftTranslationLabel.textColor = UIColor.ud.textPlaceholder
        leftGrayContentView.addSubview(leftTranslationLabel )
        leftTranslationLabel.snp.makeConstraints { (make) in
            make.top.equalTo(spaceLine.snp.bottom).offset(8)
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.bottom.equalTo(-12)
        }
        /// 标题
        let leftTitleLabel = UILabel()
        leftTitleLabel.numberOfLines = 2
        leftTitleLabel.textColor = UIColor.ud.textTitle
        leftTitleLabel.font = UIFont.systemFont(ofSize: 14)
        leftTitleLabel.textAlignment = .center
        leftTitleLabel.text = BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplayTranslationAndOriginal
        self.contentView.addSubview(leftTitleLabel)
        leftTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(leftGrayContentView.snp.bottom).offset(8)
            make.left.greaterThanOrEqualTo(12)
            make.right.lessThanOrEqualTo(-12)
            make.centerX.equalTo(leftGrayContentView.snp.centerX)
        }
        /// 图标
        self.contentView.addSubview(self.leftSelectImageView)
        self.leftSelectImageView.snp.makeConstraints { (make) in
            make.top.equalTo(leftTitleLabel.snp.bottom).offset(8)
            make.centerX.equalTo(leftTitleLabel.snp.centerX)
            make.bottom.equalTo(-24)
        }

        let leftTapGes = UITapGestureRecognizer(target: self, action: #selector(didSelectRadioStyle))
        self.leftSelectConfigView.addGestureRecognizer(leftTapGes)
        self.contentView.addSubview(self.leftSelectConfigView)
        self.leftSelectConfigView.snp.makeConstraints { (make) in
            make.center.equalTo(leftSelectImageView)
            make.width.height.equalTo(leftSelectImageView).multipliedBy(2)
        }

        /// Right Part
        /// 灰色背景
        let rightGrayContentView = UIView()
        rightGrayContentView.layer.cornerRadius = 5
        rightGrayContentView.layer.masksToBounds = true
        rightGrayContentView.backgroundColor = UIColor.ud.bgFloatOverlay
        self.contentView.addSubview(rightGrayContentView)
        rightGrayContentView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualTo(24)
            make.bottom.equalTo(leftGrayContentView.snp.bottom)
            make.left.greaterThanOrEqualTo(self.snp.centerX).offset(11)
            make.centerX.equalToSuperview().multipliedBy(1.5)
        }
        /// 译文内容
        rightTranslationLabel.numberOfLines = 2
        rightTranslationLabel.font = UIFont.systemFont(ofSize: 16)
        rightTranslationLabel.text = BundleI18n.LarkMine.Lark_Chat_TranslateStyleDemoTranslation
        rightTranslationLabel.textColor = UIColor.ud.textTitle
        rightGrayContentView.addSubview(rightTranslationLabel)
        rightTranslationLabel.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.top.equalTo(8)
            make.right.equalTo(-12)
            make.bottom.equalTo(-12)
        }

        /// 标题
        let rightTitleLabel = UILabel()
        rightTitleLabel.numberOfLines = 2
        rightTitleLabel.textColor = UIColor.ud.textTitle
        rightTitleLabel.font = UIFont.systemFont(ofSize: 14)
        rightTitleLabel.numberOfLines = 1
        rightTitleLabel.text = BundleI18n.LarkMine.Lark_NewSettings_TranslationDisplayTranslationOnly
        self.contentView.addSubview(rightTitleLabel)
        rightTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(rightGrayContentView.snp.bottom).offset(8)
            make.left.greaterThanOrEqualTo(12)
            make.right.lessThanOrEqualTo(-12)
            make.centerX.equalTo(rightGrayContentView.snp.centerX)
        }

        /// 图标
        self.contentView.addSubview(self.rightSelectImageView)
        self.rightSelectImageView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(leftSelectImageView)
            make.centerX.equalTo(rightTitleLabel.snp.centerX)
        }

        let rightTapGes = UITapGestureRecognizer(target: self, action: #selector(didSelectRadioStyle))
        self.rightSelectConfigView.addGestureRecognizer(rightTapGes)
        self.contentView.addSubview(self.rightSelectConfigView)
        self.rightSelectConfigView.snp.makeConstraints { (make) in
            make.center.equalTo(rightSelectImageView)
            make.width.height.equalTo(rightSelectImageView).multipliedBy(2)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didSelectRadioStyle(_ ges: UIGestureRecognizer) {
        guard var currItem = self.item as? MineTranslateDisplayModel else {
            return
        }
        let onlyTranslation = (ges.view == self.rightSelectConfigView)
        currItem.status = onlyTranslation
        currItem.switchHandler(onlyTranslation)
        leftSelectImageView.isSelected = !onlyTranslation
        rightSelectImageView.isSelected = onlyTranslation
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateDisplayModel else {
            return
        }
        if let translateDoc = currItem.translateDoc,
            !translateDoc.isEmpty {
            self.leftTranslationLabel.text = translateDoc
            self.rightTranslationLabel.text = translateDoc
        }
        self.originLabel.text = currItem.originDoc
        self.leftSelectImageView.isSelected = currItem.status
        self.rightSelectImageView.isSelected = !currItem.status
    }
}
