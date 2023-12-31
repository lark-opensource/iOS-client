//
//  UserUniversalSettingConfig.swift
//  LarkSDK
//
//  Created by zhangxingcheng on 2021/7/6.
//

import Foundation
//请求类
import RustPB
//Rxswift
import RxSwift
//（待学习）
import LarkContainer
import LarkRustClient
//推送使用的两个类
import LarkSDKInterface
import LKCommonsLogging
//线程安全类
import ThreadSafeDataStructure

final class UserUniversalSettingConfig: UserUniversalSettingService, UserResolverWrapper {
    private static let logger = Logger.log(UserUniversalSettingConfig.self, category: "Module.LarkSDK.UserSettingConfig")

    /**（1）请求体*/
    @ScopedProvider var client: RustService?

    /**（2）接收推送*/
    private let pushCenter: PushNotificationCenter
    let userResolver: UserResolver

    /**（3）Rxswift*/
    private let disposeBag = DisposeBag()

    /**（5）设置oneof value（通过BehaviorSubject监听）*/
    private var settingMapSubject: BehaviorSubject<[String: UserUniversalSettingValue]> = BehaviorSubject<[String: UserUniversalSettingValue]>(value: [:])

    /**（6）设置oneof value*/
    private var settingMap: SafeDictionary<String, UserUniversalSettingValue> = [:] + .readWriteLock

    init(pushCenter: PushNotificationCenter, userResolver: UserResolver) {
        self.pushCenter = pushCenter
        self.userResolver = userResolver
    }

    //- --------------- publicMethod ---------------
    /**（1）对外提供的更新设置方法（key是GLOBALLY_ENTER_CHAT_POSITION、value是1 2 3）*/
    public func setUniversalUserConfig(values: [String: UserUniversalSettingValue]) -> Observable<Void> {
        //request为拉取、更新数据的请求
        var request = RustPB.Settings_V1_UpdateUniversalUserSettingRequest()
        let settings = values.map { (key, value) -> Basic_V1_UniversalUserSetting in
            //Basic_V1_UniversalUserSetting获取到数据以及更新数据的类型
            var setting = RustPB.Basic_V1_UniversalUserSetting()
            setting.key = key
            switch value {
            case .intValue(let value):
                setting.intValue = value
            case .boolValue(let value):
                setting.boolValue = value
            case .strValue(let value):
                setting.strValue = value
            @unknown default:
                assertionFailure("unknown case")
                //fatalError()
            }
            return setting
        }
        request.settings = settings
        //更新完settings参数交给RustPB处理
        return self.client?.sendAsyncRequest(request).do(onNext: { [weak self] in
            guard let self else { return }
            for (key, value) in values {
                self.settingMap[key] = value
            }
            self.settingMapSubject.onNext((self.settingMap.getImmutableCopy()))
        }) ?? .empty()
    }

    /**（2）获取通用类型配置*/
    public func getUniversalUserSetting(key: String) -> UserUniversalSettingValue? {
        return self.settingMap[key]
    }

    /**（3）获取Int类型配置*/
    public func getIntUniversalUserSetting(key: String) -> Int64? {
        let value = self.settingMap[key]
        switch value {
        case .intValue(let result):
            return result
        @unknown default:
            return nil
        }
    }

    /**（4）获取String类型配置*/
    public func getStringUniversalUserSetting(key: String) -> String? {
        let value = self.settingMap[key]
        switch value {
        case .strValue(let result):
            return result
        @unknown default:
            return nil
        }
    }

    /**（5）获取BOOL类型配置*/
    public func getBoolUniversalUserSetting(key: String) -> Bool? {
        let value = self.settingMap[key]
        switch value {
        case .boolValue(let result):
            return result
        @unknown default:
            return nil
        }
    }

    /**（6-1）通过信号获取（Int64类型value）*/
    public func getIntUniversalUserObservableSetting(key: String) -> Observable<Int64?> {
        return self.settingMapSubject.asObserver().map { [weak self] _ in
            let value = self?.settingMap[key]
            switch value {
            case .intValue(let result):
                return result
            @unknown default:
                return nil
            }
        }
    }

