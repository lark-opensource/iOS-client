//
//  MailFeedDraftListCellViewModel.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import RxSwift
import RustPB

class MailFeedDraftListCellViewModel: Hashable {
    var threadID: String = ""
    var draftID: String = ""
    var images: [MailClientDraftImage] = []
    var isFlagged: Bool = false
    var title: String
    var desc: String
    var replyTagType: MailReplyType
    var priorityType: MailPriorityType
    var hasAttachment: Bool = false
    var lastmessageTime: Int64
    var sendDisplayName: String? // 发件箱
    var displayAddress: [MailClientAddress] = []
    var bccAddress: [MailClientAddress] = []
    var labelID: String = ""
    var draft: MailClientDraft
    var labelIDs: [String]?
    var currentLabelID: String = ""
    var permissionCode: MailPermissionCode = .none
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
    init(with draftItem: MailFeedDraftItem) {
        let thread = draftItem.threadID
        self.threadID = draftItem.threadID
        self.images = draftItem.item.images
        self.replyTagType = draftItem.item.replyType
        self.priorityType = draftItem.item.priorityType
        self.isFlagged = draftItem.labelIds.contains(Mail_LabelId_FLAGGED) ? true : false
        self.desc = draftItem.item.bodySummary.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_EmptyBody : draftItem.item.bodySummary
        self.lastmessageTime = draftItem.item.createdTimestamp
        self.title = draftItem.item.subject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : draftItem.item.subject
        self.hasAttachment = !draftItem.item.attachments.isEmpty
        self.draftID = draftItem.item.id
        if !draftItem.item.to.isEmpty {
            self.displayAddress = draftItem.item.to
        } else if !draftItem.item.cc.isEmpty {
            self.displayAddress = draftItem.item.cc
        } else if !draftItem.item.bcc.isEmpty {
            self.displayAddress = draftItem.item.bcc
        }
        self.bccAddress = draftItem.item.bcc
        if let labelId = MailTagDataManager.shared.getTagModels(draftItem.labelIds).first?.id {
            self.labelID = labelId
        }
        self.sendDisplayName = MailFeedDraftListCellViewModel.genNameForSend(draftItem.item.to, draftItem.item.bcc)
        self.draft = draftItem.item
        self.labelIDs = draftItem.labelIds
        self.permissionCode = draftItem.item.permissionCode

    }
    
    init(push fromDraftItem: Email_Client_V1_FromViewDraftItem) {
        self.threadID = fromDraftItem.threadID
        self.images = fromDraftItem.item.images
        self.replyTagType = fromDraftItem.item.replyType
        self.priorityType = fromDraftItem.item.priorityType
        self.isFlagged = fromDraftItem.labelIds.contains(Mail_LabelId_FLAGGED) ? true : false
        self.desc = fromDraftItem.item.bodySummary
        self.lastmessageTime = fromDraftItem.item.hasLastUpdatedTimestamp ?
        fromDraftItem.item.lastUpdatedTimestamp : fromDraftItem.item.createdTimestamp
        self.title = fromDraftItem.item.subject
        self.hasAttachment = !fromDraftItem.item.attachments.isEmpty
        self.draftID = fromDraftItem.item.id
        if !fromDraftItem.item.to.isEmpty {
            self.displayAddress = fromDraftItem.item.to
        } else if !fromDraftItem.item.cc.isEmpty {
            self.displayAddress = fromDraftItem.item.cc
        } else if !fromDraftItem.item.bcc.isEmpty {
            self.displayAddress = fromDraftItem.item.bcc
        }
        self.bccAddress = fromDraftItem.item.bcc
        if let labelId = MailTagDataManager.shared.getTagModels(fromDraftItem.labelIds).first?.id {
            self.labelID = labelId
        }
        self.sendDisplayName = MailFeedDraftListCellViewModel.genNameForSend(fromDraftItem.item.to, fromDraftItem.item.bcc)
        self.draft = fromDraftItem.item
        self.labelIDs = fromDraftItem.labelIds
        self.permissionCode = fromDraftItem.item.permissionCode
    }
}


// MARK: 收件箱/发件箱 发件人/收件人展示文本生成 文档 https://bytedance.feishu.cn/docs/doccnkXx9PC7d7JXdZUOd4DAjMc
extension MailFeedDraftListCellViewModel {
    func getDisplayName(_ time: String, _ contentViewWidth: CGFloat, nameFont: UIFont) -> String? {
        if sendDisplayName != nil {
            self.sendDisplayName = MailFeedDraftListCellViewModel.genNameForSend(self.displayAddress,self.bccAddress)
            return sendDisplayName
        } else {
            return  BundleI18n.MailSDK.Mail_ThreadList_NoRecipients
        }
    }
    
