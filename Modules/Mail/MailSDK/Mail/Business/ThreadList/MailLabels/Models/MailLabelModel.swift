//
//  MailLabel.swift
//  MailSDK
//
//  Created by majx on 2019/7/16.
//

import Foundation
import RustPB
import LKCommonsLogging
import UniverseDesignIcon

enum MailLabelModelMailClientType {
    case larkMail
    case googleMail
}

extension Email_Client_V1_Label {
    var labelModelMailClientType: MailLabelModelMailClientType {
        switch emailClientType {
        case .googleMail:
            return .googleMail
        @unknown default:
            return .larkMail
        }
    }
}

extension MailFilterLabelCellModel {
    var emailClientType: Email_Client_V1_Label.EmailClientType {
        switch mailClientType {
        case .googleMail:
            return .googleMail
        default:
            return .larkMail
        }
    }
}
// var modelType: RustPB.Email_Client_V1_Label.ModelType

enum MailTagType: Int {
    case label = 0
    case folder
}

extension Email_Client_V1_Label { // }.ModelType {
    var tagType: MailTagType {
        switch modelType {
        case .label:
            return .label
        case .folder:
            return .folder
        @unknown default:
            return .label
        }
    }
}

extension MailFilterLabelCellModel {
    var modelType: Email_Client_V1_Label.ModelType {
        switch tagType {
        case .label:
            return .label
        case .folder:
            return .folder
        }
    }
}

enum MailLabelBadgeStyle {
    case none
    case number
}

protocol MailLabelModel {
    var labelId: String { get set }
    var icon: UIImage? { get set }
    var text: String { get set }
    var selected: Bool { get set }
    var fontColor: UIColor? { get set }
    var bgColor: UIColor? { get set }
    var fontColorHex: String? { get set }
    var bgColorHex: String? { get set }
    var badge: Int? { get set }
    var isSystem: Bool { get set }
    var mailClientType: MailLabelModelMailClientType { get set }
    var canShow: Bool { get set }
    var textNames: [String] { get set }
    var parentID: String { get set }
    var idNames: [String] { get set }
    var badgeStyle: MailLabelBadgeStyle { get set }
    var userOrderedIndex: Int64 { get set }
    var tagType: MailTagType { get set }
    var colorType: MailLabelTransformer.LabelColorType { get set }
}

// extension Email_Client_V1_Label: MailLabelModel {
//    var labelId: String {
//        return
//    }
//
// }

let Mail_LabelId_Unknow: String = "FILTER_UNKNOWN"
let Mail_LabelId_Inbox: String = "INBOX"
let Mail_LabelId_Important: String = "IMPORTANT"
let Mail_LabelId_Other: String = "OTHER"
let Mail_LabelId_Archived: String = "ARCHIVED"
let Mail_LabelId_Spam: String = "SPAM"
let Mail_LabelId_Sent: String = "SENT"
let Mail_LabelId_Draft: String = "DRAFT"
let Mail_LabelId_Trash: String = "TRASH"
let Mail_LabelId_Outbox: String = "OUTBOX"
let Mail_LabelId_SEARCH: String = "SEARCH"
let Mail_LabelId_UNREAD: String = "UNREAD"
let Mail_LabelId_SHARED: String = "SHARE"
let Mail_LabelId_FLAGGED: String = "FLAGGED"
let Mail_LabelId_Received: String = "RECEIVED"
let Mail_LabelId_READ: String = "READ"
let Mail_LabelId_Scheduled: String = "SCHEDULED"
let Mail_LabelId_Stranger: String = "STRANGER"
let Mail_FolderId_Root: String = "0"
let Mail_LabelId_SEARCH_TRASH_AND_SPAM: String = "SEARCH_TRASH_AND_SPAM"
let Mail_LabelId_HighPriority: String = "HIGH_PRIORITY"
let Mail_LabelId_LowPriority: String = "LOW_PRIORITY"
let Mail_LabelId_ReadReceiptRequest: String = "READ_RECEIPT_REQUEST"
//let Mail_LabelId_ReadReceiptSended: String = "READ_RECEIPT_SENDED" // 暂时用不到


