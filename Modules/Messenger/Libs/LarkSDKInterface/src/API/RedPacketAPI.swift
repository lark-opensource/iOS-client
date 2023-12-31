//
//  RedPacketAPI.swift
//  LarkSDKInterface
//
//  Created by CharlieSu on 2018/10/30.
//

import Foundation
import RxSwift
import LarkModel
import ServerPB
import RustPB

public protocol RedPacketAPI {
    /// 获取钱包余额
    ///
    /// - Returns: 钱包余额
    func getBalance() -> Observable<WalletBalance>

    /// 获取红包信息
    ///
    /// - Parameter redPacketID: 红包ID
    /// - Returns: 红包信息
    func getRedPaketInfo(redPacketID: String) -> Observable<RedPacketInfo>

    /// 获取红包领取信息
    ///
    /// - Parameters:
    ///   - id: 红包id
    ///   - cursor: 抢红包的时间（单位：毫秒）降序返回小于该时间的领取记录，初始值传空
    ///   - count: 每次detail返回数目
    /// - Returns: 红包领取信息
    func getRedPacketReceiveDetail(redPacketID: String, type: RedPacketType, cursor: String, count: Int) -> Observable<RedPacketReceiveInfo>

    /// 抢红包请求
    ///
    /// - Parameter id: 红包id
    /// - Parameter chatId: 聊天id
    /// - Returns: 抢到金额信息
    func grabRedPacket(redPacketID: String,
                       chatId: String?,
                       type: RedPacketType,
                       financeSdkVersion: String) -> Observable<GrabRedPacketResult>

    /// 更新红包点击信息，调用这个请求后，红包状态会变成已经点击
    /// - Parameter messageID: 红包消息
    @discardableResult
    func updateRedPacket(messageID: String, type: RedPacketType, isClicked: Bool?, isGrabbed: Bool?, isGrabbedFinish: Bool?, isExpired: Bool) -> Observable<Void>

    /// 发送红包
    ///
    /// - Parameters:
    ///   - totalAmount: 红包总金额 单位分
    ///   - totalNum: 红包总数量
    ///   - subject: 红包主题
    ///   - type: 红包类型
    ///   - channel: 红包 channel 目前支持 chat
    /// - Returns: 发送结果
    func sendRedPacket(totalAmount: Int64,
                       coverId: Int64?,
                       totalNum: Int32,
                       subject: String,
                       receiveUserIds: [Int64]?,
                       type: RustPB.Basic_V1_HongbaoContent.TypeEnum,
                       channel: RustPB.Basic_V1_Channel,
                       isByteDancer: Bool,
                       financeSdkVersion: String) -> Observable<SendRedPacketResult>

    // 获取 paytoken
    func getPayToken() -> Observable<String>

    func grabRedPacketRecords(year: Int, cursor: String, count: Int) -> Observable<GrabRedPacketHistoryResult>

    func sendRedPacketRecords(year: Int, cursor: String, count: Int) -> Observable<SendRedPacketHistoryResult>

    func getRedPacketInfoAndReceiveDetail(redPacketID: String, type: RedPacketType) -> Observable<(RedPacketInfo, RedPacketReceiveInfo)>

    func pullHongbaoCoverListRequest() -> Observable<PullHongbaoCoverListResponse>
}

public typealias HongbaoCover = ServerPB.ServerPB_Entities_HongbaoCover
public typealias HongbaoCoverDisplayName = RustPB.Basic_V1_HongbaoCover.DisplayName
public typealias PullHongbaoCoverListResponse = ServerPB.ServerPB_Hongbao_PullHongbaoCoverListResponse
public typealias CurrencyType = RustPB.Im_V1_GetWalletBalanceResponse.CurrencyType
public typealias HongbaoGrabStatus = RustPB.Im_V1_HongbaoRecvDetail.HongbaoGrabStatus

public struct WalletBalance {
    public let balance: Int64
    public let currency: CurrencyType

    public init(balance: Int64, currency: CurrencyType) {
        self.balance = balance
        self.currency = currency
    }
}

public typealias RedPacketType = HongbaoContent.TypeEnum

