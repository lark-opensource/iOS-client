//
//  MailSettingCacheCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/28.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignIcon

protocol MailSettingCacheCellDependency: AnyObject {
    func jumpCacheSettingPage()
}

class MailSettingCacheCell: MailSettingBaseCell {
    weak var dependency: MailSettingCacheCellDependency?

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    @objc
    override func didClickCell() {
        if (item as? MailSettingCacheModel) != nil {
            dependency?.jumpCacheSettingPage()
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingCacheModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.detail
        }
    }

    func refreshStatus() {
        if let currItem = item as? MailSettingCacheModel {
            statusLabel.text = currItem.detail
        }
    }
}
