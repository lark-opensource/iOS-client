//
//  RustRedPacketAPI.swift
//  LarkSDK
//
//  Created by CharlieSu on 2018/10/30.
//

import Foundation
import LarkSDKInterface
import LarkFeatureGating
import RustPB
import LarkModel
import RxSwift
import ServerPB
import LKCommonsLogging

typealias GetWalletBalanceRequest = Im_V1_GetWalletBalanceRequest
typealias GetWalletBalanceResponse = Im_V1_GetWalletBalanceResponse
typealias GetHongbaoInfoRequest = Im_V1_GetHongbaoInfoRequest
typealias GetHongbaoInfoResponse = Im_V1_GetHongbaoInfoResponse
typealias GetHongbaoRecvDetailRequest = Im_V1_GetHongbaoRecvDetailRequest
typealias GetHongbaoRecvDetailResponse = Im_V1_GetHongbaoRecvDetailResponse
typealias GrabHongbaoRequest = Im_V1_GrabHongbaoRequest
typealias GrabHongbaoResponse = Im_V1_GrabHongbaoResponse
typealias UpdateHongbaoRequest = Im_V1_UpdateHongbaoRequest
typealias UpdateHongbaoResponse = Im_V1_UpdateHongbaoResponse
typealias SendHongbaoRequest = Im_V1_SendHongbaoRequest
typealias SendHongbaoResponse = Im_V1_SendHongbaoResponse
typealias GetPayTokenRequest = Im_V1_GetPayTokenRequest
typealias GetPayTokenResponse = Im_V1_GetPayTokenResponse
typealias GetGrabHongbaoRecordRequest = Im_V1_GetGrabHongbaoRecordRequest
typealias GetSendHongbaoRecordRequest = Im_V1_GetSendHongbaoRecordRequest
typealias GetGrabHongbaoRecordResponse = Im_V1_GetGrabHongbaoRecordResponse
typealias GetSendHongbaoRecordResponse = Im_V1_GetSendHongbaoRecordResponse

extension Basic_V1_HongbaoCover {
    // 目前对红包Cover定义了俩PB: ServerPB的和RustPB的, 这里进行一次转换
    func transformToServerHongbaoCover() -> HongbaoCover {
        var cover = HongbaoCover()
        cover.id = self.id
        cover.name = self.name
        cover.mainCover.key = self.mainCover.key
        cover.mainCover.fsUnit = self.mainCover.fsUnit

        cover.messageCover.key = self.messageCover.key
        cover.messageCover.fsUnit = self.messageCover.fsUnit

        cover.headCover.key = self.headCover.key
        cover.headCover.fsUnit = self.headCover.fsUnit

        cover.companyLogo.key = self.companyLogo.key
        cover.companyLogo.fsUnit = self.companyLogo.fsUnit
        switch self.coverType {
        case .customize:
            cover.coverType = .customize
        case .template:
            cover.coverType = .template
        case .unknown:
            cover.coverType = .unknown
        @unknown default:
            assertionFailure("unknown type")
            cover.coverType = .unknown
        }
        return cover
    }
}

final class RustRedPaketAPI: LarkAPI, RedPacketAPI {

    static let logger = Logger.log(RustRedPaketAPI.self, category: "RustSDK.RedPacket")

    /// 获取钱包余额
    ///
    /// - Returns: 钱包余额
    func getBalance() -> Observable<WalletBalance> {
        let request = GetWalletBalanceRequest()
        let result: Observable<GetWalletBalanceResponse> = client.sendAsyncRequest(request)
        return result.map { WalletBalance(balance: $0.balance, currency: $0.currency) }
            .do(onNext: { (balance) in
                RustRedPaketAPI.logger.info("Get balance success" + "\(balance)")
            }, onError: { (error) in
                RustRedPaketAPI.logger.error("Get balance error", error: error)
            })
    }

