//
//  RedPacketHistoryModel.swift
//  LarkFile
//
//  Created by SuPeng on 12/23/18.
//

import Foundation
import LarkModel
import LarkSDKInterface
import ByteWebImage

/// 红包是从2018年上线的，所以历史记录默认从2018年到现在
let redPacketServiceStartYear: Int = 2018

protocol RedPacketReceviedSentRecord {
    var redPacketID: String { get }

    var displayName: String { get }

    var avatarKey: String { get }

    var avatarId: String { get }

    var date: Date { get }

    var sum: Int { get }

    var description: String? { get }

    var companyLogoPassThrough: ImagePassThrough? { get }
}

extension GrabRedPacketRecord: RedPacketReceviedSentRecord {
    var avatarKey: String {
        return chatter?.avatarKey ?? ""
    }

    var displayName: String {
        /// 如果是企业红包 返回企业的名字
        if isB2C {
            return companyInfo.companyName
        }
        if !isP2P, let chat = chat {
            return (chatter?.displayName ?? "") + "-" + chat.displayName
        }
        return chatter?.displayName ?? ""
    }

    var avatarId: String {
        return chatter?.id ?? ""
    }

    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(grabTime))
    }

    var sum: Int {
        return grabAmount
    }

    var description: String? {
        return nil
    }

    var companyLogoPassThrough: ImagePassThrough? {
        guard isB2C else {
            return nil
        }
        var pass = ImagePassThrough()
        pass.key = companyInfo.companyLogo.key
        pass.fsUnit = companyInfo.companyLogo.fsUnit
        return pass
    }
}

extension SendRedPacketRecord: RedPacketReceviedSentRecord {
    var avatarKey: String {
        switch type {
        case .multiChat(chat: let chat):
            return chat.avatarKey
        case .singChat(chatter: let chatter):
            return chatter.avatarKey
        }
    }

    var avatarId: String {
        switch type {
        case .multiChat(chat: let chat):
            return chat.id
        case .singChat(chatter: let chatter):
            return chatter.id
        @unknown default:
            fatalError("new value")
        }
    }

    var displayName: String {
        switch type {
        case .multiChat(chat: let chat):
            return chat.displayName
        case .singChat(chatter: let chatter):
            return chatter.displayName
        @unknown default:
            fatalError("new value")
        }
    }

    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(createTime))
    }

    var sum: Int {
        return totalAmount
    }

    var description: String? {
        switch type {
        case .singChat:
            if totalNum == grabNum {
                return BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryReceived
            } else {
                if isExpired {
                    return BundleI18n.LarkFinance.Lark_Legacy_HistoryExpired
                } else {
                    return BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryUnreceived
                }
            }
        case .multiChat:
            let progress = BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryAmount(grabNum, totalNum)
            if totalNum == grabNum {
                return BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryReceived + " " + progress
            } else {
                if isExpired {
                    return BundleI18n.LarkFinance.Lark_Legacy_HistoryExpired + " " + progress
                } else {
                    if grabNum > 0 {
                        return BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryReceived + " " + progress
                    } else {
                        return BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryUnreceived + " " + progress
                    }
                }
            }
        @unknown default:
            assert(false, "new value")
            return nil
        }
    }

    var companyLogoPassThrough: ImagePassThrough? {
        return nil
    }
}

protocol RedPacketHistoryDataSource {
    var year: Int { get }
    var totalNumber: Int { get }
    var totalAmount: Int { get }
    var historyRecords: [RedPacketReceviedSentRecord] { get set }
    var hasMore: Bool { get }
    var currentCursor: String { get }
    var nextCursor: String { get }
}

extension SendRedPacketHistoryResult: RedPacketHistoryDataSource {
    var historyRecords: [RedPacketReceviedSentRecord] {
        get {
            return records
        }
        set {
            records = newValue.compactMap { $0 as? SendRedPacketRecord }
        }
    }
}
extension GrabRedPacketHistoryResult: RedPacketHistoryDataSource {
    var historyRecords: [RedPacketReceviedSentRecord] {
        get {
            return records
        }
        set {
            records = newValue.compactMap { $0 as? GrabRedPacketRecord }
        }
    }
}
