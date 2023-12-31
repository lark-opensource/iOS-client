//
//  SendRedPacketRule.swift
//  Action
//
//  Created by lichen on 2018/10/29.
//

import Foundation
import LarkModel
import RustPB

protocol SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?)
}

final class SendRedPackerChecker {
    var rules: [SendRedPacketRule] = []

    func check(content: SendRedPacketContent, chatId: String, selectedChatters: [Chatter]) -> RedPacketCheckResult {
        var content = content
        var errors: [SendRedPacketError] = []

        self.rules.forEach { (rule) in
            let (c, error) = rule.check(content: content)
            content = c
            if let error = error {
                errors.append(error)
            }
        }

        return RedPacketCheckResult(content: content,
                                    errors: errors,
                                    chatId: chatId,
                                    selectedChatters: selectedChatters)
    }

    static var defaultRules: [SendRedPacketRule] {
        var rules: [SendRedPacketRule] = []
        rules.append(P2pMoneyMaxCheck())
        rules.append(P2pMoneyMinCheck())
        rules.append(GroupNumberMinCheck())
        rules.append(GroupNumberMaxCheck())
        rules.append(GroupMoneyEveryPacketMaxCheck())
        rules.append(GroupMoneyEveryPacketMinCheck())
        rules.append(GroupMoneyTotleCheck())
        return rules
    }
}

final class P2pMoneyMaxCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {
        if content.type == .p2P,
            let totalAmount = content.totalAmount,
            totalAmount > 20_000 {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_UpTo200CNY))
        }
        return (content, nil)
    }
}

final class P2pMoneyMinCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {
        if content.type == .p2P,
            let totalAmount = content.totalAmount,
            totalAmount < 1 {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_AtLeast001CNY))
        }
        return (content, nil)
    }
}

final class GroupNumberMinCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {
        let types: [RustPB.Basic_V1_HongbaoContent.TypeEnum] = [.groupFix, .groupRandom]
        if types.contains(content.type),
            let totalNum = content.totalNum,
            totalNum < 1 {
            return (content, .number(BundleI18n.LarkFinance.Lark_Legacy_QuantityCantBeEmpty))
        }
        return (content, nil)
    }
}

final class GroupNumberMaxCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {
        let types: [RustPB.Basic_V1_HongbaoContent.TypeEnum] = [.groupFix, .groupRandom, .exclusive]
        if types.contains(content.type),
           let totalNum = content.totalNum,
           let groupNum = content.context?.groupNum,
           totalNum > groupNum {
            return (content, .number(BundleI18n.LarkFinance.Lark_IM_RedPacket_RedPacketNumberCannotExceedGoupMembers_Toast))
        }
        return (content, nil)
    }
}

final class GroupMoneyTotleCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {
        let upperLimit = 5_000_000
        if content.type == .groupRandom,
            let totalAmount = content.totalAmount,
            totalAmount > upperLimit {
            return (content, .money(BundleI18n.LarkFinance.Lark_RedPacket_EachPaymentUpperLimit(upperLimit / 100)))
        } else if content.type == .groupFix || content.type == .exclusive,
            let singleAmount = content.singleAmount,
            let totalNum = content.totalNum,
            totalNum > 0,
            singleAmount * Int64(totalNum) > upperLimit {
            return (content, .money(BundleI18n.LarkFinance.Lark_RedPacket_EachPaymentUpperLimit(upperLimit / 100)))
        }

        return (content, nil)
    }
}

final class GroupMoneyEveryPacketMaxCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {

        if content.type == .groupRandom,
            let totalAmount = content.totalAmount,
            let totalNum = content.totalNum,
            totalNum > 0,
            (totalAmount / Int64(totalNum)) > 20_000 {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_UpTo200CNYForEachHongbao))
        } else if content.type == .groupFix || content.type == .exclusive,
            let singleAmount = content.singleAmount,
            singleAmount > 20_000 {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_UpTo200CNYForEachHongbao))
        }

        return (content, nil)
    }
}

final class GroupMoneyEveryPacketMinCheck: SendRedPacketRule {
    func check(content: SendRedPacketContent) -> (SendRedPacketContent, SendRedPacketError?) {

        if content.type == .groupRandom,
            let totalAmount = content.totalAmount,
            let totalNum = content.totalNum,
            totalNum > 0,
            (totalAmount / Int64(totalNum)) < 1 {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_AtLeast001CNY))
        } else if content.type == .groupFix || content.type == .exclusive,
            let singleAmount = content.singleAmount,
            singleAmount < 1 {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_AtLeast001CNY))
        } else if content.type == .groupRandom,
            let money = content.moneyStr,
            money == "0.00" {
            return (content, .money(BundleI18n.LarkFinance.Lark_Legacy_AtLeast001CNY))
        }

        return (content, nil)
    }
}
