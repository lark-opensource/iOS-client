//
//  MailThreadListCellViewModel.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/5/18.
//

import Foundation
import RxSwift
import RustPB

enum MailThreadStatus {
    case normal
    case sending
    case failed
    case hasdraft
}

struct ThreadNameItem {
    var name: String
    var address: String
    var uid: String
}

class MailThreadListCellViewModel: CustomStringConvertible {

    let userID: String
    var threadID: String
    var currentLabelID: String = ""
    var name: String
    var address: String
    var title: String
    var desc: String
    var convCount: Int64
    var time: Int64
    var lastmessageTime: Int64
    var fromList: [String]
    var fromAddressList: [MailAddress]
    var isUnread: Bool
    var replyTagType: MailReplyType
    var priorityType: MailPriorityType
    var mailStatus: MailThreadStatus
    var draft: String?
    var isComposeDraft: Bool
    var threadActions: [MailThreadAction]
    var description: String
    var labelIDs: [String]?
    var isShared: Bool = false
    let isExternal: Bool
    var isFlagged: Bool = false
    var permissionCode: MailPermissionCode = .none
    var senderAddresses: [String]
    var scheduleSendMessageCount: Int64
    var scheduleSendTimestamp: Int64
    var hasAttachment: Bool = false
    var hasReadStat: Bool = false
    var deliveryState: MailClientMessageDeliveryState
    var isFromAuthorized: Bool = false
    /// 用来渲染读信页titleView的label数据
    var readMailDisplayUnsortedLabels: [MailClientLabel] {
        let currentLabelID = self.currentLabelID
        /// 参与者不显示任何 label
        if permissionCode == .view {
            return []
        }
        return MailTagDataManager.shared.getTagModels(labelIDs ?? []).filter({ $0.tagType == .label })
    }

    /// 封面信息
    var subjectCover: MailSubjectCover?

    // 收件箱/发件箱 发件人/收件人展示文本生成
    var isAddressee: Bool
    var sendDisplayName: String? // 发件箱
    var addresseeDisplayName: String? // 收件箱
    var addresseeName: [ThreadNameItem]
    var addresseeWidth: [CGFloat] = []
    var contentViewWidth: CGFloat = 0
    var timeWidth: CGFloat = 0
    let maxHeight = CGFloat(MAXFLOAT)
    let nameFont = UIFont.systemFont(ofSize: 17) // MailThreadListCell.nameFontSize
    let timeLabelFont = UIFont.systemFont(ofSize: 16) // MailThreadListCell.timeLabelFont
    let nameLabelLeftMargin = 16 // MailThreadListCell.nameLabelLeftMargin
    let images: [MailClientDraftImage]
    lazy var commaWidth = ", ".getTextWidth(font: nameFont, height: maxHeight)
    lazy var pointsWidth = "...".getTextWidth(font: nameFont, height: maxHeight)

    var enableReaction: Bool = true // 默认开

    let disposeBag = DisposeBag()
    var displayAddress: [MailClientAddress] = []
    var bccAddress: [MailClientAddress] = []
    var labelId: String = ""
    var originData: MailThreadItem? = nil
    // 按照过滤规则处理后，需要显示的标签
    var displayLabels: [MailClientLabel]? {
        let currentLabelID = self.currentLabelID
        /// 参与者不显示任何 label
        if permissionCode == .view {
            return nil
        }
        if let labelIDs = labelIDs {
            let allLabels = MailTagDataManager.shared.getTagModels(labelIDs).filter({ $0.tagType == .label })
            return MailThreadListLabelFilter.filterLabels(allLabels,
                                                          atLabelId: currentLabelID,
                                                          permission: permissionCode)
        }
        return nil
    }