extension MailLabelModel {
    static var restrictedLabels: [String] {
        return [Mail_LabelId_Inbox,
                Mail_LabelId_Important,
                Mail_LabelId_Other,
                Mail_LabelId_Archived,
                Mail_LabelId_Spam,
                Mail_LabelId_Sent,
                Mail_LabelId_Scheduled,
                Mail_LabelId_Draft,
                Mail_LabelId_Trash,
                Mail_LabelId_Outbox,
                Mail_LabelId_SEARCH,
                Mail_LabelId_UNREAD,
                Mail_LabelId_SHARED,
                Mail_LabelId_FLAGGED,
                Mail_LabelId_Received,
                Mail_LabelId_READ,
                Mail_LabelId_Stranger]
    }
}

let systemLabels = [Mail_LabelId_Unknow,
                           Mail_LabelId_Inbox,
                           Mail_LabelId_Archived,
                           Mail_LabelId_Spam,
                           Mail_LabelId_Sent,
                           Mail_LabelId_Scheduled,
                           Mail_LabelId_Draft,
                           Mail_LabelId_Trash,
                           Mail_LabelId_Outbox,
                           Mail_LabelId_SEARCH,
                           Mail_LabelId_SHARED,
                           Mail_LabelId_FLAGGED,
                           Mail_LabelId_UNREAD,
                           Mail_LabelId_Important,
                           Mail_LabelId_Other,
                           Mail_LabelId_Stranger,
                           Mail_LabelId_SEARCH_TRASH_AND_SPAM]

let smartInboxLabels = [Mail_LabelId_Important, Mail_LabelId_Other]

public let systemFolders = [Mail_LabelId_Inbox, Mail_LabelId_Archived,
                            Mail_LabelId_Spam, Mail_LabelId_Sent,
                            Mail_LabelId_Draft, Mail_LabelId_Trash,
                            MailLabelId.Folder.rawValue]

public let managableSystemFolders = Set<String>.init([Mail_LabelId_Inbox, Mail_LabelId_Archived,
                                                     Mail_LabelId_Spam, Mail_LabelId_Sent,
                                                     Mail_LabelId_Draft, Mail_LabelId_Trash,
                                                     MailLabelId.Folder.rawValue])

let systemRootEnableMoveTo = [Mail_LabelId_Inbox, Mail_LabelId_Spam]

extension String {
    var menuResource: (text: String?, iconImage: UIImage?) {
        var text: String?
        var icon: UIImage? = Resources.mail_filter_label_icon
        switch self {
        case Mail_LabelId_Unknow:
            text = nil
            icon = Resources.mail_filter_label_icon
        case Mail_LabelId_Inbox:
            text = BundleI18n.MailSDK.Mail_Folder_Inbox
            icon = UDIcon.inboxOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Important:
            text = BundleI18n.MailSDK.Mail_SmartInbox_Important
            icon = UDIcon.priorityOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Other:
            text = BundleI18n.MailSDK.Mail_SmartInbox_Others
            icon = UDIcon.inboxOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Archived:
            text = BundleI18n.MailSDK.Mail_Folder_Archived
            icon = UDIcon.archiveOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Spam:
            text = BundleI18n.MailSDK.Mail_Folder_Spam
            icon = UDIcon.spamOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Sent:
            text = BundleI18n.MailSDK.Mail_Folder_Sent
            icon = UDIcon.sentOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Scheduled:
            text = BundleI18n.MailSDK.Mail_Folder_Scheduled
            icon = UDIcon.sentScheduledOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Draft:
            text = BundleI18n.MailSDK.Mail_Folder_Draft
            icon = UDIcon.draftOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Trash:
            text = BundleI18n.MailSDK.Mail_Folder_Trash
            icon = UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Outbox:
            text = BundleI18n.MailSDK.Mail_Outbox_OutboxMobile
            icon = UDIcon.outboxOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_SHARED:
            text = BundleI18n.MailSDK.Mail_Folder_Shared
            icon = UDIcon.shareOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_FLAGGED:
            text = BundleI18n.MailSDK.Mail_Folder_Flagged
            icon = UDIcon.flagOutlined.withRenderingMode(.alwaysTemplate)
        case Mail_LabelId_Stranger:
            text = BundleI18n.MailSDK.Mail_Stranger_Folder_Title
            icon = UDIcon.unknowncontactOutlined.withRenderingMode(.alwaysTemplate)
        default:
            text = nil
            icon = nil
        }
        return (text, icon)
    }

    func isSystemLabel() -> Bool {
        return systemLabels.contains(self)
    }

    func isRoot() -> Bool {
        return self == Mail_FolderId_Root
    }

}

