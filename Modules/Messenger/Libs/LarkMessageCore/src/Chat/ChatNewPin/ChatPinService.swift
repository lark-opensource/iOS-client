//
//  ChatPinService.swift
//  LarkChat
//
//  Created by Zigeng on 2023/7/20.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer
import TangramService
import LarkMessageBase
import LarkSDKInterface
import EEAtomic
import RxSwift
import LKCommonsLogging

public struct PinInfo: Hashable, Equatable {
    let messageId: String
    let pinId: Int64
    var pinChatter: Chatter

    // 服务端如果下发脏数据,需要进行去重操作
    public func hash(into hasher: inout Hasher) {
        hasher.combine(messageId)
    }
    public static func == (lhs: PinInfo, rhs: PinInfo) -> Bool {
        return lhs.messageId == rhs.messageId
    }
}

public final class ChatPinPageService: ChatPinDataSource, PageService {

    private let logger = Logger.log(ChatPinPageService.self, category: "Module.Chat")

    private weak var pageContext: PageContext?
    private var disposeBag = DisposeBag()
    private var currentVersion: Int64?
    private let chatID: String

    public init(chatID: String, pageContext: PageContext?) {
        self.chatID = chatID
        self.pageContext = pageContext
    }

    @AtomicObject var pinDictionary = [String: PinInfo]()
    @AtomicObject var chatterDictionary = [String: Set<String>]()
    private(set) var announcementPinID: Int64?

    private static func generatePinDictionary(_ data: Im_V1_GetChatPinInfoResponse, _ chatID: String) -> [String: PinInfo] {
        let pinInfoSet = Set(data.infos.compactMap { pb -> PinInfo? in
            guard pb.type == .messagePin else { return nil }
            guard let chatter = try? Chatter.transformChatChatter(entity: data.entity, chatID: chatID, id: String(pb.chatterID)) else { return nil }
            let messageId = String(pb.messageID)
            return PinInfo(messageId: messageId, pinId: pb.pinID, pinChatter: chatter)
        })
        return Dictionary(uniqueKeysWithValues: pinInfoSet.map { ($0.messageId, $0) })
    }

    private static func generatePinDictionary(_ data: Im_V1_PushChatPinInfo, _ chatID: String) -> [String: PinInfo] {
        let pinInfoSet = Set(data.infos.compactMap { pb -> PinInfo? in
            guard pb.type == .messagePin else { return nil }
            guard let chatter = try? Chatter.transformChatChatter(entity: data.entity, chatID: chatID, id: String(pb.chatterID)) else { return nil }
            let messageId = String(pb.messageID)
            return PinInfo(messageId: messageId, pinId: pb.pinID, pinChatter: chatter)
        })
        return Dictionary(uniqueKeysWithValues: pinInfoSet.map { ($0.messageId, $0) })
    }

    private func fetchPins() {
        guard let chatAPI = try? pageContext?.userResolver.resolve(assert: ChatAPI.self), let chatID = Int64(chatID) else { return }
        chatAPI.getChatPinInfo(chatID: chatID).subscribe(onNext: { [weak self] data in
            guard var self = self else { return }
            let newVersion = data.version
            let announcementPinID = data.infos.first(where: { $0.type == .announcementPin })?.pinID
            self.logger.info("""
                chatPinTrace handle ChatPinMessageIDsInfo Response
                chatID: \(chatID) newVersion: \(newVersion)
                currentVersion: \(self.currentVersion ?? -1)
                announcementPinID: \(announcementPinID ?? -1)
            """)
            guard self.checkNeedUpdate(newVersion) else { return }

            let messageIDs = self.update(Self.generatePinDictionary(data, self.chatID))
            self.pageContext?.reloadRows(by: messageIDs) { (message) -> Message? in
                return message
            }
            self.announcementPinID = announcementPinID
        }).disposed(by: disposeBag)
    }