    init(with threadItem: MailThreadItem, labelId: String, userID: String) {
        let thread = threadItem.thread
        self.images = thread.images
        // 假设这个LabelID就是Mail_LabelId_Draft之类的东西，可以用它来判断是不是收件
        if thread.messageCount == 0 && labelId != Mail_LabelId_Draft {
            MailLogger.error("fetchMailInboxFeeds 含有非法的 message, id =\(thread.id)")
        }
        self.userID = userID
        self.labelId = labelId
        var name = ""
        var flag = true
        for address in thread.displayAddress {
            if flag {
                flag = false
            } else {
                name = "," + name
            }
            var addressname = MailThreadListCellViewModel.cellModelDisplayName(address: address, labelId: labelId)
            if addressname.isEmpty {
                addressname = String(address.address.split(separator: "@").first ?? "")
            }
            if addressname.isEmpty {
                addressname = address.address
            }
            name = name + addressname
        }
        self.name = name
        self.threadID = thread.id
        self.description = "threadID: \(thread.id)"
        self.address = thread.displayAddress.first?.address ?? ""
        self.title = thread.messageSubject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : thread.messageSubject
        self.desc = thread.messageSummary
        self.convCount = thread.messageCount
        self.time = thread.lastUpdatedTimestamp
        self.lastmessageTime = thread.lastMessageTimestamp
        self.fromList = thread.displayAddress.map({ $0.address })
        self.fromAddressList = thread.displayAddress.map({ MailAddress.init(with: $0) })
        self.isUnread = !thread.isRead
        self.replyTagType = thread.displayReplyType
        self.priorityType = thread.priorityType
        self.mailStatus = MailThreadStatus.normal
        self.isComposeDraft = thread.isComposeDraft
        self.draft = thread.draftSummary.isEmpty ? nil : thread.draftSummary
        self.hasAttachment = thread.hasAttachment_p
        self.threadActions = threadItem.actions.compactMap { MailThreadAction(rawValue: $0.rawValue) }
        self.labelIDs = thread.labelIds
        self.isAddressee = MailThreadListCellViewModel.isAddressee(labelId)
		self.isFromAuthorized = threadItem.isFromAuthorized
        self.deliveryState = threadItem.deliveryState
        if labelId == Mail_LabelId_Sent {
            self.hasReadStat = thread.hasReadStatistics_p != .none
        } else {
            self.hasReadStat = (thread.hasReadStatistics_p == .hasBoth ||
                           thread.hasReadStatistics_p == .hasReceivedOnly)
        }
        if self.isAddressee {
            self.addresseeName = MailThreadListCellViewModel.genNamesForAddressee(thread.displayAddress, labelId: labelId)
            self.sendDisplayName = ""
        } else {
            self.addresseeName = []
            self.displayAddress = thread.displayAddress
            self.bccAddress = thread.bccAddress
            self.sendDisplayName = MailThreadListCellViewModel.genNameForSend(thread.displayAddress,
                                                                              thread.bccAddress,
                                                                              inDraftLabel: labelId == Mail_LabelId_Draft,
                                                                              labelId: labelId)
        }
        self.permissionCode = threadItem.code
        /// 通过 permissionCode 判断是否是分享邮件
        self.isShared = threadItem.code != .none
        self.isFlagged = thread.isFlagged
        self.isExternal = threadItem.isExternal
        self.senderAddresses = thread.displayAddress.map { (address) -> String in
            address.address
        }
        self.scheduleSendTimestamp = thread.scheduleSendTimestamp
        self.scheduleSendMessageCount = thread.scheduleSendMessageCount
        self.subjectCover = thread.coverInfo.isEmpty ? nil : MailSubjectCover.decode(from: thread.coverInfo)

        if self.addresseeName.count > 1 {
            let addressStrs = self.addresseeName.map({$0.name})
            self.addresseeWidth = addressStrs.map(end: 4, trans: { $0.getTextWidth(font: nameFont, height: maxHeight)
            })
        }
        self.originData = threadItem
    }
}

extension MailThreadListCellViewModel: Equatable {
	  // disable-lint: cyclomatic_complexity
    static func == (lhs: MailThreadListCellViewModel, rhs: MailThreadListCellViewModel) -> Bool {
        return lhs.threadID == rhs.threadID && lhs.name == rhs.name &&
        lhs.address == rhs.address && lhs.title == rhs.title && lhs.desc == rhs.desc &&
        lhs.convCount == rhs.convCount && lhs.lastmessageTime == rhs.lastmessageTime &&
        MailThreadListCellViewModel.areArraysEqual(lhs.labelIDs ?? [], rhs.labelIDs ?? []) &&
        lhs.isUnread == rhs.isUnread &&
        MailThreadListCellViewModel.areArraysEqual(lhs.fromList, rhs.fromList) &&
        lhs.scheduleSendTimestamp == rhs.scheduleSendTimestamp &&
        lhs.isFlagged == rhs.isFlagged &&
        lhs.hasAttachment == rhs.hasAttachment &&
        lhs.sendDisplayName == rhs.sendDisplayName &&
        lhs.addresseeDisplayName == rhs.addresseeDisplayName &&
        lhs.displayAddress == rhs.displayAddress &&
        lhs.replyTagType == rhs.replyTagType &&
        lhs.priorityType == rhs.priorityType
    }
		// enable-lint: cyclomatic_complexity

