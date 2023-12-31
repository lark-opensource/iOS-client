//
//  MailSettingAttachmentsCell.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/8.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignIcon

protocol MailSettingAttachmentsCellDependency: AnyObject {
    func jumpAttachmentsSettingPage()
}

class MailSettingAttachmentsCell: MailSettingBaseCell {
    weak var dependency: MailSettingAttachmentsCellDependency?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    @objc
    override func didClickCell() {
        if (item as? MailSettingAttachmentsModel) != nil {
            dependency?.jumpAttachmentsSettingPage()
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingAttachmentsModel {
            titleLabel.text = currItem.title
            statusLabel.text = FileSizeHelper.memoryFormat(UInt64(currItem.byte), useAbbrByte: true, spaceBeforeUnit: true)
        }
    }
    
    func refreshCapacity() {
        if let currItem = item as? MailSettingAttachmentsModel {
            statusLabel.text = FileSizeHelper.memoryFormat(UInt64(currItem.byte), useAbbrByte: true, spaceBeforeUnit: true)
        }
    }
}