    /// 获取红包信息
    ///
    /// - Parameter id: 消息id
    /// - Returns: 红包信息
    func getRedPaketInfo(redPacketID: String) -> Observable<RedPacketInfo> {
        let hongbaoType: Im_V1_HongbaoType = .normal
        var infoRequest = GetHongbaoInfoRequest()
        infoRequest.id = redPacketID
        infoRequest.hongbaoType = hongbaoType
        let infoResponse: Observable<GetHongbaoInfoResponse> = client.sendAsyncRequest(infoRequest)
        return infoResponse.flatMap { (info) -> Observable<RedPacketInfo> in
            Observable.create { (observer) -> Disposable in
                let chatterPB = info.entity.chatters.randomElement()?.value
                var hasCover = (info.hasCover && info.cover.id != 0)
                let isB2C = info.type == .b2CFix || info.type == .b2CRandom
                /// B2C红包 不会下发chatter& info.cover.id
                if isB2C {
                    hasCover = true
                }
                if chatterPB != nil || isB2C {
                    var chatter: LarkModel.Chatter?
                    if let pb = chatterPB {
                        chatter = LarkModel.Chatter.transform(pb: pb)
                    }
                    observer.onNext(RedPacketInfo(redPacketID: redPacketID,
                                                  chatter: chatter,
                                                  userID: info.userID,
                                                  totalAmount: Int(info.totalAmount),
                                                  totalNumber: Int(info.totalNum),
                                                  grabNumber: Int(info.grabNum),
                                                  subject: info.subject,
                                                  type: info.type,
                                                  grabAmount: info.hasGrabbed_p ? Int(info.grabAmount) : nil,
                                                  isExpired: info.isExpired,
                                                  luckyUserID: info.luckyUserID,
                                                  cover: hasCover ? info.cover.transformToServerHongbaoCover() : nil,
                                                  hasPermissionToGrab: info.canGrab,
                                                  hongbaoCoverDisplayName: info.cover.hasDisplayName ? info.cover.displayName : nil,
                                                  hongbaoCoverCompanyName: info.cover.companyName,
                                                  totalGrabAmount: Int(info.totalGrabAmount)))
                } else {
                    observer.onError(RedPacketError(errorReason: "response.entity中缺少Chatter数据"))
                }
                observer.onCompleted()
                return Disposables.create()
            }
        }
        .do(onNext: { (_) in
            RustRedPaketAPI.logger.info("Get redPacketInfo success" + redPacketID)
        }, onError: { (error) in
            RustRedPaketAPI.logger.error("Get redPacketInfo error", additionalData: ["redPacketID": redPacketID], error: error)
        })
    }

    /// 获取红包领取信息
    ///
    /// - Parameters:
    ///   - id: 红包id
    ///   - cursor: 抢红包的时间（单位：毫秒）降序返回小于该时间的领取记录，初始值传 0
    ///   - count: 每次detail返回数目
    /// - Returns: 红包领取信息
    func getRedPacketReceiveDetail(redPacketID: String, type: RedPacketType, cursor: String, count: Int) -> Observable<RedPacketReceiveInfo> {
        let hongbaoType: Im_V1_HongbaoType = type == .commercial ? .commercial : .normal
        var detailRequest = GetHongbaoRecvDetailRequest()
        detailRequest.id = redPacketID
        detailRequest.hongbaoType = hongbaoType
        detailRequest.cursor = cursor
        detailRequest.count = Int32(count)
        let detailReponse: Observable<GetHongbaoRecvDetailResponse> = client.sendAsyncRequest(detailRequest)
        return detailReponse.flatMap { (response) -> Observable<RedPacketReceiveInfo> in
            Observable.create { (observer) -> Disposable in
                var missingChatterIds: [String] = []
                let details = response.details.compactMap { (detail) -> RedPacketReceiveDetail? in
                    let chatter = response.entity.chatters[detail.userID].flatMap { LarkModel.Chatter.transform(pb: $0) }
                    if chatter == nil { missingChatterIds.append(detail.userID) }
                    return chatter.flatMap { RedPacketReceiveDetail(chatter: $0,
                                                                    amount: Int(detail.amount),
                                                                    time: detail.time,
                                                                    receiveStatus: detail.hasReceiveStatus ? detail.receiveStatus : nil)
                    }
                }
                if missingChatterIds.isEmpty {
                    observer.onNext(RedPacketReceiveInfo(redPacketID: redPacketID,
                                                         details: details,
                                                         hasMore: response.hasMore_p,
                                                         nextCursor: response.nextCursor,
                                                         grabNumber: response.hasGrabNum ? Int(response.grabNum) : nil,
                                                         totalGrabAmount: response.hasTotalGrabAmount ? Int(response.totalGrabAmount) : nil,
                                                         luckyUserID: response.hasLuckyUserID ? response.luckyUserID : nil))
                } else {
                    observer.onError(RedPacketError(errorReason: "response.entity中缺少Chatter数据" + missingChatterIds.joined(separator: "||")))
                }
                observer.onCompleted()
                return Disposables.create()
            }
        }
        .do(onNext: { (info) in
            RustRedPaketAPI.logger.info("Get redPacketReceiveDetail success" + redPacketID)
            if cursor.isEmpty, (info.grabNumber == nil || info.totalGrabAmount == nil) {
                RustRedPaketAPI.logger.error(
                    "Get redPacketReceiveDetail error, missing grabNumber of totalGrabAmount when cursor is empty",
                    additionalData: ["redPacketID": redPacketID]
                )
            }
        }, onError: { (error) in
            RustRedPaketAPI.logger.error("Get redPacketReceiveDetail error", additionalData: ["redPacketID": redPacketID], error: error)
        })
    }

