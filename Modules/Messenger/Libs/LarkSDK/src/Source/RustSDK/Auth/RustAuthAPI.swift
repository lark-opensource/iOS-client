//
//  RustAuthAPI.swift
//  Lark
//
//  Created by linlin on 2017/10/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import RxRelay
import LKCommonsLogging
import LarkAccountInterface
import LarkSensitivityControl

final class RustAuthAPI: LarkAPI, AuthAPI {

    static let logger = Logger.log(RustAuthAPI.self, category: "RustSDK.Auth")

    private let deviceId: String

    private var validSessionsVariable = BehaviorRelay<[RustPB.Basic_V1_Device]>(value: [])

    private var isNotifyVariable = BehaviorRelay<Bool>(value: true)

    private let disposeBag = DisposeBag()

    /// 当前有效设备
    var validSessions: Observable<[RustPB.Basic_V1_Device]> {
        return validSessionsVariable.asObservable().distinctUntilChanged()
    }

    /// 是否通知
    var isNotify: Bool {
        get {
            return isNotifyVariable.value
        }
        set {
            isNotifyVariable.accept(newValue)
        }
    }

    /// 通知状态变化信号
    var isNotifyObservable: Observable<Bool> {
        return isNotifyVariable.asObservable()
    }

    init(deviceId: String, client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.deviceId = deviceId
        super.init(client: client, onScheduler: onScheduler)
    }

    func fetchValidSessions() -> Observable<[RustPB.Basic_V1_Device]> {
        return RustAuthModule
            .fetchValidSessions(client: client)
            .do(onNext: { [weak self] (sessions) in
                guard let `self` = self else { return }
                self.validSessionsVariable.accept(self.updateCurrentDeviceInfo(sessions: sessions))
            })
            .subscribeOn(scheduler)
    }

    func updateValidSessions(with sessions: [RustPB.Basic_V1_Device]) {
        self.validSessionsVariable.accept(sessions)
    }

    func forceSessionInvalid(identifier: SessionIdentifier) -> Observable<Bool> {
        return RustAuthModule
            .forceSessionInvalid(identifier: identifier, client: client)
            .do(onNext: { [weak self] (success) in
                guard let `self` = self, success else { return }

                let validSessionsVariable = self.validSessionsVariable.value
                self.validSessionsVariable.accept(validSessionsVariable.filter({ (model) -> Bool in
                    return model.id != identifier
                }))
            })
            .subscribeOn(scheduler)
    }

    func logout() -> Observable<Void> {
        return RustAuthModule
            .logout(client: self.client)
            .subscribeOn(scheduler)
    }

    func updateDeviceInfo(deviceInfo: RustPB.Basic_V1_Device) -> Observable<Void> {
        return RustAuthModule
            .updateDeviceInfo(deviceInfo: deviceInfo, client: self.client)
            .subscribeOn(scheduler)
    }

    func setReqIdSuffix(_ suffix: String) -> Observable<Void> {
        return RustAuthModule
            .setReqIdSuffix(suffix, client: self.client)
            .subscribeOn(scheduler)
    }

    private func updateCurrentDeviceInfo(sessions: [RustPB.Basic_V1_Device]) -> [RustPB.Basic_V1_Device] {
        var newSessions = sessions
        let currentOs = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        var currentDeviceName: String = ""
        do {
            currentDeviceName = try DeviceInfoEntry.getDeviceName(
                forToken: Token(withIdentifier: "LARK-PSDA-RustSDK_update_session"),
                device: UIDevice.current)
        } catch {
            currentDeviceName = UIDevice.current.lu.modelName()
            Self.logger.warn("Could not fetch device name by LarkSensitivityControl API, use model name as fallback.")
        }
        let index = sessions.firstIndex(where: { (session) -> Bool in
            return session.isCurrentDevice && (session.name != currentDeviceName || session.os != currentOs)
        })
        if let index = index {
            var session: RustPB.Basic_V1_Device = sessions[index]
            session.id = deviceId
            session.os = currentOs
            session.name = currentDeviceName
            session.model = UIDevice.current.lu.modelName()
            session.terminal = .ios
            session.isOnline = true
            newSessions[index] = session
            updateDeviceInfo(deviceInfo: session)
                .subscribe()
                .disposed(by: disposeBag)
        }
        return newSessions
    }
}
