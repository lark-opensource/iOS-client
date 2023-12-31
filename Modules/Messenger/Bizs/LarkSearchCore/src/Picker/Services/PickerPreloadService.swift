//
//  PickerPreloadService.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/16.
//

import Foundation
import RxSwift
import LarkSDKInterface
import LarkModel
import LarkMessengerInterface
import LarkContainer

public class PickerPreloadService: ForwardItemDataConvertable, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var serviceContainer: PickerServiceContainer?
    var didFinishPreloadHandler: (([Option]) -> Void)?

    let logger = PickerLogger.shared

    deinit {
        logger.info(module: PickerLogger.Module.preload, event: "deinit")
    }

    private let disposeBag = DisposeBag()
    private let tenantId: String
    init(resolver: UserResolver, tenantId: String) {
        self.userResolver = resolver
        self.tenantId = tenantId
    }

    func preload(selects: [Option]) {
        let selectInfos = selects.map { ($0.optionIdentifier.id, $0.optionIdentifier.type) }
        let uniqueSelects = selects.reduce(into: [Option]()) { partialResult, option in
            if !partialResult.contains(where: {
                $0.optionIdentifier.id == option.optionIdentifier.id && $0.optionIdentifier.type == option.optionIdentifier.type
            }) {
                partialResult.append(option)
            }
        }
        logger.info(module: PickerLogger.Module.preload, event: "start preload", parameters: "\(selectInfos), unique: \(uniqueSelects.map { $0.optionIdentifier.id })")

        let chatSelects = selects.filter { $0.optionIdentifier.type == "chat" }
        let chatterSelects = selects.filter { $0.optionIdentifier.type == "chatter" }
        let chatParams: [String: String?] = Dictionary(uniqueKeysWithValues: chatSelects.map {
            ($0.optionIdentifier.id, $0.optionIdentifier.emailId)
        })
        let chatterParams: [String: String?] = Dictionary(uniqueKeysWithValues: chatterSelects.map {
            ($0.optionIdentifier.id, $0.optionIdentifier.emailId)
        })

        pre(chatIds: chatSelects.map({ $0.optionIdentifier.id }), chatterIds: chatterSelects.map({ $0.optionIdentifier.id }))
            .do(onNext: { [weak self] in
                let param = $0.map { "id: \($0.id), type: \($0.type)" }
                self?.logger.info(module: PickerLogger.Module.preload, event: "preload success", parameters: "items: \(param)")
            })
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (items: [ForwardItem]) in
                // 将加载后的Items按照传入的id数组排序
                let items: [Option] = uniqueSelects
                    .map { $0.optionIdentifier.id }
                    .compactMap { (id: String) in
                        // 用户
                        if var item = items.first(where: {
                            $0.type == .user && $0.id == id
                        }) {
                            if let enterpriseMailAddress = chatterParams[id] {
                                item.enterpriseMailAddress = enterpriseMailAddress
                            }
                            return item
                        }
                        // 单聊相关的用户
                        if var item = items.first(where: {
                            $0.type == .user && $0.chatId == id
                        }) {
                            if let enterpriseMailAddress = chatParams[id] {
                                item.enterpriseMailAddress = enterpriseMailAddress
                            }
                            return item
                        }
                        // 群组
                        if var item = items.first(where: {
                            $0.type == .chat && $0.id == id
                        }) {
                            if let enterpriseMailAddress = chatParams[id] {
                                item.enterpriseMailAddress = enterpriseMailAddress
                            }
                            return item
                        }
                        let matchTypes = ["doc", "wiki", "workspace", "mailUser"]
                        if let item = selects.first(where: {
                            let identifier = $0.optionIdentifier
                            return matchTypes.contains(identifier.type) && identifier.id == id
                        }) { return item }
                        return nil
                    }
                self?.logger.info(module: PickerLogger.Module.preload, event: "preload after filter", parameters: "items: \(items.map { $0.optionIdentifier.id })")
                self?.didFinishPreloadHandler?(items)
            }.disposed(by: self.disposeBag)
    }

    func preloadChats(by ids: [String]) -> Observable<[Chat]> {
        return serviceContainer?.getChats(by: ids)
            .do(onNext: { [weak self] in
                self?.logger.info(module: PickerLogger.Module.preload, event: "load chats success", parameters: "\($0.keys)")
            }, onError: { [weak self] in
                self?.logger.error(module: PickerLogger.Module.preload, event: "load chat failed", parameters: $0.localizedDescription)
            })
            .map { map in
                return ids.compactMap { map[$0] }
            } ?? .never()
    }

    func preloadChatters(by ids: [String]) -> Observable<[Chatter]> {
        return serviceContainer?.getChatters(ids: ids)
            .do(onNext: { [weak self] in
                self?.logger.info(module: PickerLogger.Module.preload, event: "load chatters success", parameters: "\($0.keys)")
            }, onError: { [weak self] in
                self?.logger.error(module: PickerLogger.Module.preload, event: "load chatter failed", parameters: $0.localizedDescription)
            })
            .map { chats in
                return ids.compactMap { chats[$0] }
            } ?? .never()
    }

    func pre(chatIds: [String], chatterIds: [String]) -> Observable<[ForwardItem]> {
        let ob = Observable.just([ForwardItem]())
            .flatMap { [weak self] in
                self?.preloadChats(chatIds: chatIds, items: $0) ?? .never()
            }
            .flatMap { [weak self] (items: [ForwardItem], idMap: [String: String]) -> Observable<[ForwardItem]> in
                // 传入chat中存在的单聊id map
                var map: [String: String] = idMap
                // 传入的chat中存在单聊, 且该单聊同时有传入用户id, 则进行去重, 仅加载用户即可
                chatterIds.forEach {
                    map.removeValue(forKey: $0)
                }
                self?.logger.info(module: PickerLogger.Module.preload, event: "ready load chatters", parameters: "chatters: \(chatterIds), map: \(map)")
                return self?.preloadChatters(chatterIds: chatterIds, idMap: map, items: items) ?? .never()
            }
        return ob
    }

    func preloadChats(chatIds: [String], items: [ForwardItem]) -> Observable<([ForwardItem], [String: String])> {
        var result = items
        var chatterIdMap = [String: String]()
        let tenantId = self.tenantId
        return preloadChats(by: chatIds)
            .map { [weak self] chats in
                for chat in chats {
                    if chat.type == .group {
                        // 群聊直接添加
                        let item = ForwardItemDataConverter.convert(chat: chat, currentTeanantId: tenantId)
                        result.append(item)
                    } else if chat.type == .p2P && !chat.chatterId.isEmpty {
                        // 单聊需要转换为用户支持
                        chatterIdMap[chat.chatterId] = chat.id
                    } else {
                        self?.logger.error(module: PickerLogger.Module.preload, event: "chat with other type", parameters: "id: \(chat.id), type: \(chat.type)")
                    }
                }
                return (result, chatterIdMap)
            }
    }

    /// 加载
    /// - Parameters:
    ///   - chatterIds: 传入的用户id数组
    ///   - idMap: chatter id 和 chat id的映射表
    func preloadChatters(chatterIds: [String], idMap: [String: String], items: [ForwardItem]) -> Observable<[ForwardItem]> {
        var result = items
        let chatterIds = Array(idMap.keys) + chatterIds
        let tenantId = self.tenantId
        return preloadChatters(by: chatterIds)
            // 映射到Item
            .map { chatters in
                chatters.map {
                    let chatId = idMap[$0.id]
                    return ForwardItemDataConverter.convert(chatter: $0, currentTeanantId: tenantId, chatId: chatId)
                }
            }
            // 叠加之前的items
            .map {
                result.append(contentsOf: $0)
                return result
            }
    }
}