    /// 抢红包请求
    ///
    /// - Parameter id: 红包id
    /// - Returns: 抢到金额信息
    func grabRedPacket(redPacketID: String, chatId: String?, type: RedPacketType, financeSdkVersion: String) -> Observable<GrabRedPacketResult> {
        let hongbaoType: Im_V1_HongbaoType = type == .commercial ? .commercial : .normal
        var request = GrabHongbaoRequest()
        request.id = redPacketID
        request.hongbaoType = hongbaoType
        request.isReturnNameAuth = true
        if let chatId = chatId, let intChatId = Int64(chatId) {
            request.chatID = intChatId
        }
        var deviceInfo = GrabHongbaoRequest.DeviceInfo()
        deviceInfo.financeSdkVersion = financeSdkVersion
        request.deviceInfo = deviceInfo
        let response: Observable<GrabHongbaoResponse> = client.sendAsyncRequest(request)
        return response.map({ (response) -> GrabRedPacketResult in
                return GrabRedPacketResult(
                    amount: Int(response.amount),
                    isRealNameAuthed: response.isRealNameAuthed,
                    authURL: response.authURL
                )
            })
            .do(onNext: { (_) in
                RustRedPaketAPI.logger.info("Grab redPacket success" + redPacketID)
            }, onError: { (error) in
                RustRedPaketAPI.logger.error("Grab redPacket error", additionalData: ["redPacketID": redPacketID], error: error)
            })
    }

    /// 更新红包点击信息，调用这个请求后，红包状态会变成已经点击
    ///
    /// - Parameter id: 消息ID
    func updateRedPacket(messageID: String,
                         type: RedPacketType,
                         isClicked: Bool?,
                         isGrabbed: Bool?,
                         isGrabbedFinish: Bool?,
                         isExpired: Bool) -> Observable<Void> {
        let hongbaoType: Im_V1_HongbaoType = type == .commercial ? .commercial : .normal
        var request = UpdateHongbaoRequest()
        request.id = messageID
        request.hongbaoType = hongbaoType
        if let isClicked = isClicked {
            request.clicked = isClicked
        }
        if let isGrabbed = isGrabbed {
            request.grabbed = isGrabbed
        }
        if let isGrabbedFinish = isGrabbedFinish {
            request.grabbedFinish = isGrabbedFinish
        }
        request.isExpired = isExpired
        let result: Observable<UpdateHongbaoResponse> = client.sendAsyncRequest(request)
        return result.map { _ in return }
            .do(onNext: { _ in
                RustRedPaketAPI.logger.info("Update redPacket success" + messageID)
            }, onError: { (error) in
                RustRedPaketAPI.logger.error("Update redPacket error", additionalData: ["messageID": messageID], error: error)
            })
    }

