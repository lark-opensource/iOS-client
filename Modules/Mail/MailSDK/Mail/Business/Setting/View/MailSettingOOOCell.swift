//
//  MailSettingOOOCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/23.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignIcon

protocol MailSettingOOOCellDependency: AnyObject {
    func jumpOOOSettingPage()
}

class MailSettingOOOCell: MailSettingBaseCell {
    weak var dependency: MailSettingOOOCellDependency?

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    @objc
    override func didClickCell() {
        if (item as? MailSettingOOOModel) != nil {
            dependency?.jumpOOOSettingPage()
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingOOOModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.status ? BundleI18n.MailSDK.Mail_Setting_EmailEnabled : BundleI18n.MailSDK.Mail_Setting_EmailNotEnabled
        }
    }
}
