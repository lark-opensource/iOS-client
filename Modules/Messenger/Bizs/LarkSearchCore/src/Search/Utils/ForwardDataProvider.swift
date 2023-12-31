//
//  ForwardDataProvider.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/9/21.
//

import Foundation
import RxSwift
import LarkMessengerInterface
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer
import RustPB
import LarkModel
import LarkFeatureGating

struct RecentForwardFilterParameter: RecentForwardFilterParameterType {
    var includeGroupChat: Bool = true
    var includeP2PChat: Bool = true
    var includeThreadChat: Bool = true
    var includeOuterChat: Bool = true
    var includeSelf: Bool = true
    var includeMyAi: Bool = true
}

final class ForwardDataProvider: ForwardItemDataConvertable {
    private var searchAPI: SearchAPI?
    private var contactAPI: ContactAPI?
    private var userService: PassportUserService?
    let logger = Logger.log("ForwardDataProvider")
    static let loggerKeyword = "Forward.DataProvider.<IOS_RECENT_VISIT>:"

    init(searchAPI: SearchAPI?, contactAPI: ContactAPI?, userService: PassportUserService?) {
        self.searchAPI = searchAPI
        self.contactAPI = contactAPI
        self.userService = userService
    }

    func loadForwardItems(isFromLocal: Bool, includeConfigs: IncludeConfigs?, strategy: Basic_V1_SyncDataStrategy, limit: Int32) -> Observable<[ForwardItem]> {
        self.logger.info("\(Self.loggerKeyword) load from forward list request isFromLocal: \(isFromLocal)")
        guard let contactAPI else { return .never() }
        if isFromLocal {
            return contactAPI.getForwardList()
                .do(onNext: { [weak self] in
                    self?.logger.info("\(Self.loggerKeyword) load forward list count: \($0.previews.count)")
                }, onError: { [weak self] in
                    self?.logger.error("\(Self.loggerKeyword) load forward list error: \($0)")
                })
                .map { [weak self] res -> [ForwardItem] in
                    guard let self = self else { return [] }
                    let items = self.convert(previews: res.previews, userService: self.userService)
                        .map {
                            var i = $0; i.enableThreadMiniIcon = false; return i
                        }
                    return items
                }
        }
        self.logIncludeCongfigs(includeConfigs)
        let startTime = CACurrentMediaTime()
        return contactAPI.getRemoteSyncForwardList(includeConfigs: self.convertIncludeConfigs(includeConfigs: includeConfigs), strategy: strategy, limit: limit)
            .do(onNext: { [weak self] in
                self?.logger.info("\(Self.loggerKeyword) load forward list count: \($0.previews.count) reason: \($0.canNotSelectChatterMap) costTime: \(CACurrentMediaTime() - startTime) strategy: \(strategy)")
            }, onError: { [weak self] in
                self?.logger.error("\(Self.loggerKeyword) load forward list error: \($0)")
            })
            .do(onNext: { [weak self] in
                let res = $0.previews.filter { $0.chatData.isUserCountVisible == false }
                    .map { return $0.feedID }
                self?.logger.info("\(Self.loggerKeyword) hide chat user count ids: \(res)")
            })
            .map { [weak self] res -> [ForwardItem] in
                guard let self = self else { return [] }
                let canNotSelectChatterMap = res.canNotSelectChatterMap
                let items = self.convert(previews: res.previews, userService: self.userService)
                    .map {
                        var i = $0
                        i.enableThreadMiniIcon = false
                        if let reason = canNotSelectChatterMap[i.id] {
                            i.deniedReasons = [reason]
                        }
                        return i
                    }
                return items
            }
    }

    func loadRecentForwardItem(filter paramter: RecentForwardFilterParameter, strategy: Basic_V1_SyncDataStrategy) -> Observable<[ForwardItem]> {
        self.logger.info("\(Self.loggerKeyword) recent forward include parameter: \(paramter)")
        let startTime = CACurrentMediaTime()
        guard let searchAPI else { return .just([]) }
        return searchAPI.fetchRecentForwardItems(includeGroupChat: paramter.includeGroupChat,
                                                 includeP2PChat: paramter.includeP2PChat,
                                                 includeThreadChat: paramter.includeThreadChat,
                                                 includeOuterChat: paramter.includeOuterChat,
                                                 includeSelf: paramter.includeSelf,
                                                 includeMyAi: paramter.includeMyAi,
                                                 strategy: strategy)
        .map {
            return $0.filter {
                // 根据入参决定是否本地过滤外部单聊/群聊
                if paramter.includeOuterChat { return true }
                if $0.isCrossTenant { return false }
                return true
            }.map {
                let isChat = $0.chatterID.isEmpty
                let isPrivate = $0.extTypes.contains(.encryptedType)
                let isThread = $0.extTypes.contains(.threadType)
                let isMyAi = $0.extTypes.contains(.p2PMyAiType)
                var item = ForwardItem(avatarKey: $0.avatarKey,
                                       name: $0.name,
                                       subtitle: "", description: "",
                                       descriptionType: .onDefault, localizeName: "",
                                       id: isChat ? $0.chatID : $0.chatterID,
                                       chatId: $0.chatID,
                                       type: isMyAi ? .myAi : (isChat ? .chat : .user),
                                       isCrossTenant: $0.isCrossTenant,
                                       isCrossWithKa: false,
                                       isCrypto: false,
                                       isThread: isThread,
                                       isPrivate: isPrivate,
                                       doNotDisturbEndTime: 0,
                                       hasInvitePermission: true,
                                       userTypeObservable: nil,
                                       enableThreadMiniIcon: false,
                                       isOfficialOncall: false,
                                       tags: [])
                item.source = .recentForward
                if isPrivate {
                    item.id = $0.chatID
                    item.type = .chat
                }
                item.enableThreadMiniIcon = false
                return item
            }
        }
        .do(onNext: { [weak self] in
            self?.logger.info("\(Self.loggerKeyword) load recent forward list count \($0.count), costTime: \(CACurrentMediaTime() - startTime)")
        }, onError: {
            self.logger.error("\(Self.loggerKeyword) Forward load recent forward list error: \($0)")
        })
        .catchErrorJustReturn([])
    }

    func logIncludeCongfigs(_ includeConfigs: IncludeConfigs?) {
        guard let includeConfigs = includeConfigs else {
            self.logger.info("\(Self.loggerKeyword) includeConfigs is nil")
            return
        }
        self.logger.info("\(Self.loggerKeyword) remote sync forwad list includeConfigs count:\(includeConfigs.count)")
        var logStr = ""
        for includeConfig in includeConfigs {
            if let userConfig = includeConfig as? ForwardUserEntityConfig {
                logStr += userConfig.description + "; "
            }
            if let groupChatConfig = includeConfig as? ForwardGroupChatEntityConfig {
                logStr += groupChatConfig.description + "; "
            }
            if let botConfig = includeConfig as? ForwardBotEntityConfig {
                logStr += botConfig.description + "; "
            }
            if let threadConfig = includeConfig as? ForwardThreadEntityConfig {
                logStr += threadConfig.description
            }
        }
        self.logger.info("\(Self.loggerKeyword) includeConfigs: \(logStr)")
    }
}
