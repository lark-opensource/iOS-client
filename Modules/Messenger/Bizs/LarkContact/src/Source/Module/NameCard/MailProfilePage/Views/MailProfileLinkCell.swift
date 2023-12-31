//
//  MailProfileLinkCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/31.
//

import UIKit
import Foundation
import RustPB
import SwiftProtobuf
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignToast
import EENavigator
import LarkUIKit
import LarkCore
import LarkEMM
import LarkContainer

enum MailProfileLinkType {
    case unknown, calendar, profile, mail, h5, microApp
}

struct MailProfileLinkItem: MailProfileCellItem {
    var fieldKey: String

    var type: MailProfileCellType {
        return .link
    }

    var title: String

    var url: String

    var subTitle: String

    var linkType: MailProfileLinkType

    var accountType: String = "None"

    func handleClick(fromVC: UIViewController?, resolver: UserResolver) {
        guard let url = URL(string: url), let from = fromVC else {
            return
        }

        if linkType == .mail {
            if Display.pad {
                resolver.navigator.present(url,
                                         wrap: LkNavigationController.self,
                                         from: from,
                                         prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
            } else {
                resolver.navigator.push(url, from: from)
            }

            MailProfileStatistics.action(.clickAddress, accountType: accountType)
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
        if field.fieldType != .link {
            return nil
        }

        /// 兼容下发字段
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true

        if let link = try? NewUserProfile.Href(jsonString: field.jsonFieldVal, options: options),
            !link.title.i18NVals.isEmpty || !link.title.defaultVal.isEmpty,
            !link.link.i18NVals.isEmpty || !link.link.defaultVal.isEmpty {

            let url = setI18NVal(link.link, field: "")
            let item = MailProfileLinkItem(
                fieldKey: field.key,
                title: MailProfileLinkItem.setI18NVal(field.i18NNames, field: field.key),
                url: url,
                subTitle: setI18NVal(link.title, field: ""),
                linkType: MailProfileLinkItem.getLinkType(url: url)
            )
            return item
        }
        return nil
    }

    static func getLinkType(url: String) -> MailProfileLinkType {
        /// profile 前缀为：lark://client/profile
        var pattern = "lark://client/profile"
        if url.hasPrefix(pattern) {
            return .profile
        }

        /// 日历 前缀为：lark://client/calendar
        pattern = "lark://client/calendar"
        if url.hasPrefix(pattern) {
            return .calendar
        }

        /// 邮箱 前缀为：mailto:
        pattern = "mailto:"
        if url.hasPrefix(pattern) {
            return .mail
        }

        /// 小程序 前缀为：sslocal://microapp
        pattern = "sslocal://microapp"
        if url.hasPrefix(pattern) {
            return .microApp
        }

        /// h5为 http或者https
        pattern = "^http(s)?\\://([^.]+\\.)?/?([^/]+/)*"
        do {
            let urlRegexp = (try NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
            let range = NSRange(location: 0, length: url.count)
            if !urlRegexp.matches(in: url, options: [], range: range).isEmpty {
                return .h5
            }
        } catch {
            return .unknown
        }
        return .unknown
    }
}

final class MailProfileLinkCell: MailProfileBaseCell {
    override func commonInit() {
        super.commonInit()

        self.subTitleLabel.textColor = UIColor.ud.textLinkNormal
    }

    override func updateData() {
        super.updateData()

        guard let cellItem = item as? MailProfileLinkItem else {
            return
        }
        titleLabel.text = cellItem.title
        subTitleLabel.text = cellItem.subTitle
    }
}
