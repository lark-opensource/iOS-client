//
//  ExtensionAssembly.swift
//  LarkAccount
//
//  Created by quyiming on 2020/9/9.
//

import Foundation
import Swinject
import EENavigator
import LarkAccountInterface
import LarkRustClient
import LarkContainer
import LarkDebugExtensionPoint
import LKCommonsLogging
import RxSwift
import LarkModel
import RustPB
import ThreadSafeDataStructure
import LarkEnv
import LarkSDKInterface

// MARK: ChatterManager
final class ChatterManager: ChatterManagerProtocol {
    static let logger = Logger.log(ChatterManager.self, category: "SuiteLogin.ChatterManager")
    let disposeBag = DisposeBag()
    @Provider var rustClient: RustService
    @Provider var accountService: AccountService
    private var chatterKey = "Cached.Account.Key"
    lazy private var _innerChatter: SafeAtomic<Chatter> = {
        var chatter = Chatter.placeholderChatter()

        guard let cachedData = UserDefaults.standard.data(forKey: self.chatterKey) else {
            Self.logger.info("Fail to load chatter from UserDefaults")
            return chatter + .readWriteLock
        }
        do {
            let pbChatter = try Chatter.PBModel(serializedData: cachedData)
            chatter = Chatter.transform(pb: pbChatter)
        } catch {
            Self.logger.error("Serialized data failed", error: error)
        }
        return chatter + .readWriteLock
    }()
    private let currentChatterPubSub = BehaviorSubject<Chatter?>(value: nil)
    var currentChatterObservable: Observable<Chatter> {
        return currentChatterPubSub
            .filter { $0 != nil }
            .map { $0! }
            .asDriver(onErrorDriveWith: .empty())
            .asObservable()
    }
    var currentChatter: LarkModel.Chatter {
        get {
            self._innerChatter.value
        }
        set {
            self._innerChatter.value = newValue
            self.currentChatterPubSub.onNext(newValue)

            do {
                let pbChatter = newValue.transform()
                let cachedData = try pbChatter.serializedData()
                UserDefaults.standard.set(cachedData, forKey: self.chatterKey)
                Self.logger.info("Save chatter into UserDefaults", additionalData: ["id": newValue.id])
            } catch {
                Self.logger.error("Save chatter into UserDefaults failed.",
                                  additionalData: ["id": newValue.id],
                                            error: error)
                assertionFailure()
            }
        }
    }

    init(
        pushChatters: Observable<[Chatter]>
    ) {

        let env = EnvManager.env
        if env.type != .release {
            self.chatterKey = "\(chatterKey)_\(env.type)"
        }
        #if DEBUG
        self.chatterKey = "\(chatterKey)_debug"
        #endif

        pushChatters
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatters) in
            guard let self = self else {
                return
            }
            if let chatter = chatters.first(where: { (chatter) -> Bool in
                return chatter.id == self.accountService.currentAccountInfo.userID
            }) {
                self.currentChatter = chatter
                // 推送更新 name 需要使用 localizedName 因为：
                // 1. pushChatters 修改群组昵称时候也会推送（更新聊天人 ChatChatters），查看PushChattersHandler可知
                // 2. chatter.name = nickName ? nickName : localizedName, nickName 就是在chatExtra里的群昵称
                self.accountService.updateUserInfo(
                    userId: chatter.id,
                    name: chatter.localizedName,
                    avatarKey: chatter.avatarKey,
                    enUsName: chatter.enUsName,
                    avatarUrl: chatter.avatarOriginFirstUrl
                )
            } else {
                Self.logger.info("push update chatter not found", additionalData: [
                    "userId": self.accountService.currentAccountInfo.userID,
                    "chatter_ids": String(describing: chatters.map({ $0.id }))
                ])
            }
        }).disposed(by: self.disposeBag)
    }

    func getChatter(id: String) -> Observable<LarkModel.Chatter?> {
        getLocalChatter(id: id).concat(getRemoteChatter(id: id)).subscribeOn(scheduler)
    }

    private func getLocalChatter(id: String) -> Observable<LarkModel.Chatter?> {
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.syncDataStrategy = .local
        request.chatterIds = [id]
        return self.rustClient.sendAsyncRequest(request)
            .map { (response: RustPB.Contact_V1_MGetChattersResponse) -> LarkModel.Chatter? in
                response.entity.chatters[id].flatMap { LarkModel.Chatter.transform(pb: $0) }
            }
            .do(onError: { error in
                Self.logger.error("Load local chatter error", error: error)
            })
            .catchErrorJustReturn(nil)
    }

    private func getRemoteChatter(id: String) -> Observable<LarkModel.Chatter?> {
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.syncDataStrategy = .forceServer
        request.chatterIds = [id]
        return self.rustClient.sendAsyncRequest(request)
            .map { (response: RustPB.Contact_V1_MGetChattersResponse) -> LarkModel.Chatter? in
                response.entity.chatters[id].flatMap { LarkModel.Chatter.transform(pb: $0) }
            }
            .do(onError: { error in
                Self.logger.error("Load remote chatter error", error: error)
            })
            .catchErrorJustReturn(nil)
    }

    private func clearChatterCache() {
        UserDefaults.standard.set(nil, forKey: self.chatterKey)
    }

    // MARK: LauncherDelegate
    var name: String {
        return "ChatterManager"
    }

    func afterLogout(_ context: LauncherContext) {
        Self.logger.info("after logout clear chatter cache")
        self.clearChatterCache()
    }

    func fastLoginAccount(_ account: Account) {
        Self.logger.info("fastLogin refresh chatter")
        getChatter(id: account.userID).subscribe(onNext: { [weak self] chatter in
            guard let chatter = chatter, let self = self else {
                Self.logger.info("Load chatter fail when setting account. \(account.userID)")
                return
            }
            self.currentChatter = chatter
        }).disposed(by: disposeBag)
    }

    func updateAccount(_ account: Account) -> Observable<Void> {
        Self.logger.info("udpate account refresh chatter")
        return getChatter(id: account.userID)
            .do(onNext: { [weak self] chatter in
                guard let chatter = chatter, let self = self else {
                    Self.logger.info("Load chatter fail when setting account. \(chatter?.id)")
                    return
                }

                self.currentChatter = chatter
            })
            .map { _ in () }
    }
}

public extension Chatter {
    /// empty chatter
    static func placeholderChatter() -> Chatter {
        return Chatter(
            id: "",
            isAnonymous: false,
            isFrozen: false,
            name: "",
            localizedName: "",
            enUsName: "",
            namePinyin: "",
            alias: "",
            anotherName: "",
            nameWithAnotherName: "",
            type: .unknown,
            avatarKey: "",
            avatar: .init(),
            updateTime: .zero,
            creatorId: "",
            isResigned: false,
            isRegistered: false,
            description: .init(),
            withBotTag: "",
            canJoinGroup: false,
            tenantId: "",
            workStatus: .init(),
            majorLanguage: "",
            profileEnabled: false,
            focusStatusList: [],
            chatExtra: nil,
            accessInfo: .init(),
            email: "",
            doNotDisturbEndTime: .zero,
            openAppId: "",
            acceptSmsPhoneUrgent: false)
    }
}
