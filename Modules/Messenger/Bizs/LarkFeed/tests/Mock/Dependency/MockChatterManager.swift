//
//  MockChatterManager.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/18.
//

import RustPB
import RxSwift
import RxRelay
import LarkContainer
import LarkSDKInterface
import LarkAccountInterface
import LarkModel
@testable import LarkFeed

final class MockChatterManager: ChatterManagerProtocol, UserResolverWrapper {
    // MARK: LauncherDelegate
    var name: String {
        return "ChatterManager"
    }

    let userResolver: UserResolver
    let disposeBag = DisposeBag()
    private lazy var _innerChatter: Chatter = MockChatterManager.placeholderChatter()

    private let currentChatterPubSub = BehaviorSubject<Chatter?>(value: nil)
    var currentChatterObservable: Observable<Chatter> {
        return currentChatterPubSub
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .asObservable()
    }

    var currentChatter: Chatter {
        get {
            if self._innerChatter.id != userResolver.userID {
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
            return self._innerChatter
        }
        set {
            self._innerChatter = newValue
            self.currentChatterPubSub.onNext(newValue)
        }
    }

    func logout() { }
    func updateUser(_ user: User) { }

    init(
        pushChatters: Observable<[Chatter]>,
        userResolver: UserResolver
    ) {

        self.userResolver = userResolver
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
                    //                self.passportService?.updateUserInfo(
                    //                    userId: chatter.id,
                    //                    name: chatter.localizedName,
                    //                    avatarKey: chatter.avatarKey,
                    //                    enUsName: chatter.enUsName,
                    //                    avatarUrl: chatter.avatarOriginFirstUrl
                    //                )
                }
            }).disposed(by: self.disposeBag)
    }
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