    private func startObserve() {
        guard let pushCenter = try? pageContext?.userResolver.userPushCenter else { return }
        pushCenter.observable(for: PushChatPinInfo.self)
            .filter { [weak self] in String($0.push.chatID) == self?.chatID }
            .subscribe(onNext: { [weak self] data in
                guard var self = self else { return }
                let newVersion = data.push.version
                let announcementPinID = data.push.infos.first(where: { $0.type == .announcementPin })?.pinID
                self.logger.info("""
                    chatPinTrace handle ChatPinMessageIDsInfo push
                    chatID: \(self.chatID) newVersion: \(newVersion)
                    currentVersion: \(self.currentVersion ?? -1)
                    announcementPinID: \(announcementPinID ?? -1)
                """)
                guard self.checkNeedUpdate(newVersion) else { return }

                let messageIDs = self.update(Self.generatePinDictionary(data.push, self.chatID))
                self.pageContext?.reloadRows(by: messageIDs) { (message) -> Message? in
                    return message
                }
                self.announcementPinID = announcementPinID
            }).disposed(by: self.disposeBag)
    }

    private func checkNeedUpdate(_ newVersion: Int64) -> Bool {
        if let currentVersion = self.currentVersion, currentVersion >= newVersion { return false }
        self.currentVersion = newVersion
        return true
    }

    public func beforeFetchFirstScreenMessages() {
        if pageContext?.userResolver.fg.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) ?? false {
            fetchPins()
            startObserve()
        }
    }

    public func getPinInfo(messageId: String) -> PinInfo? {
        return pinDictionary[messageId]
    }
}

protocol ChatPinDataSource {
    // Pin列表 MessageId -> Chatter
    var pinDictionary: [String: PinInfo] { get set }
    // PinChatter 列表 ChatterId -> Set<MessageId>
    var chatterDictionary: [String: Set<String>] { get set }
    // Pin列表MessageId更新, 返回需要更新的MessageId数组
    mutating func update(_ newPinDictionary: [String: PinInfo]) -> [String]
    // Chatter更新, 若成功更新, 返回需要更新的MessageId数组
    mutating func updateChatter(_ chatter: Chatter) -> [String]?
}

extension ChatPinDataSource {
    private mutating func chatterDicPop(chatterId: String, messageId: String) {
        chatterDictionary[chatterId]?.remove(messageId)
        if chatterDictionary[chatterId]?.isEmpty ?? false {
            chatterDictionary.removeValue(forKey: chatterId)
        }
    }

    // 更新当前的Pin列表
    mutating func update(_ newPinDictionary: [String: PinInfo]) -> [String] {
        var needUpdateMessageIds: [String] = []
        // 取pinDictionary和newPinDictionary的差集, 判断被取消Pin的消息IDs
        let diffKeys = Set(pinDictionary.keys).subtracting(Set(newPinDictionary.keys))
        diffKeys.forEach { messageId in
            if let oldPinInfo = pinDictionary.removeValue(forKey: messageId) {
                chatterDicPop(chatterId: oldPinInfo.pinChatter.id, messageId: messageId)
            }
            needUpdateMessageIds.append(messageId)
        }
        // 遍历新的Pin列表
        newPinDictionary.forEach { (messageId, pinInfo) in
            // Chatter ID 不一致(Pin操作的用户改变为其他用户), Chatter列表推出命中的MessageId
            if let currentChatter = pinDictionary[messageId]?.pinChatter, currentChatter.id != pinInfo.pinChatter.id {
                chatterDicPop(chatterId: currentChatter.id, messageId: messageId)
            }
            pinDictionary.updateValue(pinInfo, forKey: messageId)
            if chatterDictionary[pinInfo.pinChatter.id] == nil {
                chatterDictionary[pinInfo.pinChatter.id] = []
            }
            chatterDictionary[pinInfo.pinChatter.id]?.insert(messageId)
            needUpdateMessageIds.append(messageId)
        }
        return needUpdateMessageIds
    }

    // 收到Chatter推送,进行Pin信息的Chatter更新
    mutating func updateChatter(_ chatter: Chatter) -> [String]? {
        guard let needUpdateMessageIds = chatterDictionary[chatter.id] else { return nil }
        needUpdateMessageIds.forEach { messageId in
            pinDictionary[messageId]?.pinChatter = chatter
        }
        return Array(needUpdateMessageIds)
    }
}
