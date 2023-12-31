//
//  CalendarEventShareConfirmFooter.swift
//  LarkForward
//
//  Created by zhu chao on 2018/8/19.
//

import UIKit
import Foundation

final class CalendarEventShareConfirmFooter: BaseForwardConfirmFooter {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(message: String, subMessage: String, image: UIImage) {
        super.init()
        let imgView = UIImageView()
        imgView.image = image
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.top).offset(4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        nameLabel.text = message
        let subLabel = UILabel()
        self.layoutSubLabel(subLabel: subLabel, text: subMessage, iconView: imgView)
    }

    private func layoutSubLabel(subLabel: UILabel, text: String, iconView: UIImageView) {
        self.addSubview(subLabel)
        subLabel.numberOfLines = 2
        subLabel.textColor = UIColor.ud.N500
        subLabel.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(subLabel)
        subLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(iconView.snp.bottom).offset(-4)
            make.left.equalTo(iconView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        subLabel.text = text
    }
}
