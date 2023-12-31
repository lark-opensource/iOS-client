//
//  MailSettingStatusCell.swift
//  MailSDK
//
//  Created by majx on 2020/8/28.
//

import Foundation
import RxSwift
import UniverseDesignIcon

protocol MailSettingStatusCellDependency: AnyObject {
    func jumpUndoSettingPage()
    func jumpToPushSettingPage()
    func jumpToAttachmentSettingPage()
    func jumpToClientAdSettingPage(_ accID: String?)
    func jumpToClientAliasSettingPage(_ accID: String?)
    func jumpToSwipeActionsSettingPage()
    func jumpToWebImageDisplaySettingPage(_ accID: String?)
    func jumpToAutoCCSettingPage()
    func jumpToAliasSettingPage(_ accID: String)
}

class MailSettingStatusCell: MailSettingBaseCell {
    let disposeBag = DisposeBag()
    weak var dependency: MailSettingStatusCellDependency?

    @objc
    override func didClickCell() {
        if (item as? MailSettingUndoModel) != nil {
            dependency?.jumpUndoSettingPage()
        } else if (item as? MailSettingPushModel) != nil {
            dependency?.jumpToPushSettingPage()
        } else if item is MailSettingAttachmentModel {
            dependency?.jumpToAttachmentSettingPage()
        } else if let currItem = item as? MailSettingServerConfigModel {
            dependency?.jumpToClientAdSettingPage(currItem.accountId)
        } else if let currItem = item as? MailSettingSenderAliasModel {
            dependency?.jumpToClientAliasSettingPage(currItem.accountId)
        } else if item is MailSettingSwipeActionsModel {
            dependency?.jumpToSwipeActionsSettingPage()
        } else if let currItem = item as? MailSettingWebImageModel {
            dependency?.jumpToWebImageDisplaySettingPage(currItem.accountId)
        } else if let currItem = item as? MailSettingAutoCCModel {
            dependency?.jumpToAutoCCSettingPage()
        } else if let currItem = item as? MailAliasSettingModel {
            dependency?.jumpToAliasSettingPage(currItem.accountId)
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingUndoModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.status ? BundleI18n.MailSDK.Mail_Setting_EmailEnabled : BundleI18n.MailSDK.Mail_Setting_EmailNotEnabled
        } else if let currItem = item as? MailSettingPushModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.status ? BundleI18n.MailSDK.Mail_Setting_EmailEnabled : BundleI18n.MailSDK.Mail_Setting_EmailNotEnabled
            statusLabel.isHidden = false
        } else if let currItem = item as? MailSettingAttachmentModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.location == .top
                ? BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_Above_Checkbox
                : BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_Below_Checkbox
            statusLabel.isHidden = false
        } else if let currItem = item as? MailSettingServerConfigModel {
            titleLabel.text = currItem.title
            statusLabel.isHidden = true
        } else if let currItem = item as? MailSettingSenderAliasModel {
            titleLabel.text = currItem.title
            statusLabel.isHidden = true
        } else if let currItem = item as? MailSettingSwipeActionsModel {
            titleLabel.text = currItem.title
            statusLabel.isHidden = true
        } else if let currItem = item as? MailSettingWebImageModel {
            titleLabel.text = BundleI18n.MailSDK.Mail_Settings_ExterImages_Title
            statusLabel.isHidden = false
            statusLabel.text = currItem.statusTitle
        } else if let currItem = item as? MailSettingAutoCCModel {
            titleLabel.text = currItem.title
            statusLabel.isHidden = false
            statusLabel.text = currItem.status ? BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Enabled : BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Disabled
        } else if let currItem = item as? MailAliasSettingModel {
            titleLabel.text = currItem.title
            statusLabel.isHidden = true
        }
    }
}