    static func areArraysEqual(_ array1: [String], _ array2: [String]) -> Bool {
        let set1 = Set(array1)
        let set2 = Set(array2)
        return set1 == set2
    }
}

struct MailAttachMent {
    var typeStr: String
    var name: String
    var url: String
}

extension MailClientAddress {
    var isGroupOrEnterpriseMailGroup: Bool {
        return larkEntityType.isGroupOrEnterpriseMailGroup
    }

    /// group邮件组，不展示"我"
    var mailDisplayName: String {
        return innerMailDisplayName(ignoreMe: isGroupOrEnterpriseMailGroup)
    }

    var mailDisplayNameNoMe: String {
        return innerMailDisplayName(ignoreMe: true)
    }
    // 返回是否自己
    var isMe: Bool {
        return isMeDetermine()
    }
    
    var mailDisplayNameNoMeNoNameUpdate: String {
        return innerMailDisplayName(ignoreMe: true,
                                    fromTo: false,
                                    nameUpdate: false)
    }
    
    var mailToDisplayName: String {
        return innerMailDisplayName(ignoreMe: false, fromTo: true)
    }

    var domain: String {
        if let d = address.split(separator: "@").last {
            return String(d)
        } else {
            return ""
        }
    }
    
    private func isMeDetermine() -> Bool {
        var isMe = false
        if (Store.settingData.getCachedCurrentAccount()?.mailSetting.emailAlias.allAddresses ?? []).filter({ $0.larkEntityType != .enterpriseMailGroup}).map({ $0.address.lowercased() }).contains(address.lowercased()) {
            isMe = true
            return isMe
        } else if let account = Store.settingData.getCachedCurrentAccount(), !account.isShared,
                  Store.settingData.currentUserContext?.user.userID  == self.larkEntityIDString &&
                    !self.larkEntityIDString.isEmpty &&
                    self.larkEntityIDString != "0" {
            isMe = true
            return isMe
        }
        return isMe
    }

    private func innerMailDisplayName(ignoreMe: Bool = false,
                                      fromTo: Bool = false,
                                      nameUpdate: Bool = true) -> String {
        // 三方走老逻辑
        if Store.settingData.mailClient {
            if(Store.settingData.getCachedCurrentAccount()?.mailSetting.emailAlias.allAddresses ?? []).map({ $0.address.lowercased() }).contains(address.lowercased()) {
                if !ignoreMe {
                    return BundleI18n.MailSDK.Mail_ThreadList_Me
                }
            }
            return displayName.isEmpty ? name : displayName
        }
        var isMe = false
        if (Store.settingData.getCachedCurrentAccount()?.mailSetting.emailAlias.allAddresses ?? []).filter({ $0.larkEntityType != .enterpriseMailGroup}).map({ $0.address.lowercased() }).contains(address.lowercased()) {
            isMe = true
        } else if let account = Store.settingData.getCachedCurrentAccount(), !account.isShared,
                  Store.settingData.currentUserContext?.user.userID  == self.larkEntityIDString &&
                    !self.larkEntityIDString.isEmpty &&
                    self.larkEntityIDString != "0" {
            isMe = true
        }
        if fromTo && isMe && !FeatureManager.open(.ignoreMe) {
            return BundleI18n.MailSDK.Mail_ThreadList_Me
        }
        if isMe && !fromTo {
            if !ignoreMe && !FeatureManager.open(.ignoreMe) {
                return BundleI18n.MailSDK.Mail_ThreadList_Me
            } else if let setting = Store.settingData.getCachedCurrentSetting(),
                Store.settingData.mailClient {
                 return setting.emailAlias.defaultAddress.name
             }
            return name.isEmpty ? displayName : name
        } else {
            if nameUpdate {
                if let newName = MailAddressChangeManager.shared.uidNameMap[self.larkEntityIDString], !newName.isEmpty {
                    return newName
                } else if let newName = MailAddressChangeManager.shared.addressNameMap[self.address], !newName.isEmpty {
                    return newName
                }
            }
            return displayName.isEmpty ? name : displayName
        }
    }
}

