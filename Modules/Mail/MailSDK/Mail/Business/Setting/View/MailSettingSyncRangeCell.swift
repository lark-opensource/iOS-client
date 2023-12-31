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

protocol MailSettingSyncRangeCellDependency: AnyObject {
    func jumpSyncRangeSettingPage()
}

class MailSettingSyncRangeCell: MailSettingBaseCell {
    weak var dependency: MailSettingSyncRangeCellDependency?

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    @objc
    override func didClickCell() {
        if (item as? MailSettingSyncRangeModel) != nil {
            dependency?.jumpSyncRangeSettingPage()
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingSyncRangeModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.detail
        }
    }
}
