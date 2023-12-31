//
//  CallKitPassportDelegate.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/6.
//

import ByteView
import ByteViewCommon
import ByteViewSetting
import Foundation
import LarkAccountInterface
import LarkContainer
#if canImport(LarkPushTokenUploader)
import LarkPushTokenUploader
#endif
import PushKit
import RxSwift

final class CallKitPassportDelegate: PassportDelegate {
    static let shared = CallKitPassportDelegate()

    private static let logger = Logger.getLogger("PushKit")
    private var pushKitEnable = true
    private let voIPTokenSubject = PublishSubject<String?>()
    private var userID: String = ""

    func stateDidChange(state: PassportState) {
        guard state.user == nil || state.loginState == .offline else { return }
        self.logout()
    }

    func start(userResolver: UserResolver) {
        self.userID = userResolver.userID
        CallKitLauncher.setup(userId: self.userID) {
            try MeetingDependencyImpl(userResolver: userResolver)
        }
        // pushkit token 任务不阻塞 CallKit 任务启动
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now()) { [weak self] in
            self?.setupVoipTokenRegister(userResolver: userResolver)
        }
    }

    private func setupVoipTokenRegister(userResolver: UserResolver) {
        // 订阅 PushKit token
        self.setupTokenUploader(userResolver: userResolver)
        // 取消之前的订阅
        // 有 CallKit 能力（即能看到 callkit 设置项）的即需要上报 voip token，存在多设备登录，
        // 某一台打开了 CallKit 设置，导致当前的设备无法收到 CallKit 推送.
        guard let service = try? userResolver.resolve(assert: UserSettingManager.self), service.showsCallKitSetting else {
            Self.logger.info("use null voip token, uid: \(self.userID)")
            self.pushKitEnable = false
            return
        }
        self.pushKitEnable = true

        // upload voIP Token
        if let token = PushKitService.shared.tokenCache[.voIP]?.token {
            Self.logger.info("upload voip token \(token.suffix(6)) via cache, uid: \(self.userID)")
            self.voIPTokenSubject.onNext(token)
        }
        PushKitService.shared.addHandler(self)
    }

    private func setupTokenUploader(userResolver: UserResolver) {
        #if canImport(LarkPushTokenUploader)
        guard let uploader = try? userResolver.resolve(assert: LarkPushTokenUploaderService.self) else { return }
        Self.logger.info("setup voip token uploader, uid: \(self.userID)")
        uploader.subscribeVoIPObservable(voIPTokenSubject.asObservable())
        #endif
    }

    private func logout() {
        CallKitLauncher.destroy()
        // handle logout
        Self.logger.info("unregistryPushKit voip token, uid: \(self.userID)")
        PushKitService.shared.cleanAllCache()
        PushKitService.shared.removeHandler(self)
        PushKitService.shared.unregistryPushKit()
        self.userID = ""
    }
}

extension CallKitPassportDelegate: PushKitServiceHandler {
    func handleToken(_ token: PushKitToken) {
        guard token.type == .voIP else { return }
        Self.logger.info("upload voip token \(token.token.suffix(6)) via handler, uid: \(self.userID)")
        self.voIPTokenSubject.onNext(token.token)
    }
}