// MARK: 收件箱/发件箱 发件人/收件人展示文本生成 文档 https://bytedance.feishu.cn/docs/doccnkXx9PC7d7JXdZUOd4DAjMc
extension MailThreadListCellViewModel {

    static func isAddressee(_ labelId: String) -> Bool {
        var isAddressee = false
        switch labelId {
        case // 发件箱
             Mail_LabelId_Sent, Mail_LabelId_SEARCH, Mail_LabelId_Draft,
             Mail_LabelId_Scheduled, Mail_LabelId_Outbox,
             // 不处理
             Mail_LabelId_Unknow, Mail_LabelId_UNREAD, Mail_LabelId_SHARED,
             Mail_LabelId_READ, Mail_FolderId_Root, Mail_LabelId_Received:
            ()
        default: // 1. 自定义标签/文件夹 2. 收件箱场景
            isAddressee = true
        }
        return isAddressee
    }
    
    func updateNameAndWidth() {
        self.addresseeName = self.addresseeName.map { item in
            if item.address.addresIsMe() ||
                (!item.uid.isEmpty &&
                 item.uid != "0" &&
                 item.uid == userID) {
                return item
            }
            // 三方不替换
            if Store.settingData.mailClient {
                return item
            }
            if let newName = MailAddressChangeManager.shared.uidNameMap[item.uid], !newName.isEmpty {
                return ThreadNameItem(name: newName, address: item.address, uid: item.uid)
            } else if let newName = MailAddressChangeManager.shared.addressNameMap[item.address], !newName.isEmpty,
                      newName != item.name {
                return ThreadNameItem(name: newName, address: item.address, uid: item.uid)
            } else {
                return item
            }
        }
        let addressStrs = self.addresseeName.map({$0.name})
        self.addresseeWidth = addressStrs.map(end: 4, trans: { $0.getTextWidth(font: nameFont, height: maxHeight)
        })
    }

    func getDisplayName(_ time: String, _ contentViewWidth: CGFloat, inDraftLabel: Bool = false, nameFont: UIFont) -> String? {
        updateNameAndWidth()
        if !isAddressee {
            if sendDisplayName != nil {
                self.sendDisplayName = MailThreadListCellViewModel.genNameForSend(self.displayAddress,
                                                                                  self.bccAddress,
                                                                                  inDraftLabel: self.labelId == Mail_LabelId_Draft,
                                                                                  labelId: labelId)
                return sendDisplayName
            } else { return inDraftLabel ? BundleI18n.MailSDK.Mail_ThreadList_NoRecipients : BundleI18n.MailSDK.Mail_ThreadAction_RecipientUnFilled }
        } else if contentViewWidth == self.contentViewWidth, let addresseeDisplayName = self.addresseeDisplayName {
            return addresseeDisplayName
        }
        let count = addresseeName.count
        if count == 0 {
            return inDraftLabel ? BundleI18n.MailSDK.Mail_ThreadList_NoRecipients : BundleI18n.MailSDK.Mail_ThreadAction_RecipientUnFilled
        } else if count == 1 { return addresseeName[0].name }
        if self.timeWidth == 0 {
            self.timeWidth = time.getTextWidth(font: timeLabelFont, height: maxHeight)
        }
        let leftPadding: CGFloat = 28 //contentView与父view左边界距离
        let rightPadding: CGFloat = 16 //contentView与父view右边界距离
        let maxWidth = contentViewWidth - leftPadding - rightPadding - timeWidth // 附件 和 定时发送
        var nameWidth: CGFloat = addresseeWidth[0]

        if count == 2 {
            nameWidth += commaWidth
            if nameWidth >= maxWidth {
                return addresseeName[0].name
            } else { return addresseeName[0].name + ", " + addresseeName[1].name }
        }
        if nameWidth + pointsWidth >= maxWidth {
            return addresseeName[0].name
        }
        var sepWidth = (count == 3) ? 2 * commaWidth : pointsWidth
        nameWidth += (addresseeWidth[2] + addresseeWidth[1] + sepWidth)
        if nameWidth >= maxWidth {
            return addresseeName[0].name + "..." + addresseeName[2].name
        } else {
            let addresseeDisplayName = (count == 3) ? addresseeName[0].name + ", " + addresseeName[1].name + ", " + addresseeName[2].name
                                        : getAdjustLongNames(maxWidth: maxWidth, nameFont: nameFont)
            self.addresseeDisplayName = addresseeDisplayName
            return addresseeDisplayName
        }
    }

