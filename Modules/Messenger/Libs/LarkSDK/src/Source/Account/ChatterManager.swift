//
//  ExtensionAssembly.swift
//  LarkAccount
//
//  Created by quyiming on 2020/9/9.
//

import Foundation
import Swinject
import EEAtomic
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
import LarkStorage

// MARK: ChatterManager
final class ChatterManager: ChatterManagerProtocol, UserResolverWrapper {
    static let logger = Logger.log(ChatterManager.self, category: "SuiteLogin.ChatterManager")
    let disposeBag = DisposeBag()

    @ScopedProvider var rustClient: RustService?
    @ScopedProvider var passportUserService: PassportUserService?
    @ScopedProvider var passportService: PassportService?

    lazy private var _innerChatter: SafeAtomic<Chatter> = {
        return self.refreshLocalChatter() + .readWriteLock
    }()

    let userResolver: UserResolver
    private let currentChatterPubSub = BehaviorSubject<Chatter?>(value: nil)
    var currentChatterObservable: Observable<Chatter> {
        return currentChatterPubSub
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .asObservable()
    }

    var currentChatter: LarkModel.Chatter {
        get {
            if self._innerChatter.value.id != userResolver.userID {
                // 上报埋点
                let exception = UserExceptionInfo(scene: "Chatter",
                                                  key: "get_chatter",
                                                  message: "user data is not consistency",
                                                  callerState: .ready,
                                                  calleeState: .compatible,
                                                  recordStack: true,
                                                  isError: true)
                UserExceptionInfo.log(exception)
            }
            Self.logger.info("get chatter: \(self._innerChatter.value.id)")
            return self._innerChatter.value
        }
        set {
            self._innerChatter.value = newValue
            self.currentChatterPubSub.onNext(newValue)

            do {
                let pbChatter = newValue.transform()
                let cachedData = try pbChatter.serializedData()
                self.userStore[self.chatterKey] = cachedData
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
        pushChatters: Observable<[Chatter]>,
        userResolver: UserResolver
    ) {
        self.userResolver = userResolver
        self._userStore = SafeLazy {
            userResolver.udkv(domain: Domain.biz.core.child("Chatter"))
        }

        pushChatters
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatters) in
            guard let self = self else {
                return
            }
            if let chatter = chatters.first(where: { (chatter) -> Bool in
                return chatter.id == userResolver.userID
            }) {
                self.currentChatter = chatter
                // 推送更新 name 需要使用 localizedName 因为：
                // 1. pushChatters 修改群组昵称时候也会推送（更新聊天人 ChatChatters），查看PushChattersHandler可知
                // 2. chatter.name = nickName ? nickName : localizedName, nickName 就是在chatExtra里的群昵称
                self.passportService?.updateUserInfo(
                    userId: chatter.id,
                    name: chatter.localizedName,
                    avatarKey: chatter.avatarKey,
                    enUsName: chatter.enUsName,
                    avatarUrl: chatter.avatarOriginFirstUrl
                )
            } else {
                Self.logger.info("push update chatter not found", additionalData: [
                    "userId": userResolver.userID,
                    "chatter_ids": String(describing: chatters.map({ $0.id }))
                ])
            }
        }).disposed(by: self.disposeBag)
    }

    func refreshLocalChatter() -> Chatter {
        guard let cachedData = self.userStore[self.chatterKey] else {
            Self.logger.info("Fail to load chatter from UserDefaults")
            return placeHolderChatter(user: try? userResolver.resolve(type: PassportUserService.self).user)
        }
        do {
            let pbChatter = try Chatter.PBModel(serializedData: cachedData)
            return Chatter.transform(pb: pbChatter)
            Self.logger.info("load chatter from UserDefaults: \(self.chatterKey.raw)")
        } catch {
            Self.logger.error("Serialized data failed", error: error)
            return placeHolderChatter(user: try? userResolver.resolve(type: PassportUserService.self).user)
        }
    }

    func getChatter(id: String) -> Observable<LarkModel.Chatter?> {
        getLocalChatter(id: id).concat(getRemoteChatter(id: id)).subscribeOn(scheduler)
    }

    private func placeHolderChatter(user: User?) -> Chatter {
        if let user = user {
            return Chatter(
                id: user.userID,
                isAnonymous: false,
                isFrozen: user.isFrozen,
                name: user.name,
                localizedName: user.localizedName,
                enUsName: user.localizedName,
                namePinyin: "",
                alias: "",
                anotherName: "",
                nameWithAnotherName: "",
                type: .unknown,
                avatarKey: user.avatarKey,
                avatar: .init(),
                updateTime: .zero,
                creatorId: "",
                isResigned: false,
                isRegistered: false,
                description: .init(),
                withBotTag: "",
                canJoinGroup: false,
                tenantId: user.tenant.tenantID,
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
        } else {
            return Chatter.placeholderChatter()
        }
    }

    private func getLocalChatter(id: String) -> Observable<LarkModel.Chatter?> {
        guard let rustClient = rustClient else { return Observable.just(nil) }
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.syncDataStrategy = .local
        request.chatterIds = [id]
        return rustClient.sendAsyncRequest(request)
            .map { (response: RustPB.Contact_V1_MGetChattersResponse) -> LarkModel.Chatter? in
                return try? LarkModel.Chatter.transformChatter(entity: response.entity, id: id)
            }
            .do(onError: { error in
                Self.logger.error("Load local chatter error", error: error)
            })
            .catchErrorJustReturn(nil)
    }

    private func getRemoteChatter(id: String) -> Observable<LarkModel.Chatter?> {
        guard let rustClient = rustClient else { return Observable.just(nil) }
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.syncDataStrategy = .forceServer
        request.chatterIds = [id]
        return rustClient.sendAsyncRequest(request)
            .map { (response: RustPB.Contact_V1_MGetChattersResponse) -> LarkModel.Chatter? in
                return try? LarkModel.Chatter.transformChatter(entity: response.entity, id: id)
            }
            .do(onError: { error in
                Self.logger.error("Load remote chatter error", error: error)
            })
            .catchErrorJustReturn(nil)
    }

    private func clearChatterCache() {
        self.userStore[self.chatterKey] = nil
    }

    // MARK: LauncherDelegate
    var name: String {
        return "ChatterManager"
    }

    // KV 存储部分
    @SafeLazy
    private var userStore: KVStore
    private var chatterKey: KVKey<Data?> {
        var chatterKey = "Cached.Account.Key"
        let env = EnvManager.env
        if env.type != .release {
            chatterKey = "\(chatterKey)_\(env.type)"
        }
        #if DEBUG
        chatterKey = "\(chatterKey)_debug"
        #endif
        return .init(chatterKey)
    }

    func logout() {
        Self.logger.info("after logout clear chatter cache")
        self.clearChatterCache()
    }

    func updateUser(_ user: User) {
        Self.logger.info("fastLogin refresh chatter: \(user.userID)")
        self.currentChatter = self.refreshLocalChatter()
        getChatter(id: user.userID).subscribe(onNext: { [weak self] chatter in
            guard let chatter = chatter, let self = self else {
                Self.logger.info("Load chatter fail when setting account. \(user.userID)")
                return
            }
            Self.logger.info("Load chatter success in fastLoginAccount. \(chatter.id)")
            self.currentChatter = chatter
        }).disposed(by: disposeBag)
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

class ChatterManagerPassportDelegate: PassportDelegate {

    init(container: Container) {
        self.container = container
    }

    private let container: Container

    func userDidOnline(state: PassportState) {

        guard let id = state.user?.userID,
              let currentUserResolver = try? container.getUserResolver(userID: id),
              let chatterManager = try? currentUserResolver.resolve(assert: ChatterManagerProtocol.self) else { return }
        if case .online = state.loginState, let user = state.user {
            chatterManager.updateUser(user)
        }
    }
}
