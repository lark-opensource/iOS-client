//
//  UrgentPushHandler.swift
//  LarkUrgent
//
//  Created by Supeng on 2021/1/26.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LarkContainer
import LKCommonsLogging
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface

protocol UrgentPushHandlerDependency {
    func isBurned(message: Message) -> Bool
}

final class UrgentPushHandlerDependencyImpl: UrgentPushHandlerDependency {
    let messageBurnService: MessageBurnService

    init(messageBurnService: MessageBurnService) {
        self.messageBurnService = messageBurnService
    }

    func isBurned(message: LarkModel.Message) -> Bool {
        return messageBurnService.isBurned(message: message) ?? true
    }
}

final class UrgentPushActionCache {
    fileprivate static var urgents: Set<String> = Set<String>()
    fileprivate static var lock: NSLock = NSLock()

    static func contains(ackId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return urgents.contains(ackId)
    }

    static func insert(ackId: String) {
        lock.lock()
        defer { lock.unlock() }
        urgents.insert(ackId)
    }
}

// 加急失败
final class UrgentFailPushHandler: UserPushHandler {
    override class var compatibleMode: Bool { Urgent.userScopeCompatibleMode }

    static var logger = Logger.log(UrgentFailPushHandler.self, category: "Rust.UrgentFailPushHandler")
    private let disposeBag = DisposeBag()
    private var currentChatterID: String? { try? userResolver.resolve(assert: PassportUserService.self).user.userID }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushUrgentFailed) throws {

        guard let pushCenter = pushCenter else { return }
        Self.logger.info("recieve Im_V1_PushUrgentFailed")
        guard let pushCenter = self.pushCenter, let currentChatterID = currentChatterID else { return }

        guard let msg = RustAggregatorTransformer.transformToMessageModel(
            fromEntity: message.entity,
            currentChatterId: currentChatterID).first?.value else {
                Self.logger.info("recieve Im_V1_PushUrgentFailed: msg is nil")
                return
            }
        guard let chat = RustAggregatorTransformer.transformToChatsMap(fromEntity: message.entity).first?.value else {
            Self.logger.info("recieve Im_V1_PushUrgentFailed: chat is nil")
            return
        }
        Self.logger.info("send PushUrgentFail")
        let info = UrgentFailInfo(message: msg,
                                  urgentId: message.urgentID,
                                  chat: chat,
                                  urgentType: message.urgentType,
                                  failedTip: message.failedMessage)
        pushCenter.post(PushUrgentFail(urgentFailInfo: info))
    }
}

//RustPB.Basic_V1_Entity实体中，message/user/urgent/chat都会带上
final class UrgentPushHandler: UserPushHandler {
    override class var compatibleMode: Bool { Urgent.userScopeCompatibleMode }

    static var logger = Logger.log(UrgentPushHandler.self, category: "Rust.PushHandler")

    private let disposeBag = DisposeBag()

