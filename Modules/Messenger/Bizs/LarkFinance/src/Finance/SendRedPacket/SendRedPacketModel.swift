//
//  SendRedPacketModel.swift
//  Pods
//
//  Created by lichen on 2018/10/29.
//

import Foundation
import LarkModel
import RustPB
import LarkSDKInterface

struct SendRedPacketMetaModel {
    /// 红包总金额（单位：分）
    var totalAmount: Int64?
    /// 红包总数量
    var totalNum: Int32?
    /// 单个红包金额
    var singleAmount: Int64?
    /// 红包祝福内容
    var subject: String = ""
    ///红包封面
    var cover: HongbaoCover?

}

struct SendRedPacketContent {

    /// 红包总金额（单位：分）
    var totalAmount: Int64?

    /// 单个红包金额
    var singleAmount: Int64?

    /// 红包总数量
    var totalNum: Int32?

    /// 红包祝福内容
    var subject: String = ""

    /// 金钱输入字符串
    var moneyStr: String?

    /// 数目输入字符串
    var numberStr: String?

    var type: RustPB.Basic_V1_HongbaoContent.TypeEnum

    var channel: RustPB.Basic_V1_Channel

    ///红包封面
    var cover: HongbaoCover?

    ///上下文信息
    var context: SendRedPacketContext?

    init(type: RustPB.Basic_V1_HongbaoContent.TypeEnum, channel: RustPB.Basic_V1_Channel, context: SendRedPacketContext? = nil) {
        self.type = type
        self.channel = channel
        self.context = context
    }

    // 根据redPacketModel和SendRedpacketPageType来更新总钱数和数量
    mutating func updateData(redPacketPageModel res: RedPacketPageModel?,
                             selectedCount: Int,
                             currentType: SendRedpacketPageType) {
        guard let res = res, res.pageType != currentType else { return }
        switch (res.pageType, currentType) {
        case (.random, .equal):
            if let num = res.redPacketMetaModel.totalNum, num != 0 {
                self.totalNum = num
            }
            if let sum = res.redPacketMetaModel.totalAmount, sum != 0 {
                let singleAmount = sum / Int64(self.totalNum ?? 1)
                self.singleAmount = singleAmount
                let totalAmount = singleAmount * Int64((self.totalNum ?? 1))
                self.totalAmount = totalAmount
                self.moneyStr = "\(Double(totalAmount) / 100)"
            }
        case (.random, .exclusive):
            if let sum = res.redPacketMetaModel.totalAmount, sum != 0 {
                let num = res.redPacketMetaModel.totalNum
                let singleAmount = sum / Int64(num ?? 1)
                self.singleAmount = singleAmount
                let totalAmount = singleAmount * Int64((self.totalNum ?? 1))
                self.totalAmount = totalAmount
                self.moneyStr = "\(Double(totalAmount) / 100)"
            }
        case (.equal, .random):
            if let num = res.redPacketMetaModel.totalNum, num != 0 {
                self.totalNum = num
            }
            if let sum = res.redPacketMetaModel.totalAmount, sum != 0 {
                self.totalAmount = sum
                self.moneyStr = "\(Double(sum) / 100)"
            }
        case (.exclusive, .equal), (.equal, .exclusive), (.exclusive, .random):
            if let amount = res.redPacketMetaModel.singleAmount, amount != 0 {
                self.singleAmount = amount
                let totalAmount = amount * Int64((self.totalNum ?? 1))
                self.totalAmount = totalAmount
                self.moneyStr = "\(Double(totalAmount) / 100)"
            }
        default:
            if let sum = res.redPacketMetaModel.totalAmount, sum != 0 {
                self.totalAmount = sum
                self.moneyStr = "\(Double(sum) / 100)"
            }
        }
        // 统一同步祝福语和封面
        self.subject = res.redPacketMetaModel.subject
        self.cover = res.redPacketMetaModel.cover
    }
}

// 用于传递发红包的context
struct SendRedPacketContext {
    /// 当前群人数（用于群红包数量检验）
    var groupNum: Int?
}

struct RedPacketCheckResult {
    var content: SendRedPacketContent
    var errors: [SendRedPacketError]
    let chatId: String
    var selectedChatters: [Chatter]

    init(content: SendRedPacketContent,
         errors: [SendRedPacketError],
         chatId: String = "",
         selectedChatters: [Chatter] = []) {
        self.content = content
        self.errors = errors
        self.chatId = chatId
        self.selectedChatters = selectedChatters
    }
}

enum SendRedPacketError: Error, CustomStringConvertible {
    case money(String)
    case number(String)

    var description: String {
        switch self {
        case .money(let result):
            return result
        case .number(let result):
            return result
        }
    }
}
