//
//  FeedSyncDispatchServiceImp.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/8.
//

import Foundation
import LarkMessengerInterface
import RxCocoa
import RustPB
import RxSwift
import LarkModel
import LKCommonsLogging

final class FeedSyncDispatchServiceImp: FeedSyncDispatchService {

    private let dependency: FeedSyncDispatchServiceDependency
    private let disposeBag = DisposeBag()
    private var netStatus: Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent
    private let feedLoadStatus = BehaviorRelay<Bool>(value: false)

    init(dependency: FeedSyncDispatchServiceDependency) {
        self.dependency = dependency

        dependency.pushDynamicNetStatus.subscribe(onNext: { [weak self] (push) in
            self?.netStatus = push.dynamicNetStatus
        }).disposed(by: disposeBag)

        dependency.pushLoadFeedCardsStatus.subscribe(onNext: { [weak self] push in
            guard let self = self, push.feedType == .inbox else { return }
            switch push.status {
            case .start: self.feedLoadStatus.accept(false)
            case .finished: self.feedLoadStatus.accept(true)
            @unknown default: break
            }
            FeedContext.log.info("feedlog. pushLoadFeedCardsStatus: \(push.status)")
        }).disposed(by: disposeBag)
    }

    var dynamicNetStatus: Basic_V1_DynamicNetStatusResponse.NetStatus {
        return netStatus
    }

    var inboxFeedsReadyDriver: Driver<Bool> {
        return feedLoadStatus.asDriver().distinctUntilChanged()
    }

    /// Chat定义在LarkModel中，仍需要引入LarkModel依赖
    var allShortcutChats: [Chat] {
        let ids = dependency.shortcutIds
        if let chatMap = try? dependency.getLocalChats(ids) {
            return ids.compactMap { chatMap[$0] }
        }
        return []
    }

    func fetchAllShortcutChats() -> Observable<[Chat]> {
        let ids = dependency.shortcutIds
        return dependency.fetchLocalChats(ids).map({ chatsMap -> [Chat] in
            return ids.compactMap { (chatId) -> Chat? in
                return chatsMap[chatId]
            }
        })
    }

    // 目前chatType中，小组的chatType全为GROUP 而不是TOPIC_GROUP，
    // 因此获取真正的小组类型和普通群组类型，需要靠ChatMode字段；
    // 用于获取用户当前已见的Top Count个Inbox Feed
    func topInboxChats(by count: Int, chatType: [Chat.ChatMode]?, needChatBox: Bool) -> Observable<[Chat]> {
        let topChatIds = dependency.allFeedCellViewModels.filter { (cellVM) -> Bool in
            let needFilter = (cellVM.feedPreview.basicMeta.feedCardBaseCategory == .inbox &&
                cellVM.feedPreview.basicMeta.feedPreviewPBType == .chat &&
                cellVM.isShow &&
                cellVM.feedPreview.preview.threadData.entityType != .msgThread &&
                !cellVM.feedPreview.preview.chatData.isCrypto
            )
            if let types = chatType {
                return needFilter && types.contains(cellVM.feedPreview.preview.chatData.chatMode)
            }
            // 转发消息需要过滤消息盒子
            if needChatBox == false {
                return needFilter && cellVM.feedPreview.basicMeta.parentCardID.isEmpty
            }
            return needFilter
        }
        .sorted {
            $0.feedPreview.basicMeta.rankTime > $1.feedPreview.basicMeta.rankTime
        }
        .prefix(count)
        .map { $0.feedPreview.id }

        return dependency.fetchLocalChats(topChatIds).map({ chatsMap -> [Chat] in
            return topChatIds.compactMap { (chatId) -> Chat? in
                return chatsMap[chatId]
            }
        })
    }

    func topInboxData(by count: Int,
                      containMsgThread: Bool) -> Observable<(forwardMessages: [ForwardMessage], msgThreadMap: [String: String])> {
        var msgThreadMap: [String: String] = [:]
        let topDataIDTypes = dependency.allFeedCellViewModels.filter {
            return $0.feedPreview.basicMeta.feedCardBaseCategory == .inbox &&
                ($0.feedPreview.basicMeta.feedPreviewPBType == .chat || $0.feedPreview.basicMeta.feedPreviewPBType == .thread) &&
                $0.feedPreview.basicMeta.parentCardID.isEmpty && // 去掉chatBox里的消息
            !(!containMsgThread && $0.feedPreview.preview.threadData.entityType == .msgThread) &&
                $0.isShow
        }
        .sorted {
            $0.feedPreview.basicMeta.rankTime > $1.feedPreview.basicMeta.rankTime
        }
        .prefix(count)
        .map { vm -> (String, Basic_V1_FeedCard.EntityType) in
            if containMsgThread, vm.feedPreview.preview.threadData.entityType == .msgThread {
                msgThreadMap[vm.feedPreview.id] = vm.feedPreview.uiMeta.name
            }
           return (vm.feedPreview.id, vm.feedPreview.basicMeta.feedPreviewPBType)
        }
        let topMessageIDs = topDataIDTypes.filter { $0.1 == .thread }.map { $0.0 }
        return dependency.fetchMessagesMap(ids: topMessageIDs, needTryLocal: false)
            .flatMap({ [weak self] (topMessageMaps) -> Observable<(forwardMessages: [ForwardMessage], msgThreadMap: [String: String])> in
                guard let self = self else { return .just(([], [:])) }
                let topMessageChatIDs = topMessageMaps.values.map { $0.channel.id }
                let topChatIDs = topDataIDTypes.filter { $0.1 == .chat }.map { $0.0 }
                // feed中所有chatID以及message对应的ChatID，不需要保持原顺序
                let topAllChatIDs = Array(Set((topChatIDs + topMessageChatIDs)))
                return self.dependency.fetchChats(by: topAllChatIDs, forceRemote: false)
                    .map { (topAllChatsMap) -> ([ForwardMessage], [String: String]) in
                        var forwardMessages: [ForwardMessage] = []
                        for (id, type) in topDataIDTypes {
                            if type == .chat {
                                if let chat = topAllChatsMap[id] {
                                    forwardMessages.append((chat, nil))
                                }
                            } else {
                                if let message = topMessageMaps[id], let chat = topAllChatsMap[message.channel.id] {
                                    forwardMessages.append((chat, message))
                                }
                            }
                        }
                        return (forwardMessages, msgThreadMap)
                    }
            })
    }

    // 返回feed中的信息（包括Chat与Message)
    func topInboxData(by count: Int) -> Observable<[ForwardMessage]> {
        topInboxData(by: count, containMsgThread: false).map({ return $0.forwardMessages })
    }

    /// 没错，就是这么尴尬，需要兜底服务端逻辑，尽可能找到当前feed列表的全员群chatId
    func currentAllStaffChatId() -> String? {
        return dependency.allFeedCellViewModels.first(where: { $0.feedPreview.preview.chatData.tenantChat })?.feedPreview.id
    }
}
