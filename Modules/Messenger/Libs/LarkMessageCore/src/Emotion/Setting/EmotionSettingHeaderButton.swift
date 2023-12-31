//
//  EmotionSettingTableViewHeaderCell.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/13.
//

import Foundation
import UIKit
import UniverseDesignColor

final class EmotionSettingHeaderButton: UIButton {

    lazy var arrorImageView: UIImageView = {
        let iamge = Resources.emotionSettingArrow.ud.withTintColor(UIColor.ud.iconN3)
        return UIImageView(image: iamge)
    }()

    lazy var mainTitleLabel: UILabel = {
        let mainTitleLabel = UILabel()
        mainTitleLabel.text = BundleI18n.LarkMessageCore.Lark_Legacy_StickerManager
        mainTitleLabel.font = UIFont.systemFont(ofSize: 16)
        mainTitleLabel.textColor = UIColor.ud.N900
        return mainTitleLabel
    }()

    lazy var heartIconImageView: UIImageView = {
        let iamge = Resources.emotionSettingHeartIcon.ud.withTintColor(UIColor.ud.iconN1)
        return UIImageView(image: iamge)
    }()

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    func setup() {
        self.addSubview(mainTitleLabel)
        self.addSubview(heartIconImageView)
        self.addSubview(arrorImageView)
        layout()
    }

    func layout() {
        self.heartIconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }

        self.mainTitleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(38)
        }

        self.arrorImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
