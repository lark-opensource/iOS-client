//
//  MailProfileNormalCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/29.
//

import UIKit
import Foundation
import RustPB
import SwiftProtobuf
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignToast
import LarkEMM
import LarkContainer

struct MailProfileNormalItem: MailProfileCellItem {
    var fieldKey: String

    var type: MailProfileCellType {
        return .normal
    }

    var title: String

    var subTitle: String

    static func creatItemByField(_ field: NewUserProfile.Field) -> MailProfileCellItem? {
        if field.fieldType != .text {
            return nil
        }

        /// 兼容下发字段
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true

        if let text = try? NewUserProfile.Text(jsonString: field.jsonFieldVal, options: options) {
            let item = MailProfileNormalItem(
                fieldKey: field.key,
                title: setI18NVal(field.i18NNames, field: field.key),
                subTitle: setI18NVal(text.text, field: "")
            )
            return item
        }
        return nil
    }

    func handleClick(fromVC: UIViewController?, resolver: UserResolver) {}

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
}

final class MailProfileNormalCell: MailProfileBaseCell {

    override func commonInit() {
        super.commonInit()
    }

    override func updateData() {
        super.updateData()

        guard let cellItem = item as? MailProfileNormalItem else {
            return
        }
        titleLabel.text = cellItem.title
        subTitleLabel.text = cellItem.subTitle
    }
}