    func sendRedPacket(totalAmount: Int64,
                       coverId: Int64?,
                       totalNum: Int32,
                       subject: String,
                       receiveUserIds: [Int64]?,
                       type: RustPB.Basic_V1_HongbaoContent.TypeEnum,
                       channel: RustPB.Basic_V1_Channel,
                       isByteDancer: Bool,
                       financeSdkVersion: String) -> Observable<SendRedPacketResult> {
        var request = SendHongbaoRequest()
        request.totalNum = totalNum
        request.totalAmount = totalAmount
        request.subject = subject
        request.type = type
        if let coverId = coverId {
            request.coverID = coverId
        }
        if let receiveUserIds = receiveUserIds {
            request.receiveUserIds = receiveUserIds
        }
        request.channel = channel
        var deviceInfo = Im_V1_SendHongbaoRequest.DeviceInfo()
        deviceInfo.financeSdkVersion = financeSdkVersion
        request.deviceInfo = deviceInfo

        let objectToJson: (Any) -> String = { obj in
            return (try? JSONSerialization.data(
                withJSONObject: obj,
                options: []
            )).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        }

        // 支持的支付方式
        let payChannels: [String] = ["balance", "quickpay"]
        let payLimitDic = ["limit_pay_channel": payChannels]

        // 收银台以及结果展示方式
        let extsDic = [
            "cashdesk_show_style": 0,
            "result_page_show_style": 0
        ]

        let jsonInfo: [String: Any] = [
            "limit_pay": objectToJson(payLimitDic),
            "exts": objectToJson(extsDic)
        ]
        request.sdkConfig = objectToJson(jsonInfo)

        let result: Observable<SendHongbaoResponse> = client.sendAsyncRequest(request)
        return result.map { SendRedPacketResult(id: $0.id, paramsString: $0.payURL, payURLType: $0.payURLType) }
            .do(onNext: { _ in
                RustRedPaketAPI.logger.info("Send RedPakcet success")
            }, onError: { (error) in
                RustRedPaketAPI.logger.error("Send RedPakcet error", error: error)
            })
    }

    func getPayToken() -> Observable<String> {
        let request = GetPayTokenRequest()
        let result: Observable<GetPayTokenResponse> = client.sendAsyncRequest(request)
        return result.map { $0.payToken }
            .do(onNext: { _ in
                RustRedPaketAPI.logger.info("Get PayToken success")
            }, onError: { (error) in
                RustRedPaketAPI.logger.error("Get PayTokene error", error: error)
            })
    }

    func grabRedPacketRecords(year: Int, cursor: String, count: Int) -> Observable<GrabRedPacketHistoryResult> {
        var request = GetGrabHongbaoRecordRequest()
        request.year = Int32(year)
        request.cursor = cursor
        request.count = Int32(count)
        let result: Observable<GetGrabHongbaoRecordResponse> = client.sendAsyncRequest(request)

        return result.flatMap { (response) -> Observable<GrabRedPacketHistoryResult> in
            return Observable.create { (observer) -> Disposable in
                var errorString: String = ""
                let entity = response.entity
                let records = response.records.compactMap { (record) -> GrabRedPacketRecord? in
                    let isB2C = (record.hongbaoType == .b2CFix || record.hongbaoType == .b2CRandom)
                    let chatterPB = entity.chatters[record.senderID]
                    /// 不是B2C红包的情况下，chatterPB不应该为空
                    if !isB2C, chatterPB == nil {
                        errorString.append("response.entity中缺少Chatter数据 \(record.senderID) /n")
                        return nil
                    }

                    /// 群聊的红包需要展示 红包来自chat.displayName, isP2P & isB2C 不需要
                    if !record.isP2P, !isB2C, entity.chats[record.chatID] == nil {
                        errorString.append("response.entity中缺少Chat数据 \(record.chatID) /n")
                        return nil
                    }

                    var chatter: LarkModel.Chatter?
                    if let pb = chatterPB {
                        chatter = LarkModel.Chatter.transform(pb: pb)
                    }
                    return GrabRedPacketRecord(redPacketID: record.id,
                                               grabAmount: Int(record.grabAmount),
                                               grabTime: Int(record.grabTime),
                                               chatter: chatter,
                                               chat: entity.chats[record.chatID].flatMap { LarkModel.Chat.transform(pb: $0) },
                                               isP2P: record.isP2P,
                                               companyInfo: record.companyInfo,
                                               type: record.hongbaoType)
                }

                if !errorString.isEmpty {
                    observer.onError(RedPacketError(errorReason: errorString))
                } else {
                    let result = GrabRedPacketHistoryResult(year: year,
                                                           totalNumber: Int(response.totalNum),
                                                           totalAmount: Int(response.totalAmount),
                                                           records: records,
                                                           hasMore: response.hasMore_p,
                                                           currentCursor: cursor,
                                                           nextCursor: response.nextCursor)
                    observer.onNext(result)
                    observer.onCompleted()
                }
                return Disposables.create()
            }
        }
        .do(onNext: { _ in
            RustRedPaketAPI.logger.info("Get Grab Record Success")
        }, onError: { (error) in
            RustRedPaketAPI.logger.error("Get Grab Record Error", error: error)
        })
    }

