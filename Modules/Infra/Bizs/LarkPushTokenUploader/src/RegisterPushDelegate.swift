//
//  RegisterPushService.swift
//  LarkBaseService
//
//  Created by tangyunfei.tyf on 2020/3/17.
//

import Foundation
import RxSwift
import LKCommonsLogging
import Swinject
import RustPB
import LarkAccountInterface
import LarkContainer
import LarkNotificationContentExtension
import EENotification

public final class RegisterPushDelegate: PassportDelegate {
    public let name: String = "RegisterPush"

    private let logger = Logger.log(RegisterPushDelegate.self, category: "LarkPushTokenUploader.RegisterPushDelegate")

    private let resolver: Resolver
    private var userResolver: UserResolver?

    let triggerUploadSubject = PublishSubject<Void>()

    lazy var triggerUploadObservable: Observable<Void> = {
        return triggerUploadSubject.asObservable()
    }()

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func userDidOnline(state: PassportState) {
        guard state.loginState == .online,
              let userId = state.user?.userID else { return }
        do {
            logger.info("Regist Notification Task: \(userId)")
            let categories = [MessengerCategory.getCategory()]
            UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
            NotificationManager.shared.registerRemoteNotification()

            let userResolver = try resolver.getUserResolver(userID: userId)
            self.userResolver = userResolver
            let tokenUploader = try? userResolver.resolve(type: LarkPushTokenUploaderService.self) as? LarkPushTokenUploader
            /// 初始化可上线列表
            tokenUploader?.uploadCouldPushList()
            /// 触发token上报信号
            tokenUploader?.subscribeTriggerUploadObservable(triggerUploadObservable)
            triggerUploadSubject.onNext(())
        } catch {
            logger.error("userDidOnline error: \(error)")
        }
    }

    public func userDidOffline(state: PassportState) {
        guard state.loginState == .offline,
              let userId = state.user?.userID else { return } // 避免fastLogin走到这

        let multiUserService = try? self.resolver.resolve(type: MultiUserActivityCoordinatable.self)
        let multiUserNotificationSetting = multiUserService?.settingsEnableMultiUserActivity ?? false
        /// 多租户通知是开的，切换租户，不需要重新注册token
        if multiUserNotificationSetting && state.action == .switch {
            logger.info("multiUserNotificationSetting is on && swicth tenant")
            return
        }

        NotificationManager.shared.unregisterRemoteNotification()
        logger.info("unRegist Notification: \(userId)")
        /// 主账号退出后，会重新注册token，注册token后重新上报。
        /// 这里清空下之前上报的列表
        let tokenUploader = try? self.userResolver?.resolve(type: LarkPushTokenUploaderService.self) as? LarkPushTokenUploader
        tokenUploader?.resetUploadUser()
    }

    public func backgroundUserDidOnline(state: PassportState) {
        guard state.loginState == .online,
              let userId = state.user?.userID else { return }
        logger.info("backgroundUser \(userId) did online")
        let tokenUploader = try? self.userResolver?.resolve(type: LarkPushTokenUploaderService.self) as? LarkPushTokenUploader
        tokenUploader?.appendUploadUser(userId: userId, isForeground: false)
    }

    public func backgroundUserDidOffline(state: PassportState) {
        guard state.loginState == .offline,
              let userId = state.user?.userID else { return }
        logger.info("backgroundUser \(userId) did offline")
    }
}