    private func getAdjustLongNames(maxWidth: CGFloat, nameFont: UIFont) -> String {
        // 扩展这个，大于3个时自适应展示
        let lastIndex = addresseeName.count - 1
        var currentDisplayNamesPrefix = addresseeName[0].name + ", " + addresseeName[1].name
        var currentDisplayNamesSuffix = addresseeName[lastIndex].name // "..." +
        var currentDisplayNames = currentDisplayNamesPrefix + currentDisplayNamesSuffix
        var currentDisplayWidth = currentDisplayNames.getTextWidth(font: nameFont, height: maxHeight)
        var startIndex = 2
        while startIndex < lastIndex {
            let additionalWidth = addresseeName[startIndex].name.getTextWidth(font: nameFont, height: maxHeight) + commaWidth
            let sepWidth = (startIndex == lastIndex - 1) ? pointsWidth : commaWidth
            let sepStr = (startIndex == lastIndex - 1) ? "..." : ", "
            if additionalWidth + currentDisplayWidth + sepWidth < maxWidth {
                currentDisplayNamesPrefix = currentDisplayNamesPrefix + ", " + addresseeName[startIndex].name
                currentDisplayNames = currentDisplayNamesPrefix + ", " + currentDisplayNamesSuffix
                currentDisplayWidth = currentDisplayNames.getTextWidth(font: nameFont, height: maxHeight)
            } else {
                currentDisplayNames = currentDisplayNamesPrefix + "..." + currentDisplayNamesSuffix
                currentDisplayWidth = currentDisplayNames.getTextWidth(font: nameFont, height: maxHeight)
            }
            startIndex += 1
        }
        return currentDisplayNames
    }
    
    static func cellModelDisplayName(address: MailClientAddress?, labelId: String) -> String {
        if let address = address {
            if labelId == Mail_LabelId_Sent ||
                labelId == Mail_LabelId_Draft ||
                labelId == Mail_LabelId_Outbox {
                return address.mailToDisplayName
            } else {
                return address.mailDisplayName
            }
        } else {
            return ""
        }
    }

    static func genNamesForAddressee(_ addresses: [MailClientAddress],
                                     labelId: String) -> [ThreadNameItem] {
        if addresses.count == 0 { return [] }
        var temp: [MailClientAddress] = addresses
        while temp.first?.mailDisplayName == temp.last?.mailDisplayName,
              temp.first?.address.lowercased() == temp.last?.address.lowercased(), temp.count > 1 {
            temp.removeFirst()
        }
        if temp.count == 1 {
            return [temp.last!].map({
                ThreadNameItem(name: MailThreadListCellViewModel.cellModelDisplayName(address: $0, labelId: labelId),
                               address: $0.address,
                               uid: String($0.larkEntityID))
            })
        } else if temp.count == 2 {
            return [temp.last!, temp.first!].map({
                ThreadNameItem(name: MailThreadListCellViewModel.cellModelDisplayName(address: $0, labelId: labelId),
                               address: $0.address,
                               uid: String($0.larkEntityID))
            })
        } else {
            let first = temp.removeFirst()
            let last = temp.removeLast()
            var displayAddresses = [last, first]
            var sortNames = [last]
            // 如果找到了name2，就找name3
            if let index1 = temp.lastIndex(where: { isNotIn(displayAddresses, $0) }) { // 找name2
                displayAddresses.append(temp[index1])
                sortNames.append(temp[index1])
                // 如果能找到name3，看看还有没有第4个不重复的，虽然第4个的值不重要
                if let index3 = temp.lastIndex(where: { isNotIn(displayAddresses, $0) }) {
                    displayAddresses.append(temp[index3])
                    sortNames.append(temp[index3])

                    if let index4 = temp.lastIndex(where: { isNotIn(displayAddresses, $0) }) {
                        displayAddresses.append(temp[index4])
                        sortNames.append(temp[index4])

                        if let index5 = temp.lastIndex(where: { isNotIn(displayAddresses, $0) }) {
                            displayAddresses.append(temp[index5])
                            sortNames.append(temp[index5])
                        }
                    }// 直接增加两个联系人数据，避免过长的thread造成大数组影响性能，增加联系人只为ux

                }
            }
            sortNames.append(first)
            return sortNames.map({
                ThreadNameItem(name: MailThreadListCellViewModel.cellModelDisplayName(address: $0, labelId: labelId),
                               address: $0.address,
                               uid: String($0.larkEntityID))
            })
        }
    }