    /**（6-2）通过信号获取（String类型value）*/
    public func getStringUniversalUserObservableSetting(key: String) -> Observable<String?> {
        return self.settingMapSubject.asObserver().map { [weak self] _ in
            let value = self?.settingMap[key]
            switch value {
            case .strValue(let result):
                return result
            @unknown default:
                return nil
            }
        }
    }

    /**（6-3）通过信号获取（Bool类型value）*/
    public func getBoolUniversalUserObservableSetting(key: String) -> Observable<Bool?> {
        return self.settingMapSubject.asObserver().map { [weak self] _ in
            let value = self?.settingMap[key]
            switch value {
            case .boolValue(let result):
                return result
            default:
                return nil
            }
        }
    }

    /**（7）通过信号获取通用类型（UserUniversalSettingValue类型value）*/
    public func getUniversalUserObservableSetting(key: String) -> Observable<UserUniversalSettingValue?> {
        return self.settingMapSubject.asObserver().map { [weak self] _ in
            return self?.settingMap[key]
        }
    }

    //- --------------- requestMethod ---------------
    /**（1-1）请求方法 - Https主动拉取全局设置数据（forceServer）*/
    private func getUniversalUserSettingForceServerRequest() -> Observable<Settings_V1_GetUniversalUserSettingResponse> {
        var request = RustPB.Settings_V1_GetUniversalUserSettingRequest()
        //（1）从本地拿LOCAL（2）先从本地拿，没有从远端拿TRY_LOCAL（3）始终读取远端FORCE_SERVER（改参数已和安卓同步）
        request.strategy = .forceServer
        //request.key = ["1"]（拉取单一数据）可忽略
        //（拉取全部）
        request.needAllKeys = true
        return self.client?.sendAsyncRequest(request) ?? .empty()
    }

    /**（1-2）请求方法 - Https主动拉取全局设置数据（local）*/
    private func getUniversalUserSettingLocalRequest() -> Observable<Settings_V1_GetUniversalUserSettingResponse> {
        var request = RustPB.Settings_V1_GetUniversalUserSettingRequest()
        //（1）从本地拿LOCAL（2）先从本地拿，没有从远端拿TRY_LOCAL（3）始终读取远端FORCE_SERVER（改参数已和安卓同步）
        request.strategy = .local
        //（拉取全部）
        request.needAllKeys = true
        return self.client?.sendAsyncRequest(request) ?? .empty()
    }

    /**（2）请求方法 - 获取Https配置信息与接收TCP推送配置信息*/
    public func setupUserUniversalInfo() {
        self.getUniversalUserSettingLocalRequest()
            .concat(self.getUniversalUserSettingForceServerRequest())
            .subscribe(onNext: { [weak self] response in
                self?.processingResponseData(values: response.settings)
            }, onError: { error in
                UserUniversalSettingConfig.logger.info("setupUserUniversalInfo request error \(error)")
            }).disposed(by: disposeBag)

        //（2）TCP推送回调
        pushCenter.observable(for: UserUniversalSettingPushInfo.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                self?.processingResponseData(values: push.pushConfigSetting)
            }).disposed(by: disposeBag)
    }

    //处理网络回调数据
    private func processingResponseData(values: [String: RustPB.Basic_V1_UniversalUserSetting]) {
        values.forEach { (key, pbValue) in
            self.settingMap[key] = pbValue.value
        }
        self.settingMapSubject.onNext(settingMap.getImmutableCopy())
    }
}

/**全局配置推送*/
private struct UserUniversalSettingPushInfo: PushMessage {
    public var pushConfigSetting = [String: RustPB.Basic_V1_UniversalUserSetting]()
    public init(pushConfigSetting: [String: RustPB.Basic_V1_UniversalUserSetting]) {
        self.pushConfigSetting = pushConfigSetting
    }
}

final class UserUniversalPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(WebSocketStatusPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Settings_V1_PushUniversalUserSetting) {
        let userSettingMessage = UserUniversalSettingPushInfo(pushConfigSetting: message.settings)
        self.pushCenter?.post(userSettingMessage)
    }
}