// 辅助label数据处理，label父子关系排序，label每层的string放入labelNodes数组，供展示时候处理使用
struct MailLabelArrangeManager {
    private static let logger = Logger.log(MailLabelArrangeManager.self, category: "Module.MailLabelArrangeManager")
    static func sortLabels(_ labels: [MailFilterLabelCellModel]) -> [MailFilterLabelCellModel] {
        printLabels(labels: labels, desc: "origin")
        var originLabels: [MailFilterLabelCellModel] = []
        originLabels.append(contentsOf: labels)
        var res: [MailFilterLabelCellModel] = []

        // 找到根节点Label
        var rootLabels = originLabels.filter { (model) -> Bool in
            return model.parentID.isEmpty || model.parentID.isRoot()
        }
        // 给根节点label的textNames和idNames赋值
        for (i, var label) in rootLabels.enumerated() {
            // label.textNames.append(label.text)
            label.idNames.append(label.labelId)
            rootLabels[i] = label
        }

        res.append(contentsOf: rootLabels)
        deleteLabel(originLabels: &originLabels, needDeleteLabels: rootLabels)
        while originLabels.count > 0 {
            let cnt = originLabels.count
            var delete: [MailFilterLabelCellModel] = []
            for var label in originLabels {
                let flag = insertLabel(targetLabel: &res, label: &label)
                if flag {
                    delete.append(label)
                }
            }
            deleteLabel(originLabels: &originLabels, needDeleteLabels: delete)
            if originLabels.count == cnt {
                // to do 打印没有插入的label
                break
            }
        }
        printLabels(labels: res, desc: "sorted")
        return res
    }

    static func printLabels(labels: [MailFilterLabelCellModel], desc: String) {
        var debugStr = ""
        for label in labels {
            debugStr += label.debugStr
        }
        MailLabelArrangeManager.logger.debug("\(desc):{\(debugStr)}")
    }

    static func deleteLabel(originLabels: inout [MailFilterLabelCellModel], needDeleteLabels: [MailFilterLabelCellModel]) {
        originLabels = originLabels.filter { (origin) -> Bool in
            !needDeleteLabels.contains { (delete) -> Bool in
                delete.labelId == origin.labelId
            }
        }
    }

    static func insertLabel(targetLabel: inout [MailFilterLabelCellModel], label: inout MailFilterLabelCellModel) -> Bool {
        var flag = false
        var index = -1
        // var textNames: [String] = []
        var idNames: [String] = []
        for (i, main) in targetLabel.enumerated() {
            // 先找到父亲label
            if flag == false && main.labelId == label.parentID {
                flag = true
                index = i
                // textNames.append(contentsOf: main.textNames)
                idNames.append(contentsOf: main.idNames)
            }
            // 找到兄弟，插入到兄弟的最后面
            if flag == true && main.idNames.contains(label.parentID) {
                index = i
            }
        }
        if flag {
           // textNames.append(label.text)
            idNames.append(label.labelId)
            // label.textNames.append(contentsOf: textNames)
            label.idNames.append(contentsOf: idNames)
            targetLabel.insert(label, at: index + 1)
        }
        return flag
    }
}

