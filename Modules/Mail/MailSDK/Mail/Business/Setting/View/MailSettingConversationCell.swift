//
//  MailSettingConversationCell.swift
//  MailSDK
//
//  Created by li jiayi on 2021/10/14.
//

import Foundation
import UIKit
import UniverseDesignIcon

protocol MailSettingConverstionCellDependency: AnyObject {
    func jumpConversationPage()
}

class MailSettingConversationCell: MailSettingBaseCell {
    weak var dependency: MailSettingConverstionCellDependency?
    
    override func setupViews() {
        super.setupViews()
    }

    @objc
    override func didClickCell() {
        if (item as? MailSettingConversationModel) != nil {
            dependency?.jumpConversationPage()
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingConversationModel {
            titleLabel.text = currItem.title
            statusLabel.isHidden = currItem.detail.isEmpty
            statusLabel.text = currItem.detail
            if !currItem.detail.isEmpty {
                titleLabel.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview().offset(16)
                    make.left.equalToSuperview().offset(16)
                    make.right.equalToSuperview().offset(-60)
                    make.height.equalTo(22)
                }
                statusLabel.numberOfLines = 0
                statusLabel.snp.remakeConstraints { (make) in
                    make.left.equalTo(titleLabel)
                    make.top.equalTo(titleLabel.snp.bottom).offset(2)
                    make.right.equalToSuperview().offset(-60)
                    make.bottom.equalTo(contentView.snp.bottom).offset(-13)
                }
            } else {
                titleLabel.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview().offset(16)
                    make.left.equalToSuperview().offset(16)
                    make.right.equalToSuperview().offset(-60)
                    make.bottom.equalToSuperview().offset(-16)
                }
                statusLabel.snp.remakeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.right.equalTo(arrowImageView.snp.left).offset(-7)
                }
            }
        }
    }
}