    private var urgentAPI: UrgentAPI? { try? userResolver.resolve(assert: UrgentAPI.self) }
    private var currentChatterID: String? { try? userResolver.resolve(assert: PassportUserService.self).user.userID }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_Entity) throws {

        let dependency: UrgentPushHandlerDependency = UrgentPushHandlerDependencyImpl(messageBurnService: try userResolver.resolve(assert: MessageBurnService.self))

        guard let currentChatterID = currentChatterID, let pushCenter = pushCenter else { return }

        do {
            let urgentInfos = try transformToUrgents(entity: message, currentChatterId: currentChatterID)
            for urgentInfo in urgentInfos {
                Self.logger.info("urgency trace urgency pushHandler recived \(urgentInfo.urgent.id) \(urgentInfo.urgent.messageID) \(urgentInfo.urgent.status.rawValue) \(urgentInfo.urgent.isMuted)")
                switch urgentInfo.urgent.status {
                case .meCreate://我创建的加急
                    handleMyCreate(urgentInfo: urgentInfo)
                case .meAck://我确认了一个别人给我的加急
                    UrgentPushActionCache.insert(ackId: urgentInfo.urgent.id)
                    pushCenter
                        .post(
                            PushUrgentAck(
                                messageId: urgentInfo.urgent.messageID,
                                ackId: urgentInfo.urgent.id
                            )
                        )
                case .urgentMe://有人加急我
                    // 有可能我在其他端已经确认了该加急
                    // 加急状态可能存在更新，不要在这个case里UrgentPushActionCache insert
                    if !UrgentPushActionCache.contains(ackId: urgentInfo.urgent.id) {
                        pushCenter
                            .post(
                                PushUrgent(urgentInfo: urgentInfo)
                            )
                    }
                case .ackMe://有人确认了我发给他的加急
                    //防止反复收到有人确认了我发给他的加急
                    if !UrgentPushActionCache.contains(ackId: urgentInfo.urgent.id) {
                        UrgentPushActionCache.insert(ackId: urgentInfo.urgent.id)
                        handleAckMe(urgentInfo: urgentInfo, dependency: dependency)
                    }
                @unknown default:
                    assert(false, "new value")
                    break
                }
            }
        } catch {
            UrgentPushHandler.logger.error("UrgentPushHandler接收数据转换失败", error: error)
        }
    }

    private func handleMyCreate(urgentInfo: UrgentInfo) {
        guard let urgentAPI = urgentAPI, let pushCenter = pushCenter else { return }
        urgentAPI.fetchMessageUrgent(messageIds: [urgentInfo.urgent.messageID])
            .map { (unreadStatuses) -> UrgentStatus? in
                return unreadStatuses.first
            }.subscribe(onNext: { (unreadStatus) in
                let message = urgentInfo.message
                guard let unreadStatus = unreadStatus else {
                    UrgentPushHandler.logger.error(
                        "HandleMyCreateUrgent:获取unreadStatus异常",
                        additionalData: ["MessageId": message.id])
                    return
                }
                pushCenter
                    .post(
                        PushUrgentStatus(
                            channelId: message.channel.id,
                            messageId: message.id,
                            confirmedChatterIds: unreadStatus.confimedChatterIds,
                            unconfirmedChatterIds: unreadStatus.unconfirmedChatterIds
                        )
                    )
            }, onError: { (error) in
                UrgentPushHandler.logger.error("HandleMyCreateMeUrgent failed.", error: error)
            }).disposed(by: disposeBag)

        pushCenter.post(
            PushUrgent(urgentInfo: urgentInfo)
        )
    }

    private func handleAckMe(urgentInfo: UrgentInfo, dependency: UrgentPushHandlerDependency) {

        if urgentInfo.message.isDeleted || dependency.isBurned(message: urgentInfo.message) {
            UrgentPushHandler.logger.info(
                "handleAckMeUrgent: 消息已经被删除或焚毁，不需要键入会话页")
            return
        }
        guard let urgentAPI = urgentAPI, let pushCenter = pushCenter else { return }
        urgentAPI.fetchMessageUrgent(messageIds: [urgentInfo.urgent.messageID])
            .map { (unreadStatuses) -> UrgentStatus? in
                return unreadStatuses.first
            }.subscribe(onNext: { (unreadStatus) in
                let message = urgentInfo.message
                guard let unreadStatus = unreadStatus else {
                    UrgentPushHandler.logger.error(
                        "handleAckMeUrgent:获取unreadStatus异常",
                        additionalData: ["MessageId": message.id])
                    return
                }
                pushCenter
                    .post(
                        PushUrgentStatus(
                            channelId: message.channel.id,
                            messageId: message.id,
                            confirmedChatterIds: unreadStatus.confimedChatterIds,
                            unconfirmedChatterIds: unreadStatus.unconfirmedChatterIds
                        )
                    )
            }, onError: { (error) in
                UrgentPushHandler.logger.error(
                    "HandleAckMeUrgent failed.",
                    additionalData: ["MessageId": urgentInfo.urgent.messageID],
                    error: error)
            }).disposed(by: disposeBag)
    }
}

func transformToUrgents(
    entity: RustPB.Basic_V1_Entity,
    currentChatterId: String
    ) throws -> [UrgentInfo] {
    let messages = RustAggregatorTransformer.transformToMessageModel(
        fromEntity: entity,
        currentChatterId: currentChatterId)
    let chats = RustAggregatorTransformer.transformToChatsMap(fromEntity: entity)
    let urgentInfos = entity.urgents.compactMap { (_, urgent) -> UrgentInfo? in
        if let message = messages[urgent.messageID] {
            if let chat = chats[message.channel.id] {
                return UrgentInfo(message: message, chat: chat, urgent: urgent)
            } else {
                UrgentPushHandler.logger.error("push miss urgent necessary entity chat \(urgent.id) \(message.channel.id)")
            }
        } else {
            UrgentPushHandler.logger.error("push miss urgent necessary entity message \(urgent.id) \(urgent.messageID)")
        }
        return nil
    }
    return urgentInfos
}