    func sendRedPacketRecords(year: Int, cursor: String, count: Int) -> Observable<SendRedPacketHistoryResult> {
        var request = GetSendHongbaoRecordRequest()
        request.year = Int32(year)
        request.cursor = cursor
        request.count = Int32(count)
        let result: Observable<GetSendHongbaoRecordResponse> = client.sendAsyncRequest(request)
        return result.flatMap { (response) -> Observable<SendRedPacketHistoryResult> in
            return Observable.create { (observer) -> Disposable in
                var errorString: String = ""
                let entity = response.entity
                let records = response.records.compactMap { (record) -> SendRedPacketRecord? in
                    let type: SendRedPacketRecordType
                    if record.isP2P {
                        guard let chatter = entity.chatters[record.receiverID] else {
                            errorString.append("response.entity中缺少Chatter数据 \(record.receiverID) /n")
                            return nil
                        }
                        type = .singChat(chatter: LarkModel.Chatter.transform(pb: chatter))
                    } else {
                        guard let chat = entity.chats[record.chatID] else {
                            errorString.append("response.entity中缺少Chat数据 \(record.chatID) /n")
                            return nil
                        }
                        type = .multiChat(chat: LarkModel.Chat.transform(pb: chat))
                    }
                    return SendRedPacketRecord(redPacketID: record.id,
                                               totalAmount: Int(record.totalAmount),
                                               createTime: Int(record.createTime),
                                               totalNum: Int(record.totalNum),
                                               grabNum: Int(record.grabNum),
                                               isExpired: record.isExpired,
                                               type: type)
                }

                if !errorString.isEmpty {
                    observer.onError(RedPacketError(errorReason: errorString))
                } else {
                    let result = SendRedPacketHistoryResult(year: year,
                                                            totalNumber: Int(response.totalNum),
                                                            totalAmount: Int(response.totalAmount),
                                                            records: records,
                                                            hasMore: response.hasMore_p,
                                                            currentCursor: cursor,
                                                            nextCursor: response.nextCursor)
                    observer.onNext(result)
                    observer.onCompleted()
                }
                return Disposables.create()
            }
        }
        .do(onNext: { _ in
            RustRedPaketAPI.logger.info("Get Send Record Success")
        }, onError: { (error) in
            RustRedPaketAPI.logger.error("Get Send Record Error", error: error)
        })
    }

    func getRedPacketInfoAndReceiveDetail(redPacketID: String, type: RedPacketType) -> Observable<(RedPacketInfo, RedPacketReceiveInfo)> {
        let info = getRedPaketInfo(redPacketID: redPacketID)
        let detail = getRedPacketReceiveDetail(redPacketID: redPacketID, type: type, cursor: "", count: 20)
        return Observable.zip(info, detail)
    }

    func pullHongbaoCoverListRequest() -> Observable<PullHongbaoCoverListResponse> {
        var request = ServerPB.ServerPB_Hongbao_PullHongbaoCoverListRequest()
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullHongbaoCoverList)
    }
}

struct RedPacketError: Error, CustomStringConvertible {
    let description: String
    init(errorReason: String) {
        self.description = errorReason
    }
}
