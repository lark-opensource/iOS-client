//
//  MailGroupPickerRouter.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/15.
//

import Foundation
import LarkUIKit
import LarkTag
import LarkSDKInterface
import RustPB
import UniverseDesignDialog
import UniverseDesignToast
import UIKit
import UniverseDesignColor

enum MailGroupHelper {
    static private let colorList: [UIColor] = [
        UIColor.ud.colorfulBlue,
        UIColor.ud.colorfulWathet,
        UIColor.ud.colorfulOrange,
        UIColor.ud.colorfulRed,
        UIColor.ud.colorfulViolet,
        UIColor.ud.colorfulIndigo,
        UIColor.ud.colorfulLime
    ]

    static private func getRGBValue(key: String) -> UIColor {
        if key.count > 1 {
            let length: Float = Float(key.count)
            var indexs: [Int] = [Int(0), Int(floor(length / 2)), Int(length - 1)]
            var i: Int = 0
            var rgbSum = key.unicodeScalars.filter {_ in
                let pre = i
                i += 1
                return indexs.contains(pre)
            }
            .map { Int($0.value) }
            .reduce(0, +)
            let index = rgbSum % colorList.count
            return colorList[index]
        }
        /// default is blue
        return colorList.first ?? UIColor.ud.B400
       }

    static func generateAvatarImage(withNameString string: String, shouldPrefix: Bool = false) -> UIImage? {
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.ud.primaryOnPrimaryFill
        attribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 50, weight: .medium)
        let name = shouldPrefix ? string.prefix(2).uppercased() : string
        let nameString = NSAttributedString(string: name, attributes: attribute)
        let stringSize = nameString.boundingRect(with: CGSize(width: 110.0, height: 110.0),
                                                 options: .usesLineFragmentOrigin,
                                                 context: nil)
        let padding: CGFloat = 35
        let width = max(stringSize.width, stringSize.height) + padding * 2
        let size = CGSize(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: size.width / 2.0)

        let bgColor = getRGBValue(key: string)
        bgColor.setFill()
        path.fill()
        nameString.draw(at: CGPoint(x: (size.width - stringSize.width) / 2.0,
                                    y: (size.height - stringSize.height) / 2.0))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func generateAvatarImage(withIcon icon: UIImage,
                                    size defaultSize: CGSize? = nil,
                                    bgColor: UIColor = UIColor.ud.indigo) -> UIImage? {
        let tintedImage = icon.ud.colorize(color: .ud.primaryOnPrimaryFill)
        let padding: CGFloat = 8.0    // 10.0
        let size = defaultSize ?? CGSize(width: 32, height: 32)
        let iconWidth = size.width - padding * 2
        let iconHeight = iconWidth * icon.size.height / icon.size.width
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: size.width / 2.0)
        bgColor.setFill()
        path.fill()
        UIColor.ud.primaryOnPrimaryFill.set() // 用白色
        tintedImage.withRenderingMode(.alwaysTemplate)
            .draw(in: CGRect(x: padding, y: (size.height - iconHeight) / 2, width: iconWidth, height: iconHeight))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func createTag(status: MailContactGroup.Status,
                          external: Bool,
                          company: Bool) -> [Tag]? {
        var tags: [Tag] = []
        if company {
            let tag = Tag(type: .allStaff, style: Style(textColor: UIColor.ud.udtokenTagNeutralTextNormal,
                                                        backColor: UIColor.ud.udtokenTagNeutralBgNormal))
            tags.append(tag)
        }
        if external {
            tags.append(Tag(type: .external))
        }
        if status == .deactive {
            let tag = Tag(title: BundleI18n.LarkContact.Mail_MailingList_Disabled,
                          style: .red,
                          type: .customTitleTag)
            tags.append(tag)
        }
        return tags.isEmpty ? nil : tags
    }

    static func createTag(status: Email_Client_V1_MailGroupMemberStatus, external: Bool) -> [Tag]? {
        var tags: [Tag] = []
        if external {
            tags.append(Tag(type: .external))
        }
        if status == .deactive {
            let tag = Tag(title: BundleI18n.LarkContact.Mail_MailingList_Disabled,
                          style: .red,
                          type: .customTitleTag)
            tags.append(tag)
        }
        return tags.isEmpty ? nil : tags
    }

    static func createTag(memberType: Email_Client_V1_GroupMemberType) -> [Tag]? {
        var tags: [Tag] = []
        if memberType == .dynamicUserGroup {
            let tag = Tag(title: BundleI18n.LarkContact.Mail_Shared_SupportAssignedAndDynamicGroups_Dynamic_Tag,
                          style: .purple,
                          type: .customTitleTag)
            tags.append(tag)
        }
        return tags.isEmpty ? nil : tags
    }

    static func createTitle(role: MailGroupRole) -> String {
        switch role {
        case .member:
            return BundleI18n.LarkContact.Mail_MailingList_MailingListMembers
        case .manager:
            return BundleI18n.LarkContact.Mail_MailingList_MailingListAdmin
        case .permission:
            return BundleI18n.LarkContact.Mail_MailingList_WhoCanSendToMailingList
        @unknown default: break
        }
        return ""
    }

    static func createPermissionTitle(permission: MailContactGroup.PermissionType) -> String {
        switch permission {
        case .internalMember:
            return BundleI18n.LarkContact.Mail_MailingList_AllMembersInOrg
        case .groupMember:
            return BundleI18n.LarkContact.Mail_MailingList_MailingListMembersOnly
        case .custom:
            return BundleI18n.LarkContact.Mail_MailingList_PartMembersInOrg
        case .all:
            return BundleI18n.LarkContact.Mail_MailingList_AllMembers
        case .unknownPermissionType:
            return ""
        @unknown default: break
        }
        return ""
    }

    static func mailGroupErrorIfNeed(error: Error) -> MailGroupReqError {
        if let error = error.underlyingError as? APIError {
            return MailGroupReqError(rawValue: Int(error.code)) ?? .other
        } else {
            return .other
        }
    }

    static func mailCommonSectionHeader(text: String) -> UIView {
        let header = UIView()
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 14)
        title.textColor = UIColor.ud.textCaption
        title.text = text
        header.addSubview(title)
        title.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 20, bottom: 4, right: 20))
        }
        return header
    }
}

extension MailGroupReqError {
    func tipsAction(from: UIViewController) {
        switch self {
        case .noPermission:
            let dialog = UDDialog()
            dialog.setContent(text: BundleI18n.LarkContact.Mail_MailingList_AdminPermissionClosed)
            dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
            from.present(dialog, animated: true, completion: nil)
        case .other:
            UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ActionFailedTryAgainLater,
                                on: from.view)
        @unknown default: break
        }
    }
}
