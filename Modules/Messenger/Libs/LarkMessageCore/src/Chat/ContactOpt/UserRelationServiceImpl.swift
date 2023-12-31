//
//  UserRelationServiceImpl.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2020/10/10.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import LarkSDKInterface
import LKCommonsLogging
import RxSwift
import RxRelay
import ThreadSafeDataStructure
import LarkSetting
import LarkContainer

// 管理联系人控件的服务
// 联系人二期需求使用
final class ContactControlServiceImpl: ContactControlService {

    private let userRelationService: UserRelationService

    init(userRelationService: UserRelationService) {
        self.userRelationService = userRelationService
    }

    // 获取banner模型的序列
    func getExternalBannerModelObservable(chat: Chat) -> Observable<ExternalBannerModel>? {
        guard chat.type == .p2P, chat.isCrossTenant else { return nil }
        return self.userRelationService.getAndStashUserRelationModelBehaviorRelay(chat: chat)?
            .asObservable()
            .filter({ (model) -> Bool in
                if let userId = chat.chatter?.id {
                    return model.userId == userId
                }
                return true
            })
            .map({ (model) -> ExternalBannerModel in
                let avatarKey = chat.chatter?.avatarKey ?? ""
                return ExternalBannerModel(userRelationModel: model, avatarKey: avatarKey)
            })
    }

    // 获取是否展示unblock按钮
    func getIsShowUnBlock(chat: Chat) -> Bool? {
        guard chat.type == .p2P, chat.isCrossTenant else { return nil }
        guard let value = self.userRelationService.getAndStashBlockStatusBehaviorRelay(chat: chat)?.value else {
            return nil
        }
        return value.isHasBlock
    }

    // 获取是否展示unblock按钮的序列
    func getIsShowUnBlockObservable(chat: Chat) -> Observable<Bool>? {
        guard chat.type == .p2P, chat.isCrossTenant else { return nil }
        return self.userRelationService.getAndStashBlockStatusBehaviorRelay(chat: chat)?
            .asObservable()
            .filter({ (model) -> Bool in
                if let userId = chat.chatter?.id {
                    return userId == model.userId
                }
                return true
            })
            .map { (model) -> Bool in
                return model.isHasBlock
            }
    }

    // 获取是否展示block/unblock状态下的视图变化
    func getIsShowBlockStatusControlChange(chat: Chat) -> Bool? {
        guard chat.type == .p2P, chat.isCrossTenant else { return nil }
        guard let value = self.userRelationService.getAndStashBlockStatusBehaviorRelay(chat: chat)?.value else {
            return nil
        }
        return value.isHasBlock || value.isHasBeBlock
    }

    // 获取是否能打开红包
    func getCanOpenRedPacketPage(chat: Chat) -> Bool? {
        guard chat.type == .p2P, chat.isCrossTenant else { return nil }
        guard let value = self.userRelationService.getAndStashUserRelationModelBehaviorRelay(chat: chat)?.value else {
            return nil
        }
        return value.isFriend
    }
}

// 管理联系人关系的服务
// 联系人二期需求使用
final class UserRelationServiceImpl: UserRelationService {
    private let externalContactsAPI: ExternalContactsAPI
    private let chatterAPI: ChatterAPI

    private static let logger = Logger.log(UserRelationServiceImpl.self, category: "Module.IM.LarkMessageCore")

    // 这里通过version来标示请求，保证时序
    private var version: Int = 0

    private let pushContactApplicationBannerAffectEvent: Observable<PushContactApplicationBannerAffectEvent>

    // userId -> userRelationBehaviorRelay的字典
    private var userRelationBehaviorRelayDic: SafeDictionary<String, BehaviorRelay<UserRelationModel>> = [:] + .readWriteLock

    // userId -> userRelationBehaviorRelay的生命周期的字典
    private let userRelationDisposeDic: SafeDictionary<String, Disposable> = [:] + .readWriteLock

    // userId -> 屏蔽/被屏蔽序列 的字典
    private var blockStatusBehaviorRelayDic: SafeDictionary<String, BehaviorRelay<BlockStatusModel>> = [:] + .readWriteLock

    // userId -> blockBehaviorRelay的生命周期的字典
    private let blockStatusDisposeDic: SafeDictionary<String, Disposable> = [:] + .readWriteLock

    init(externalContactsAPI: ExternalContactsAPI,
         chatterAPI: ChatterAPI,
         pushContactApplicationBannerAffectEvent: Observable<PushContactApplicationBannerAffectEvent>) {
        self.externalContactsAPI = externalContactsAPI
        self.chatterAPI = chatterAPI
        self.pushContactApplicationBannerAffectEvent = pushContactApplicationBannerAffectEvent
    }

    private func enableGetRelationShip(chat: Chat) -> Bool {
        guard chat.type == .p2P,
              chat.isCrossTenant,
              chat.chatter != nil,
              chat.chatter?.type == .user else { return false }
        return true
    }

    // 移除外部联系人关系的序列
    @discardableResult
    public func removeUserRelationBehaviorRelay(userId: String) -> Bool {
        guard !userId.isEmpty else {
            Self.logger.info("removeUserRelationBehaviorRelay, userId is Empty")
            return false
        }
        self.userRelationBehaviorRelayDic.removeValue(forKey: userId)
        self.userRelationDisposeDic[userId]?.dispose()
        self.userRelationDisposeDic.removeValue(forKey: userId)
        return true
    }