    static func isNotIn(_ mailClientAddresses: [MailClientAddress], _ item: MailClientAddress) -> Bool {
        // 邮箱地址忽略大小写
        return !mailClientAddresses.contains(where: { $0.mailDisplayName == item.mailDisplayName && $0.address.caseInsensitiveCompare(item.address) == .orderedSame })
    }

    static func genNameForSend(_ addresses: [MailClientAddress],
                               _ bcc: [MailClientAddress] = [],
                               inDraftLabel: Bool = false,
                               labelId: String) -> String {
        if addresses.isEmpty && bcc.isEmpty {
            return inDraftLabel ? BundleI18n.MailSDK.Mail_ThreadList_NoRecipients : BundleI18n.MailSDK.Mail_ThreadAction_RecipientUnFilled
        }
        let noBcc = bcc.isEmpty
        let justBcc = !bcc.isEmpty && addresses.isEmpty

        var _names = addresses
        var _bcc = bcc

        let bccStr = "\(BundleI18n.MailSDK.Mail_ThreadList_BCC): "
        var result = ""
        var nameTuple: (MailClientAddress?, MailClientAddress?, MailClientAddress?) = (nil, nil, nil)
        if justBcc {
            nameTuple = removeLastDuplicate(&_bcc)
        } else {
            nameTuple = removeLastDuplicate(&_names)
        }
        let first = nameTuple.0
        let second = nameTuple.1
        let last = nameTuple.2
        let firstName = MailThreadListCellViewModel.cellModelDisplayName(address: first,
                                                                         labelId: labelId)
        let secondName = MailThreadListCellViewModel.cellModelDisplayName(address: second,
                                                                          labelId: labelId)
        let lastName = MailThreadListCellViewModel.cellModelDisplayName(address: last,
                                                                        labelId: labelId)

        var nameSet = Set(_names)
        if justBcc { nameSet = Set(_bcc) }
        if let first = first {
            nameSet.remove(first)
        }
        if let last = last {
            nameSet.remove(last)
        }

        if noBcc || justBcc {
            if nameSet.isEmpty {
                if firstName != lastName || first?.address != last?.address {
                    result = "\(firstName), \(lastName)"
                } else {
                    result = firstName
                }
            } else {
                let sep = nameSet.count > 1 ? ".." : ", "
                if secondName.isEmpty {
                    result = "\(firstName), \(lastName)"
                } else {
                    result = "\(firstName), \(secondName)\(sep)\(lastName)"
                }
            }
            return justBcc ? "\(bccStr)\(result)" : result
        }

        if !firstName.isEmpty && !secondName.isEmpty && !lastName.isEmpty {
            // 满3个
            let sep = Set(_names).count > 3 ? ".." : ", "
            result = "\(firstName), \(secondName)\(sep)\(lastName)"
            return result
        } else {
            // 不满3个
            var toCCNames = [MailClientAddress]()
            if let first = first {
                toCCNames.append(first)
                if let second = second {
                    toCCNames.append(second)
                }
                if let last = last {
                    toCCNames.append(last)
                }
            }
            let bccNameArr = removeDuplicateAndThreeNames(bcc, toCCNames: Set(toCCNames)).filter({ !MailThreadListCellViewModel.cellModelDisplayName(address: $0, labelId: labelId).isEmpty })
            let bccCount = bccNameArr.count
            if Set(toCCNames).count == 1 {
                if bccCount >= 2 {
                    let sep = bccCount == 2 ? ", ": ".."
                    result = "\(MailThreadListCellViewModel.cellModelDisplayName(address: toCCNames.first, labelId: labelId)), \(bccStr)\((MailThreadListCellViewModel.cellModelDisplayName(address: bccNameArr.first, labelId: labelId)))\(sep)\((MailThreadListCellViewModel.cellModelDisplayName(address: bccNameArr.last, labelId: labelId)))"
                } else if bccCount == 1 {
                    result = "\(MailThreadListCellViewModel.cellModelDisplayName(address: toCCNames.first, labelId: labelId)), \(bccStr)\((MailThreadListCellViewModel.cellModelDisplayName(address: bccNameArr.last, labelId: labelId)))"
                } else {
                    result = "\(MailThreadListCellViewModel.cellModelDisplayName(address: toCCNames.first, labelId: labelId))"
                }
            } else {
                if bccNameArr.count > 0 {
                    let sep = bccCount > 1 ? ".." : ", "
                    result = "\(firstName), \(secondName.isEmpty ? lastName : secondName)\(sep)\(bccStr)\((MailThreadListCellViewModel.cellModelDisplayName(address: bccNameArr.last, labelId: labelId)))"
                } else {
                    result = "\(firstName), \(secondName.isEmpty ? lastName: secondName)"
                }
            }
        }
        return result
    }

