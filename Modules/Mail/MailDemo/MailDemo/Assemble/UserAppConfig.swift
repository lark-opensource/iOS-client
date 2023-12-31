//
//  UserAppConfig.swift
//  Lark
//
//  Created by 李晨 on 2019/1/20.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import LarkModel
import RxSwift
import LKCommonsLogging
import LarkLocalizations
import LarkSDKInterface
import RustPB
import LarkSetting

final class BaseUserAppConfig: UserAppConfig {

    static let logger = Logger.log(BaseUserAppConfig.self, category: "lark.user.app.cofing")

    var appConfig: RustPB.Basic_V1_AppConfig? {
        if _appConfig == nil {
            BaseUserAppConfig.logger.warn("use app config before config init")
        }
        return _appConfig
    }

    private var disposeBag: DisposeBag = DisposeBag()

    let semaphore = DispatchSemaphore(value: 1)
    private var _appConfig_locked: RustPB.Basic_V1_AppConfig?

    // 线程安全的 property
    private var _appConfig: RustPB.Basic_V1_AppConfig? {
        get {
            semaphore.wait()
            defer { semaphore.signal() }
            return _appConfig_locked
        }
        set {
            semaphore.wait()
            _appConfig_locked = newValue
            semaphore.signal()

            if let config = newValue {
                appConfigSubject.onNext(config)
            }
        }
    }
    private var loading: Bool = false
    private var loadFromServer: Bool = false

    var appConfigSignal: Observable<RustPB.Basic_V1_AppConfig> {
        return appConfigSubject.asObservable()
    }
    private var appConfigSubject = ReplaySubject<RustPB.Basic_V1_AppConfig>.create(bufferSize: 1)

    var configAPI: ConfigurationAPI

    init(configAPI: ConfigurationAPI,
         pushWebSocketStatusOb: Observable<PushWebSocketStatus>,
         pushAppConfigOb: Observable<PushAppConfig>) {
        self.configAPI = configAPI

        pushWebSocketStatusOb.subscribe(onNext: { [weak self] (socket) in
            guard let `self` = self else { return }
            switch socket.status {
            case .success:
                self.fetchAppConfigIfNeeded()
            default:
                break
            }
        }).disposed(by: self.disposeBag)
        /// AppConfig push
        pushAppConfigOb.subscribe(onNext: { [weak self] (pushAppConfig) in
            guard let `self` = self else { return }
            self._appConfig = pushAppConfig.appConfig
        }).disposed(by: self.disposeBag)
    }

    func resourceAddrWithLanguage(key: String) -> String? {
        var addr: String?
        // 数据迁到到Lark Setting，详细历史和逻辑可参考：https://bytedance.feishu.cn/docs/doccnhLxHJRY6jSeK5olsNZu9rg#VLIXFB
        if let settingDict = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "client_dynamic_link")), let tempAddr = settingDict[key] {
            addr = tempAddr as? String
        } else if let tempAddr = self.appConfig?.resource.addrs[key] {
            addr = tempAddr as? String
        }
        guard let addr = addr,
            let url = URL(string: addr) else {
                return nil
        }

        return url.append(parameters: ["lang": LanguageManager.currentLanguage.languageCode!]).absoluteString
    }

    func fetchAppConfigIfNeeded() {
        if self._appConfig != nil && self.loadFromServer {
            return
        }

        if self._appConfig == nil {
            self._appConfig = configAPI.getAppConfigFromLocal()
            BaseUserAppConfig.logger.info("load app config from local")
        }

        if loading == false {
            loading = true
            BaseUserAppConfig.logger.info("start load app config from server")
            self.configAPI.getAppConfig()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (appConfig) in
                    BaseUserAppConfig.logger.info("load app config from server finish")
                    self?.loading = false
                    self?._appConfig = appConfig
                    self?.loadFromServer = true
                }, onError: { [weak self] (error) in
                    self?.loading = false
                    BaseUserAppConfig.logger.error("load app config from server error", error: error)
                }).disposed(by: self.disposeBag)
        }
    }
}