public struct RedPacketInfo {
    /// 红包id
    public let redPacketID: String

    public let chatter: Chatter?
    /// 红包发送者id
    public let userID: String
    /// 红包总金额
    public let totalAmount: Int
    /// 总数量
    public let totalNumber: Int
    /// 已领取数量
    public let grabNumber: Int
    /// 红包祝福语
    public let subject: String
    /// 红包类型
    public let type: RedPacketType
    /// 是否已经抢到红包，抢到红包的金额
    public let grabAmount: Int?
    /// 红包是否已经过期
    public let isExpired: Bool
    /// 当前手气最佳UserID
    public let luckyUserID: String
    /// 所有人抢到红包的总金额
    public let totalGrabAmount: Int
    /// 红包是否已经抢完
    public var isGrabbedFinish: Bool {
        return grabNumber == totalNumber
    }
    // 企业定制描述
    public var hongbaoCoverDisplayName: HongbaoCoverDisplayName?

    // 企业名称
    public var hongbaoCoverCompanyName: String?

    /// 红包封面
    public var cover: HongbaoCover?

    /// 是否是B2C红包(企业红包)
    public var isB2C: Bool {
        return type == .b2CRandom || type == .b2CFix
    }

    /// 红包是否可以抢
    public var canGrab: Bool {
        // 没过期, 没抢完, 没抢过
        if !isExpired, !isGrabbedFinish, grabAmount == nil {
            return true
        }
        return false
    }

    // 有否有权限领取
    public var hasPermissionToGrab: Bool

    public init(redPacketID: String,
                chatter: Chatter?,
                userID: String,
                totalAmount: Int,
                totalNumber: Int,
                grabNumber: Int,
                subject: String,
                type: RedPacketType,
                grabAmount: Int?,
                isExpired: Bool,
                luckyUserID: String,
                cover: HongbaoCover? = nil,
                hasPermissionToGrab: Bool,
                hongbaoCoverDisplayName: HongbaoCoverDisplayName?,
                hongbaoCoverCompanyName: String?,
                totalGrabAmount: Int) {
        self.redPacketID = redPacketID
        self.chatter = chatter
        self.userID = userID
        self.cover = cover
        self.totalAmount = totalAmount
        self.totalNumber = totalNumber
        self.grabNumber = grabNumber
        self.subject = subject
        self.type = type
        self.hasPermissionToGrab = hasPermissionToGrab
        self.hongbaoCoverDisplayName = hongbaoCoverDisplayName
        self.grabAmount = grabAmount
        self.isExpired = isExpired
        self.luckyUserID = luckyUserID
        self.hongbaoCoverCompanyName = hongbaoCoverCompanyName
        self.totalGrabAmount = totalGrabAmount
    }
}

public struct RedPacketReceiveInfo {
    /// 红包id
    public let redPacketID: String
    public let details: [RedPacketReceiveDetail]
    public let hasMore: Bool
    public let nextCursor: String

    public var grabNumber: Int?

    public var totalGrabAmount: Int?

    public var luckyUserID: String?

    public init(
        redPacketID: String,
        details: [RedPacketReceiveDetail],
        hasMore: Bool,
        nextCursor: String,
        grabNumber: Int?,
        totalGrabAmount: Int?,
        luckyUserID: String?
    ) {
        self.redPacketID = redPacketID
        self.details = details
        self.hasMore = hasMore
        self.nextCursor = nextCursor
        self.grabNumber = grabNumber
        self.totalGrabAmount = totalGrabAmount
        self.luckyUserID = luckyUserID
    }
}

public struct RedPacketReceiveDetail {
    /// 领取用户id
    public var chatter: Chatter
    /// 领取的金额（单位：分）
    public var amount: Int
    /// 领取时间
    public var time: Int64
    /// 领取状态
    public let receiveStatus: HongbaoGrabStatus?

    public init(chatter: Chatter, amount: Int, time: Int64, receiveStatus: HongbaoGrabStatus?) {
        self.chatter = chatter
        self.amount = amount
        self.time = time
        self.receiveStatus = receiveStatus
    }
}

