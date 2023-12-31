//
//  MailInterceptWebImageHelper.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/12/19.
//

import Foundation

struct MailInterceptWebImageHelper {
    private static let StoreKey = "larkmail.intercept_web_image_white_list"
    private static let Capacity  = 100
    
    /// 拦截规则
    /// https://bytedance.sg.feishu.cn/docx/doxlgDTS5rIajU5nDsDK1W1dIXd#doxlgcWC2sWieAeeiWu6jo4aoRe
    static func filterInterceptedMessageIDs(
        messageItems: [MailMessageItem],
        userID: String,
        labelID: String,
        dataManager: MailSettingManager,
        store: MailKVStore,
        from: MessageListStatInfo.FromType
    ) -> [String] {
        if labelID == Mail_LabelId_Spam {
            return messageItems.map({ $0.message.id })
        } else {
            let whiteList: [String] = store.value(forKey: StoreKey) ?? []
            let myAddresses = dataManager.getCachedCurrentSetting()?.emailAlias.allAddresses ?? []
            let isEnableWebImageSetting = dataManager.getCachedPrimaryAccount()?.mailSetting.webImageDisplay == true
            
            return messageItems.filter({ messageItem in
                if !messageItem.showSafeTipsBanner && isEnableWebImageSetting {
                    return false
                } else if !messageItem.showSafeTipsBanner && !isEnableWebImageSetting && (from == .emlPreview || from == .emailReview || from == .imFile) {
                    return true
                } else if labelID == Mail_LabelId_Sent || messageItem.isSendByMe(myAddresses: myAddresses, myUserID: userID) {
                    return false
                } else if whiteList.contains(messageItem.message.id) {
                    return false
                }
                return true
            }).map({ $0.message.id })
        }
    }
    
    // FG：larkmail.cli.web_image_blocking_2 下会优先使用from去做过滤，不是每封邮件都一定有from，需要再过滤一遍ID做兜底
    static func filterInterceptedMessageFroms(
        messageItems: [MailMessageItem],
        userID: String,
        labelID: String,
        dataManager: MailSettingManager,
        store: MailKVStore,
        from: MessageListStatInfo.FromType
    ) -> [String] {
        if labelID == Mail_LabelId_Spam {
            return messageItems.map({ $0.message.from.address })
        } else {
            let whiteList: [String] = store.value(forKey: StoreKey) ?? []
            let myAddresses = dataManager.getCachedCurrentSetting()?.emailAlias.allAddresses ?? []
            let isEnableWebImageSetting = dataManager.getCachedPrimaryAccount()?.mailSetting.webImageDisplay == true
            
            return messageItems.filter({ messageItem in
                if !messageItem.showSafeTipsBanner && isEnableWebImageSetting {
                    return false
                } else if !messageItem.showSafeTipsBanner && !isEnableWebImageSetting && (from == .emlPreview || from == .emailReview || from == .imFile) {
                    return true
                } else if labelID == Mail_LabelId_Sent || messageItem.isSendByMe(myAddresses: myAddresses, myUserID: userID) {
                    return false
                } else if whiteList.contains(messageItem.message.id) {
                    return false
                }

                return true
            }).map({ $0.message.from.address })
        }
    }
    // 过滤出来需要拦截且没有带from的messageID
    static func filterInterceptedMessageWithoutFromsIds(
        messageItems: [MailMessageItem],
        userID: String,
        labelID: String,
        dataManager: MailSettingManager,
        store: MailKVStore,
        from: MessageListStatInfo.FromType,
        fromsAddress: [String]
    ) -> [String] {
        let filterMessageItems = messageItems.filter({!fromsAddress.contains($0.message.from.address)}).map({$0})
        return filterInterceptedMessageIDs(messageItems: filterMessageItems,
                                    userID: userID,
                                    labelID: labelID,
                                    dataManager: dataManager,
                                    store: store,
                                    from: from)
    }
    
    // 将返回的allowedfroms映射成messageIDs
    static func allowedfromsTomessageIDs(messageItems: [MailMessageItem], froms: [String]) -> [String] {
        return messageItems.filter({froms.contains($0.message.from.address)
        }).map({ $0.message.id})
    }
    
    static func isMessageInWhiteList(messageID: String, store: MailKVStore) -> Bool {
        let whiteList: [String] = store.value(forKey: StoreKey) ?? []
        return whiteList.contains(messageID)
    }
    
    static func updateInterceptWhiteList(messageID: String, store: MailKVStore) {
        guard var whiteList: [String] = store.value(forKey: StoreKey) else {
            store.set([messageID], forKey: StoreKey)
            return
        }

        MailLogger.info("[Intercept-image] update intercepted image white list message id: \(messageID)")
        
        if !whiteList.contains(messageID) {
            whiteList.append(messageID)
            while whiteList.count >= Capacity {
                whiteList.removeFirst()
            }
        } else {
            whiteList.lf_remove(object: messageID)
            whiteList.append(messageID)
            while whiteList.count >= Capacity {
                whiteList.removeFirst()
            }
        }
        store.set(whiteList, forKey: StoreKey)
    }
}
