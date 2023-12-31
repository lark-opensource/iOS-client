//
//  LarkPushTokenUploader.swift
//  LarkApp
//
//  Created by mochangxing on 2019/9/17.
//

import UIKit
import Foundation
import LKCommonsLogging
import Swinject
import RxSwift
import LarkContainer
import LarkAccountInterface
import ThreadSafeDataStructure
import EENotification

final class LarkPushTokenUploader: LarkPushTokenUploaderService, UserResolverWrapper {

    let logger = Logger.log(LarkPushTokenUploader.self, category: "LarkPushTokenUploader")

    private lazy var pendingUploadQueue: LarkPushTokenUploadQueue = LarkPushTokenUploadQueue()
    private lazy var uploadRequest = PushTokenUploadRequest()

    let voipTokenPublshSubject: PublishSubject<String?> = PublishSubject()
    let apnsTokenPublshSubject: PublishSubject<String?> = PublishSubject()
    let triggerObservablePublshSubject: PublishSubject<Void> = PublishSubject()

    var hasSubscribeApnsTokenSubject: Bool = false
    var hasSubscribeVoipTokenSubject: Bool = false
    var hasSubscribeTriggerSubject: Bool = false

    var _apnsToken: SafeAtomic<String> = "" + .readWriteLock
    private var apnsToken: String {
        get {
            return _apnsToken.value
        }
        set {
            _apnsToken.value = newValue
        }
    }

    let userResolver: LarkContainer.UserResolver

    fileprivate let disposeBag = DisposeBag()

    /// - Parameter pushAPI: upload push token API
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.logger.info("init")
        _ = Observable.combineLatest(voipTokenPublshSubject.asObservable(), triggerObservablePublshSubject.asObservable())
            .subscribe(onNext: { [weak self] (voipToken, _) in
                guard let `self` = self else { return }
                self.logger.info("Receive new voip token upload lark server")
                self.uploadRequest.uploadVoipToken(voipToken, userResolver: self.userResolver)
            }).disposed(by: disposeBag)

        _ = Observable.combineLatest(apnsTokenPublshSubject.asObservable(), triggerObservablePublshSubject.asObservable())
            .subscribe(onNext: { [weak self] (apnsToken, _) in
                guard let `self` = self else { return }
                self.logger.info("Receive new apns token upload lark server")
                self.uploadRequest.uploadToken2TTpush(apnsToken, userResolver: self.userResolver)
                guard let apnsToken = apnsToken else {
                    return
                }
                self.apnsToken = apnsToken
                self.pendingUploadQueue.resume()
            }).disposed(by: disposeBag)
    }

    public func subscribeVoIPObservable(_ observable: Observable<String?>) {
        /// 一个user生命周期内保证只有一次订阅
        guard !self.hasSubscribeVoipTokenSubject else { return }
        observable.subscribe(voipTokenPublshSubject).disposed(by: disposeBag)
        self.hasSubscribeVoipTokenSubject = true
    }

    public func subscribeApnsObservable(_ observable: Observable<String?>) {
        /// 一个user生命周期内保证只有一次订阅
        guard !self.hasSubscribeApnsTokenSubject else { return }
        observable.subscribe(apnsTokenPublshSubject).disposed(by: disposeBag)
        self.hasSubscribeApnsTokenSubject = true
    }

    func subscribeTriggerUploadObservable(_ observable: Observable<Void>) {
        /// 一个user生命周期内保证只有一次订阅
        guard !self.hasSubscribeTriggerSubject else { return }
        observable.subscribe(triggerObservablePublshSubject).disposed(by: disposeBag)
        self.hasSubscribeTriggerSubject = true
    }

    func multiUserNotificationSwitchChange(_ isOn: Bool) {
        self.uploadCouldPushList()

        if (!isOn) {
            /// 开关关闭需要重新注册一次
            NotificationManager.shared.unregisterRemoteNotification()
            NotificationManager.shared.registerRemoteNotification()
        } else {
            self.pendingUploadQueue.resume()
        }
    }

    func uploadCouldPushList() {
        /// 主账号上线后需要触发上报一次
        if let multiUserService = try? userResolver.resolve(type: MultiUserActivityCoordinatable.self) {
            var activityUserIDList = multiUserService.activityUserIDList
            if !activityUserIDList.contains(self.userResolver.userID) {
                // 确保当前登录租户是有的，避免没上报导致没有推送
                activityUserIDList.append(self.userResolver.userID)
            }
            self.logger.info("start upload activityList: \(activityUserIDList)")
            self.initUploadUserList(pendingList: activityUserIDList)

            let couldPushListUploadService = try? userResolver.resolve(type: LarkCouldPushUserListService.self)
            couldPushListUploadService?.uploadCouldPushUserList(activityUserIDList)
        }
    }

    internal func initUploadUserList(pendingList: [String]) {
        self.resetUploadUser()
        guard let passportUserService = try? self.userResolver.resolve(type: PassportUserService.self) else {
            self.logger.error("initUploadUserList: resolve passportService error!")
            return
        }
        for userId in pendingList {
            var isForeground = false
            if userId == passportUserService.user.userID {
                isForeground = true
            }

            let resolver = self.userResolver.resolver
            let type: UserScopeType = isForeground ? .foreground : .background
            guard let _ = try? resolver.getUserResolver(userID: userId, type: type) else {
                /// 是否能获取到用户容器，获取不到说明还未上线
                /// 未上线的会在用户容器回调里触发`backgroundUserDidOnline`
                continue
            }
            self.appendUploadUser(userId: userId, isForeground: isForeground)
        }
    }

    internal func appendUploadUser(userId: String, isForeground: Bool) {
        let pendingUser = PendingUploadUser(userId: userId, isForeground: isForeground)
        self.pendingUploadQueue.appendTask(with: pendingUser, task: { [weak self] pendingUser in
            guard let `self` = self else { return }
            let resolver = self.userResolver.resolver
            let type: UserScopeType = isForeground ? .foreground : .background
            guard let userResolver = try? resolver.getUserResolver(userID: pendingUser.userId, type: type) else {
                return
            }
            self.logger.info("upload apns token to user: \(userResolver.userID), isForeground: \(isForeground)")
            self.uploadRequest.uploadApnsToken(self.apnsToken, userResolver: userResolver)
        })
    }

    internal func resetUploadUser() {
        self.pendingUploadQueue.reset()
    }
}
