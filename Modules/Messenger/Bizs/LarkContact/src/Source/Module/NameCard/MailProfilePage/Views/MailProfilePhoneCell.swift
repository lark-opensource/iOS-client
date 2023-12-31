//
//  MailProfilePhoneCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2022/1/3.
//

import UIKit
import Foundation
import RustPB
import SwiftProtobuf
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignToast
import LarkFoundation
import LarkEMM
import LarkContainer

struct MailProfilePhoneItem: MailProfileCellItem {
    var fieldKey: String

    var type: MailProfileCellType {
        return .phone
    }

    var title: String

    var subTitle: String

    var countryCode: String

    func handleClick(fromVC: UIViewController?, resolver: UserResolver) {
        guard let fromVC = fromVC else {
            return
        }

        if !subTitle.isEmpty {
            let responseNumber = subTitle.replacingOccurrences(of: "-", with: "")
            self.telecall(phoneNumber: responseNumber)
        }
    }

    func handleLongPress(fromVC: UIViewController?) {
        if ContactPasteboard.writeToPasteboard(string: subTitle) {
            if let window = fromVC?.view.window {
                UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_Legacy_Copied, on: window)
            }
        } else {
            if let window = fromVC?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
            }
        }
    }

    static func creatItemByField(_ field: NewUserProfile.Field) -> MailProfileCellItem? {
        if field.fieldType != .sPhoneNumber {
            return nil
        }

        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true

        if let phoneNumber = try? NewUserProfile.PhoneNumber(jsonString: field.jsonFieldVal, options: options),
            !phoneNumber.number.isEmpty {
            let item = MailProfilePhoneItem(
                fieldKey: field.key,
                title: setI18NVal(field.i18NNames, field: field.key),
                subTitle: phoneNumber.number,
                countryCode: phoneNumber.countryCode
            )
            return item
        }
        return nil
    }

    private func telecall(phoneNumber: String) {
        let responseNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
        LarkFoundation.Utils.telecall(phoneNumber: responseNumber)
    }
}

final class MailProfilePhoneCell: MailProfileBaseCell {
    override func commonInit() {
        super.commonInit()
        self.subTitleLabel.textColor = UIColor.ud.colorfulBlue
        /// Profile 手机号按单词展示有问题
        // swiftlint:disable ban_linebreak_byChar
        self.subTitleLabel.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
    }

    override func updateData() {
        super.updateData()

        guard let cellItem = item as? MailProfilePhoneItem else {
            return
        }
        titleLabel.text = cellItem.title
        subTitleLabel.text = cellItem.subTitle
    }
}