extension MailLabelArrangeManager {
    static let lastMinWidth: CGFloat = 60
    static func composeText(textNames: [String], maxWidth: CGFloat, font: UIFont) -> String {
        if textNames.count == 0 {
            return ""
        }
        if textNames.count == 1 {
            return textNames[0]
        }
        // 完全拼起来
        var res = ""
        for text in textNames {
            if res.isEmpty {
                res = res + text
            } else {
                res = res + "/" + text
            }
        }
        // 完全拼接后能展示,则直接返回
        if !cutStr(str: res, width: maxWidth, font: font).1 {
            return res
        }
        var ellipsis = "/"
        if textNames.count > 2 {
            ellipsis = "/.../"
        }
        // 第一级宽度
        var hWidth = strWidth(str: textNames[0], font: font)
        // 省略区域宽度
        let ellipsisWidth = strWidth(str: ellipsis, font: font)
        // 最后一级宽度
        var tWidth = strWidth(str: textNames[textNames.count - 1], font: font)
        // 如果第一级加省略号宽度使得最后一级的宽度不够了
        if hWidth + ellipsisWidth > maxWidth - lastMinWidth {
            let lastStr = cutStr(str: textNames[textNames.count - 1], width: lastMinWidth, font: font).0
            hWidth = maxWidth - strWidth(str: lastStr, font: font) - ellipsisWidth
            let firstStr = cutStr(str: textNames[0], width: hWidth, font: font).0
            return firstStr + ellipsis + lastStr
        } else if hWidth + tWidth + ellipsisWidth > maxWidth {
            // 第一级和最后一级加起来无法完全展示，优先展示第一级内容
            tWidth = maxWidth - hWidth - ellipsisWidth
            let lastStr = cutStr(str: textNames[textNames.count - 1], width: tWidth, font: font).0
            return textNames[0] + ellipsis + lastStr
        } else {
            // 第一级和最后一级能展示，则按从后往前顺序依次添加更多的级数
            var res = ""
            let leftpart = textNames[0]
            var lastpart = textNames[textNames.count - 1]
            if textNames.count == 2 {
                return leftpart + "/" + lastpart
            }
            var index = textNames.count - 2
            var space = maxWidth - strWidth(str: leftpart, font: font) - strWidth(str: lastpart, font: font)
            while index > 0 {
                var ellipsis = "/"
                if index != 1 {
                    ellipsis = "/.../"
                }
                let obj = cutStr(str: textNames[index], width: space - strWidth(str: ellipsis, font: font), font: font)
                let flag = obj.1
                let str = obj.0
                if !flag {
                    lastpart = str + "/" + lastpart
                    space = maxWidth - strWidth(str: leftpart, font: font) - strWidth(str: lastpart, font: font)
                    if index == 1 {
                        res = leftpart + "/" + lastpart
                        break
                    }
                } else {
                    if str == "..." {
                        res = leftpart + ellipsis + lastpart
                    } else {
                        res = leftpart + ellipsis + str + "/" + lastpart
                    }

                    break
                }
                index = index - 1
            }
            return res
        }
    }

    static func cutStr(str: String, width: CGFloat, font: UIFont) -> (String, Bool) {
        if strWidth(str: str, font: font) <= width {
            return (str, false)
        } else {
            let ellipsis = "..."
            var res = ""
            for value in str {
                let test = res + String(value) + ellipsis
                if strWidth(str: test, font: font) < width {
                    res = res + String(value)
                } else {
                    break
                }
            }
            return (res + ellipsis, true)
        }
    }

    static func strWidth(str: String, font: UIFont, height: CGFloat = CGFloat(15)) -> CGFloat {
        let rect = str.boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: height),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }
}

struct MailFilterLabelCellModel: MailLabelModel, Hashable {
    var fontColor: UIColor?
    var bgColor: UIColor?
    var fontColorHex: String?
    var bgColorHex: String?
    var labelId: String = Mail_LabelId_Unknow
    var icon: UIImage?
    var text: String
    var selected: Bool = false
    var badge: Int?
    var isSystem: Bool = false
    var mailClientType: MailLabelModelMailClientType = .larkMail
    var canShow = true
    var parentID: String = ""
    var textNames: [String] = []
    var idNames: [String] = []
    var badgeStyle: MailLabelBadgeStyle = .number
    var userOrderedIndex: Int64 = 0
    var tagType: MailTagType = .label
    var colorType: MailLabelTransformer.LabelColorType = .blue

    init(labelId: String, badge: Int) {
        let resource = labelId.menuResource
        self.init(labelId: labelId, icon: resource.iconImage, text: resource.0 ?? "", badge: badge, fontColor: nil)
    }

    init(labelId: String,
         icon: UIImage?,
         text: String,
         badge: Int,
         fontColor: UIColor?) {
        self.icon = icon
        self.text = text
        self.labelId = labelId
        self.badge = badge
        self.fontColor = fontColor
    }

    init(color: UIColor, text: String) {
        self.fontColor = color
        self.text = text
        self.labelId = Mail_LabelId_Unknow
    }