    static func cellModelDisplayName(address: MailClientAddress?) -> String {
        if let address = address {
            return address.mailToDisplayName
        } else {
            return ""
        }
    }

    static func isNotIn(_ mailClientAddresses: [MailClientAddress], _ item: MailClientAddress) -> Bool {
        // 邮箱地址忽略大小写
        return !mailClientAddresses.contains(where: { $0.mailDisplayName == item.mailDisplayName && $0.address.caseInsensitiveCompare(item.address) == .orderedSame })
    }

    static func genNameForSend(_ addresses: [MailClientAddress],
                               _ bcc: [MailClientAddress] = []) -> String {
        if addresses.isEmpty && bcc.isEmpty {
            return BundleI18n.MailSDK.Mail_ThreadList_NoRecipients
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
        let firstName = MailFeedDraftListCellViewModel.cellModelDisplayName(address: first)
        let secondName = MailFeedDraftListCellViewModel.cellModelDisplayName(address: second)
        let lastName = MailFeedDraftListCellViewModel.cellModelDisplayName(address: last)

        var nameSet = Set(_names)
        if justBcc { nameSet = Set(_bcc) }
        if let first = first {
            nameSet.remove(first)
        }
        if let last = last {
            nameSet.remove(last)
        }
        
        if noBcc || justBcc {
            result = self.noBccOrjustBccResult(nameSet: nameSet, 
                                               firstName: firstName,
                                               secondName: secondName,
                                               lastName: lastName,
                                               first: first,
                                               last: last)
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
            let bccNameArr = removeDuplicateAndThreeNames(bcc, toCCNames: Set(toCCNames)).filter({ !MailFeedDraftListCellViewModel.cellModelDisplayName(address: $0).isEmpty })
            let bccCount = bccNameArr.count
            if Set(toCCNames).count == 1 {
                if bccCount >= 2 {
                    let sep = bccCount == 2 ? ", ": ".."
                    result = "\(MailFeedDraftListCellViewModel.cellModelDisplayName(address: toCCNames.first)), \(bccStr)\((MailFeedDraftListCellViewModel.cellModelDisplayName(address: bccNameArr.first)))\(sep)\((MailFeedDraftListCellViewModel.cellModelDisplayName(address: bccNameArr.last)))"
                } else if bccCount == 1 {
                    result = "\(MailFeedDraftListCellViewModel.cellModelDisplayName(address: toCCNames.first)), \(bccStr)\((MailFeedDraftListCellViewModel.cellModelDisplayName(address: bccNameArr.last)))"
                } else {
                    result = "\(MailFeedDraftListCellViewModel.cellModelDisplayName(address: toCCNames.first))"
                }
            } else {
                if bccNameArr.count > 0 {
                    let sep = bccCount > 1 ? ".." : ", "
                    result = "\(firstName), \(secondName.isEmpty ? lastName : secondName)\(sep)\(bccStr)\((MailFeedDraftListCellViewModel.cellModelDisplayName(address: bccNameArr.last)))"
                } else {
                    result = "\(firstName), \(secondName.isEmpty ? lastName: secondName)"
                }
            }
        }
        return result
    }
    
    static func noBccOrjustBccResult(nameSet: Set<MailClientAddress>,
                                      firstName: String,
                                      secondName: String,
                                      lastName: String,
                                      first: MailClientAddress?,
                                      last: MailClientAddress?) -> String{
        var result = ""
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
    
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
    
    static func == (lhs: MailFeedDraftListCellViewModel, rhs: MailFeedDraftListCellViewModel) -> Bool {
        guard lhs.isFlagged == rhs.isFlagged else { return false }
        guard lhs.threadID == rhs.threadID else { return false }
        guard lhs.displayAddress == rhs.displayAddress else { return false }
        guard lhs.replyTagType == rhs.replyTagType else { return false }
        guard lhs.draftID == rhs.draftID else { return false }
        guard lhs.hasAttachment == rhs.hasAttachment else { return false }
        guard lhs.labelID == rhs.labelID else { return false }
        guard lhs.lastmessageTime == rhs.lastmessageTime else { return false }
        guard lhs.priorityType == rhs.priorityType else { return false }
        guard lhs.bccAddress == rhs.bccAddress else { return false }
        guard lhs.desc == rhs.desc else { return false }
        guard lhs.sendDisplayName == rhs.sendDisplayName else { return false }
        guard lhs.title == rhs.title else { return false }
        guard lhs.images == rhs.images else { return false }
        guard lhs.draft == rhs.draft else { return false }

        return true
    }
}

extension Array where Element == MailFeedDraftListCellViewModel {
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