    // 移除外部联系人block关系的序列
    @discardableResult
    public func removeBlockStatusBehaviorRelay(userId: String) -> Bool {
        guard !userId.isEmpty else {
            Self.logger.info("removeBlockStatusBehaviorRelay, userId is Empty")
            return false
        }
        self.blockStatusBehaviorRelayDic.removeValue(forKey: userId)
        self.blockStatusDisposeDic[userId]?.dispose()
        self.blockStatusDisposeDic.removeValue(forKey: userId)
        return true
    }

    // 获取block的状态
    public func getAndStashBlockStatusBehaviorRelay(chat: Chat) -> BehaviorRelay<BlockStatusModel>? {
        guard enableGetRelationShip(chat: chat) else { return nil }

        let userId = chat.chatterId
        let relay = BehaviorRelay<BlockStatusModel>(value: BlockStatusModel())
        // 如果缓存有直接返回
        if let relay = self.blockStatusBehaviorRelayDic[userId] {
            return relay
        }
        self.blockStatusBehaviorRelayDic[userId] = relay
        let localStatusObsevable = self.chatterAPI.fetchUserBlockStatusRequest(userId: userId, strategy: .local)
            .map { (res) -> BlockStatusModel in
                return BlockStatusModel(userId: userId, isHasBlock: res.blockStatus, isHasBeBlock: res.beBlockStatus)
            }
        let serverObservable: Observable<BlockStatusModel> = getAndStashUserRelationModelBehaviorRelay(chat: chat)?
            .asObservable()
            .map { (res) -> BlockStatusModel in
                return BlockStatusModel(userId: userId, isHasBlock: res.isHasBlock, isHasBeBlock: res.isHasBeBlock)
            } ?? .empty()
        let dispose = Observable.merge([localStatusObsevable, serverObservable])
            .subscribe(onNext: { (model) in
                relay.accept(model)
            })
        self.blockStatusDisposeDic[userId] = dispose

        return relay
    }

    // 获取外部联系人关系的序列
    public func getAndStashUserRelationModelBehaviorRelay(chat: Chat) -> BehaviorRelay<UserRelationModel>? {
        guard enableGetRelationShip(chat: chat) else { return nil }

        let userId = chat.chatterId
        // 如果缓存有直接返回
        if let relay = self.userRelationBehaviorRelayDic[userId] {
            return relay
        }
        let userRelationBehaviorRelay = BehaviorRelay<UserRelationModel>(value: UserRelationModel())
        self.userRelationBehaviorRelayDic[userId] = userRelationBehaviorRelay
        let chatId = chat.id
        // 通过ownerId来判断是否是发起方
        // 老版本会存在老的不是好友的外部联系人，chat的ownerId为空，这里无法判断，默认作为接收方
        let isOwner = chat.p2POwnerId.isEmpty ? false : chat.p2POwnerId != userId

        // 生成push banner model的可监听序列
        let pushObservable = self.pushContactApplicationBannerAffectEvent
            .debounce(.microseconds(500), scheduler: MainScheduler.instance)
            .flatMap { [weak self] (res) -> Observable<(UserRelationModel, Int)> in
                guard let `self` = self, res.targetUserIds.contains(userId) else { return .empty() }
                self.version += 1
                let currentVersion = self.version
                // 只要当前chat的联系人信息变更就去重新拉取联系人关系
                return self.externalContactsAPI.fetchUserRelationRequest(userId: userId)
                    .flatMap { (res) -> Observable<(UserRelationModel, Int)> in
                        let model = UserRelationModel(userId: userId,
                                                      isFriend: res.isFriend,
                                                      isOwner: isOwner,
                                                      isHasBlock: res.hasBlock_p,
                                                      isHasBeBlock: res.hasBeBlock_p,
                                                      isHasApply: res.hasApply_p,
                                                      isRecieveApply: res.hasBeApplied_p,
                                                      isAssociatedOrignazationMember: res.inCollaboration,
                                                      beAppliedReason: res.beAppliedReason)
                        return .just((model, currentVersion))
                    }
            }
            .flatMap({ [weak self] (model, version) -> Observable<UserRelationModel> in
                // 如果两次请求同时发，这里通过version标示，忽略前一个的结果
                if version == self?.version {
                    return .just(model)
                }
                return .empty()
            }).do(onError: { error in
                Self.logger.error("pushContactApplicationBannerAffectEvent error, error = \(error)")
            })

        // 根据接口获取pull userRelation的可监听序列
        let fetchObservable = externalContactsAPI.fetchUserRelationRequest(userId: userId)
            .map { (res) -> UserRelationModel in
                let model = UserRelationModel(userId: userId,
                                              isFriend: res.isFriend,
                                              isOwner: isOwner,
                                              isHasBlock: res.hasBlock_p,
                                              isHasApply: res.hasApply_p,
                                              isRecieveApply: res.hasBeApplied_p,
                                              isCtrlAddContact: res.beCtrlAddContact,
                                              isAssociatedOrignazationMember: res.inCollaboration,
                                              beAppliedReason: res.beAppliedReason)
                return model
            }.do(onError: { error in
                Self.logger.error("fetchUserRelationRequest failed",
                                  additionalData: ["userIds": userId, "chatId": chatId],
                                  error: error)
            })

        // merge pull和push外部联系人关系的序列
        let dispose = Observable.merge([pushObservable, fetchObservable])
            .distinctUntilChanged()
            .subscribe(onNext: { (model) in
                userRelationBehaviorRelay.accept(model)
            })
        // 管理生命周期
        self.userRelationDisposeDic[userId] = dispose

        return userRelationBehaviorRelay
    }
}