public struct GrabRedPacketResult {
    /// 抢到的金额（单位：分）
    public let amount: Int
    public let isRealNameAuthed: Bool
    public let authURL: String

    public init(amount: Int, isRealNameAuthed: Bool, authURL: String) {
        self.amount = amount
        self.isRealNameAuthed = isRealNameAuthed
        self.authURL = authURL
    }
}

public struct SendRedPacketResult {
    public let id: String
    public let paramsString: String
    public let payURLType: Im_V1_SendHongbaoResponse.PayURLType

    public init(id: String, paramsString: String, payURLType: Im_V1_SendHongbaoResponse.PayURLType) {
        self.id = id
        self.paramsString = paramsString
        self.payURLType = payURLType
    }
}

public enum SendRedPacketRecordType {
    case singChat(chatter: Chatter)
    case multiChat(chat: Chat)
}

public struct SendRedPacketRecord {
    public let redPacketID: String
    public let totalAmount: Int
    public let createTime: Int
    public let totalNum: Int
    public let grabNum: Int
    public let isExpired: Bool
    public let type: SendRedPacketRecordType

    public init(redPacketID: String,
                totalAmount: Int,
                createTime: Int,
                totalNum: Int,
                grabNum: Int,
                isExpired: Bool,
                type: SendRedPacketRecordType) {
        self.redPacketID = redPacketID
        self.totalAmount = totalAmount
        self.createTime = createTime
        self.totalNum = totalNum
        self.grabNum = grabNum
        self.isExpired = isExpired
        self.type = type
    }
}

public struct SendRedPacketHistoryResult {
    public let year: Int
    public let totalNumber: Int
    public let totalAmount: Int
    public var records: [SendRedPacketRecord]
    public let hasMore: Bool
    public let currentCursor: String
    public let nextCursor: String

    public init(year: Int,
                totalNumber: Int,
                totalAmount: Int,
                records: [SendRedPacketRecord],
                hasMore: Bool,
                currentCursor: String,
                nextCursor: String) {
        self.year = year
        self.totalNumber = totalNumber
        self.totalAmount = totalAmount
        self.records = records
        self.hasMore = hasMore
        self.currentCursor = currentCursor
        self.nextCursor = nextCursor
    }
}

public struct GrabRedPacketRecord {
    public let redPacketID: String
    public let grabAmount: Int
    public let grabTime: Int
    public let chatter: Chatter?
    public let chat: Chat? // 当isP2P为false的时候有值
    public let isP2P: Bool
    public let companyInfo: RustPB.Im_V1_GrabHongbaoRecord.CompanyInfo
    public let type: RustPB.Basic_V1_HongbaoContent.TypeEnum
    public var isB2C: Bool {
        return self.type == .b2CFix || self.type == .b2CRandom
    }
    public init(redPacketID: String,
                grabAmount: Int,
                grabTime: Int,
                chatter: Chatter?,
                chat: Chat?,
                isP2P: Bool,
                companyInfo: RustPB.Im_V1_GrabHongbaoRecord.CompanyInfo,
                type: RustPB.Basic_V1_HongbaoContent.TypeEnum) {
        self.redPacketID = redPacketID
        self.grabAmount = grabAmount
        self.grabTime = grabTime
        self.chatter = chatter
        self.chat = chat
        self.isP2P = isP2P
        self.companyInfo = companyInfo
        self.type = type
    }
}

public struct GrabRedPacketHistoryResult {
    public let year: Int
    public let totalNumber: Int
    public let totalAmount: Int
    public var records: [GrabRedPacketRecord]
    public let hasMore: Bool
    public let currentCursor: String
    public let nextCursor: String

    public init(year: Int,
                totalNumber: Int,
                totalAmount: Int,
                records: [GrabRedPacketRecord],
                hasMore: Bool,
                currentCursor: String,
                nextCursor: String) {
        self.year = year
        self.totalNumber = totalNumber
        self.totalAmount = totalAmount
        self.records = records
        self.hasMore = hasMore
        self.currentCursor = currentCursor
        self.nextCursor = nextCursor
    }
}