    init(pbModel: Email_Client_V1_Label) {
        if pbModel.id == Mail_LabelId_Stranger && !FeatureManager.open(.stranger, openInMailClient: false) {
            text = pbModel.name
        } else {
            text = pbModel.id.menuResource.text ?? pbModel.name
        }
        fontColorHex = pbModel.fontColor
        bgColorHex = pbModel.bgColor
        // 过滤一轮
        let config = MailLabelTransformer.transformLabelColor(backgroundColor: pbModel.bgColor)
        fontColor = config.fontColor
        bgColor = config.backgroundColor
        badge = Int(pbModel.unreadCount)
        labelId = pbModel.id
        icon = labelId.menuResource.iconImage
        isSystem = pbModel.isSystem
        mailClientType = pbModel.labelModelMailClientType
        colorType = config.colorType
        if pbModel.tagType == .folder, pbModel.parentID.isEmpty {
            parentID = Mail_FolderId_Root
        } else {
            parentID = pbModel.parentID
        }
        textNames = pbModel.nodePath
        if pbModel.id == Mail_LabelId_Important {
            userOrderedIndex = -3 // disable-lint: magic_number -- 排序定义，负数表示排在前面，且不可自定义编辑
        } else if pbModel.id == Mail_LabelId_Other {
            userOrderedIndex = -2 // disable-lint: magic_number -- 排序定义，负数表示排在前面，且不可自定义编辑
        } else {
            userOrderedIndex = pbModel.userOrderedIndex
        }
        tagType = pbModel.tagType
    }

    func toPBModel() -> MailClientLabel {
        var clientLabel = MailClientLabel()
        clientLabel.id = labelId
        clientLabel.name = text
        clientLabel.fontColor = fontColorHex ?? ""
        clientLabel.bgColor = bgColorHex ?? ""
        clientLabel.unreadCount = Int64(badge ?? 0)
        clientLabel.isSystem = isSystem
        clientLabel.emailClientType = emailClientType
        clientLabel.nodePath = textNames
        clientLabel.userOrderedIndex = userOrderedIndex
        clientLabel.modelType = modelType
        return clientLabel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.labelId)
        hasher.combine(self.text)
    }

    static func == (lLabel: MailFilterLabelCellModel, rLabel: MailFilterLabelCellModel) -> Bool {
        return lLabel.labelId == rLabel.labelId
    }

    var debugStr: String {
        if self.parentID.isEmpty {
            return "[labelID=\(self.labelId)]"
        } else {
            return "[labelID=\(self.labelId),parentID=\(self.parentID)]"
        }
    }
}

// 这里是为了纠正 label 颜色及 i18n 文案
extension MailClientLabel {
    var displayName: String {
        if self.id != Mail_LabelId_SHARED,
            let text = self.id.menuResource.text {
            return text
        }
        if self.id == Mail_LabelId_SHARED {
            return BundleI18n.MailSDK.Mail_Share_LabelName
        }
        if (self.tagType == .folder && self.parentID != Mail_FolderId_Root) ||
            (self.tagType == .label && !self.parentID.isEmpty) {
            return "/" + self.name
        }
        return self.name
    }
    var displayLongName: String {
        if self.id != Mail_LabelId_SHARED,
            let text = self.id.menuResource.text {
            return text
        }
        if self.id == Mail_LabelId_SHARED {
            return BundleI18n.MailSDK.Mail_Share_LabelName
        }
        if (self.tagType == .folder && self.parentID != Mail_FolderId_Root) ||
            (self.tagType == .label && !self.parentID.isEmpty) {
            return self.nodePath.joined(separator: "/")
        }
        return self.name
    }

    var displayFontColor: String {
        if self.id != Mail_LabelId_SHARED,
            self.isSystem,
            let fontColor = UIColor.ud.udtokenTagNeutralTextNormal.alwaysLight.hex6 {
            return fontColor
        }
        return self.fontColor
    }

    var displayBgColor: String {
        if self.id != Mail_LabelId_SHARED,
            self.isSystem,
            let bgColor = UIColor.ud.udtokenTagNeutralBgNormal.alwaysLight.hex6 {
            return bgColor
        }
        return self.bgColor
    }

    func getStrangerListSubtitleText() -> String {
        if self.unreadCount > StrangerCardConst.maxThreadCount {
            return BundleI18n.MailSDK.Mail_StrangerMail_NumberOfSendersOverNightyNine_Text
        } else {
            return BundleI18n.MailSDK.Mail_StrangerMail_NumberOfSenders_Text(unreadCount)
        }
    }

    func getStrangerListHeaderText() -> String {
        if self.unreadCount > StrangerCardConst.maxThreadCount {
            return BundleI18n.MailSDK.Mail_StrangerMail_StrangerOverNightyNine_Text
        } else {
            return BundleI18n.MailSDK.Mail_StrangerMail_StrangersWithNum_Text(unreadCount)
        }
    }

    func getMoreStrangersCount() -> Int {
        return min(Int(unreadCount) - StrangerCardConst.maxCardCount, StrangerCardConst.maxThreadCount)
    }
}
