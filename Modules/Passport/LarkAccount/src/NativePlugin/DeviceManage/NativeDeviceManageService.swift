//
//  DeviceManageApi.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/6.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkFoundation
import LarkContainer
import LarkAccountInterface
import RxRelay
import LarkSensitivityControl

class NativeDeviceManageService: APIV3, DeviceManageServiceProtocol {

    let disposeBag = DisposeBag()

    let deviceService: DeviceService

    var loginDevices: Observable<[LoginDevice]> {
        return validSessionsVariable.asObservable().distinctUntilChanged()
    }

    init(resolver: UserResolver?) throws {
        if let r = resolver {
            deviceService = try r.resolve(assert: DeviceService.self)
        } else {
            deviceService = try Container.shared.resolve(assert: DeviceService.self)
        }
    }

    func fetchLoginDevices() {
        return innerFetchValidSessions()
            .trace("fetchValidSessions")
            .subscribe(onNext: { (sessions) in
                self.validSessionsVariable.accept(self.updateCurrentDeviceInfo(sessions: sessions))
            }).disposed(by: disposeBag)

    }

    func disableLoginDevice(deviceID: String) -> Observable<Bool> {
        logoutSessions(did: deviceID).do(onNext: { [weak self] (success) in
            guard let `self` = self, success else { return }
            let validSessionsVariable = self.validSessionsVariable.value
            self.validSessionsVariable.accept(validSessionsVariable.filter({ (model) -> Bool in
                return model.id != deviceID
            }))
        })
    }

    func updateLoginDevices(_ sessions: [LoginDevice]) {
        self.validSessionsVariable.accept(self.updateCurrentDeviceInfo(sessions: sessions))
    }

    private var validSessionsVariable = BehaviorRelay<[LoginDevice]>(value: [])

    private func updateCurrentDeviceInfo(sessions: [LoginDevice]) -> [LoginDevice] {

        let deviceName: String
        do{
            deviceName = try DeviceInfoEntry.getDeviceName(forToken: Token("LARK-PSDA-passport_update_session_device_name"), device: UIDevice.current)
        } catch {
            //业务方应该在此实现兜底逻辑
            deviceName = UIDevice.current.lu.modelName()
        }

        var newSessions = sessions
        let currentOs = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        let index = sessions.firstIndex(where: { (session) -> Bool in
            return session.isCurrent && (session.name != deviceName || session.os != currentOs)
        })
        if let index = index {
            let session: LoginDevice = sessions[index]
            let newSession = LoginDevice(
                id: deviceService.deviceId,
                name: deviceName,
                os: currentOs,
                model: UIDevice.current.lu.modelName(),
                terminal: .ios,
                tenantName: session.tenantName,
                loginTime: session.loginTime,
                loginIP: session.loginIP,
                isCurrent: session.isCurrent,
                isAbnormal: session.isAbnormal
            )
            newSessions[index] = newSession
            
            updateDeviceInfo(newSession) { error in
                if let error = error {
                    Self.logger.error("updateCurrentDeviceInfo error", error: error)
                }
            }
        }
        return newSessions
    }

    private func innerFetchValidSessions() -> Observable<[LoginDevice]> {
        return fetchValidSessions()
            .trace("innerFetchValidSessions")
    }

    private func fetchValidSessions() -> Observable<[LoginDevice]> {
        let request = AfterLoginRequest<V3.ListDevicesResponse>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.listDevice.apiIdentify())
        request.required(.suiteSessionKey)
        request.method = .get
        request.domain = .passportAccounts()
        
        return self.client.send(request)
            .flatMap { (response) -> Observable<[LoginDevice]> in
                if let data = response.data {
                    return .just(data)
                } else {
                    Self.logger.error("Response with nil data for listDevices")
                    return Observable<[LoginDevice]>.error(V3LoginError.badServerData)
                }
            }
    }

    private func updateDeviceInfo(_ info: LoginDevice, completion: @escaping (V3LoginError?) -> Void) {
        let request = AfterLoginRequest<V3.ListDevicesResponse>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.updateDevice.apiIdentify())
        request.required(.suiteSessionKey)
        request.method = .post
        request.domain = .passportAccounts()
        var reqBody = [
            "device_name": info.name,
            "device_model": info.model,
            "device_os": info.os,
            "lark_version": Utils.appVersion
        ]
        #if LarkAccount_RUST
        reqBody["sdk_version"] = RustStaticInfo.sdkVersion
        #endif
        request.body = reqBody

        return client.send(request) { response, header in
            completion(nil)
        } failure: { error in
            completion(error)
        }

    }

    private func logoutSessions(did: String) -> Observable<Bool> {
        let request = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.disableDevice.apiIdentify())
        request.body = [
            "device_id": did
        ]
        request.domain = .passportAccounts()
        
        return Observable.create { (ob) -> Disposable in
            self.client.send(request) { (response, _) in
                ob.onNext(true)
                ob.onCompleted()
            } failure: { (error) in
                ob.onError(error)
            }
            return Disposables.create()
        }
    }
}