    static func removeDuplicateAndThreeNames(_ names: [MailClientAddress], toCCNames: Set<MailClientAddress>) -> [MailClientAddress] {
        var _names = names
        let nameTuple = removeLastDuplicate(&_names)
        let first = nameTuple.0
        let secondName = nameTuple.1
        let last = nameTuple.2
        var result = [MailClientAddress]()
        if let first = first, !toCCNames.contains(first) {
            result.append(first)
        }
        if let secondName = secondName, !toCCNames.contains(secondName) {
            result.append(secondName)
        }
        if let last = last, !toCCNames.contains(last), _names.count > 1 {
            result.append(last)
        }
        return result
    }

    static func removeLastDuplicate(_ names: inout [MailClientAddress]) -> (MailClientAddress?, MailClientAddress?, MailClientAddress?) {
        var temp = names
        while temp.first?.mailDisplayName == temp.last?.mailDisplayName, temp.first?.address == temp.last?.address, temp.count > 1 {
            temp.removeLast()
        }
        names = temp
        let first = names.first
        let last = names.last
        let secondAddress = names.first(where: { ($0.mailDisplayName != first?.mailDisplayName ?? "" || $0.address != first?.address ?? "")
                                                && ($0.mailDisplayName != last?.mailDisplayName ?? "" || $0.address != last?.address ?? "") })
        return (first, secondAddress, last)
    }
}

extension Array {
    func lastIndex(start: Int, where: (Self.Element) -> Bool) -> Int? {
        let min = (start < 0) ? 0 : start
        for i in stride(from: self.count - 1, to: min, by: -1) where `where`(self[i]) { return i }
        return nil
    }

    func firstIndex(start: Int, end: Int, where: (Self.Element) -> Bool) -> Int? {
        let min = (start < 0) ? 0 : start
        let max = (end > self.count) ? self.count : end
        for i in min..<max where `where`(self[i]) { return i }
        return nil
   }
}

extension Array where Element == String {
   func map(end: Int, trans: (String) -> (CGFloat)) -> [CGFloat] {
        var new: [CGFloat] = []
        let max = (end > self.count) ? self.count : end
        for i in 0..<max { new.append(trans(self[i])) }
        return new
    }
}

extension Array where Element == MailThreadListCellViewModel {
    mutating func changeUnreadState(at index: Int) -> Bool {
        assert(index >= 0 && index < self.count)
        guard index >= 0 && index < self.count else {
            return false
        }
        let model = self[index]
        model.isUnread = !model.isUnread
        if model.isUnread {
            model.labelIDs?.lf_appendIfNotContains(Mail_LabelId_UNREAD)
        } else {
            model.labelIDs?.lf_remove(object: Mail_LabelId_UNREAD)
        }
        self[index] = model
        return model.isUnread
    }

    mutating func changeFlagState(at index: Int) -> Bool {
        assert(index >= 0 && index < self.count)
        guard index >= 0 && index < self.count else {
            return false
        }
        let model = self[index]
        model.isFlagged = !model.isFlagged
        self[index] = model
        return model.isFlagged
    }
}

extension Array where Element == String {
    func toMailPriorityType() -> MailPriorityType {
        if self.contains(Mail_LabelId_HighPriority) {
            return .high
        } else if self.contains(Mail_LabelId_LowPriority) {
            return .low
        } else {
            return .normal
        }
    }
}
