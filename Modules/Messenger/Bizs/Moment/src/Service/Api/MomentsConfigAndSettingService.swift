//
//  MomentsUserCircleConfigService.swift
//  Moment
//
//  Created by liluobin on 2021/5/28.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer
import LKCommonsLogging
import RustPB

protocol MomentsConfigAndSettingService: AnyObject {
    func getUserCircleConfigWithFinsih(_ finish: ((RawData.UserCircleConfig) -> Void)?, onError: ((Error) -> Void)?)
    func getUserSettingWithFinish(_ finish: ((RawData.MomentsUserSetting) -> Void)?, onError: ((Error) -> Void)?)
    func updateUserNickName(momentUser: RawData.RustMomentUser, renewNicknameTime: Int64)
    var rxUpdateNickNameNot: PublishSubject<RawData.RustMomentUser> { get }
    func setRedDotNotify(enable: Bool, finish: @escaping (Bool) -> Void)
}

final class MomentsConfigAndSettingServiceIMP: MomentsConfigAndSettingService, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    static let logger = Logger.log(MomentsConfigAndSettingServiceIMP.self, category: "Module.Moments.MomentsUserCircleConfigServiceIMP")
    private let disposeBag = DisposeBag()
    private var hadObserver: Bool = false
    @ScopedInjectedLazy private var tabService: UserTabApiService?
    @ScopedInjectedLazy private var configNot: MomentsUserGlobalConfigAndSettingNotification?
    let rxUpdateNickNameNot: PublishSubject<RawData.RustMomentUser> = .init()
    private var currentConfig: RawData.UserConfigResponse?
    private var currentSetting: RawData.UserSettingResponse?
    @ScopedInjectedLazy private var settingApi: SettingApiService?

    func getUserCircleConfigWithFinsih(_ finish: ((RawData.UserCircleConfig) -> Void)?, onError: ((Error) -> Void)?) {
        /// 存在UserCircleConfig 直接返回
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let config = self.currentConfig {

                finish?(config.userCircleConfig)
            } else {
                self.tabService?.getUserConfigAndSettingsRequest()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (config) in
                        self?.currentConfig = config
                        finish?(config.userCircleConfig)
                        self?.addObserver()
                    }, onError: { (error) in
                        onError?(error)
                        Self.logger.error("getUserConfigAndSettingsRequest \(error)")
                    }).disposed(by: self.disposeBag)
            }
        }
    }

    func getUserSettingWithFinish(_ finish: ((RawData.MomentsUserSetting) -> Void)?, onError: ((Error) -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let setting = self.currentSetting {
                finish?(setting.userSetting)
            } else {
                self.tabService?.getUserSettingRequest()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (setting) in
                        self?.currentSetting = setting
                        finish?(setting.userSetting)
                        self?.addObserver()
                    }, onError: { (error) in
                        onError?(error)
                        Self.logger.error("getUserSettingRequest \(error)")
                    }).disposed(by: self.disposeBag)
            }
        }
    }

    /// 监听数据变化
    func addObserver() {
        if hadObserver {
            return
        }
        hadObserver = true
        configNot?.rxConfig
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (nof) in
                var config = Moments_V1_GetUserConfigAndSettingsResponse()
                config.userCircleConfig = nof.userCircleConfig
                if let manageMode = self?.currentConfig?.userCircleConfig.manageMode {
                    //manageMode需要特化 不随push更新
                    config.userCircleConfig.manageMode = manageMode
                }
                config.momentsAdminURL = nof.momentsAdminURL
                config.globalConfig = nof.globalConfig
                self?.currentConfig = config
                var setting = Moments_V1_GetUserSettingResponse()
                setting.userSetting = nof.userSetting
                self?.currentSetting = setting
            }, onError: { (error) in
                Self.logger.error("configNot.rxConfig \(error)")
            }).disposed(by: disposeBag)
    }

    func updateUserNickName(momentUser: RawData.RustMomentUser, renewNicknameTime: Int64) {
        self.currentConfig?.userCircleConfig.nicknameUser = momentUser
        self.currentConfig?.userCircleConfig.renewNicknameTimeSec = renewNicknameTime
        self.rxUpdateNickNameNot.onNext(momentUser)
    }

    func setRedDotNotify(enable: Bool, finish: @escaping (Bool) -> Void) {
        self.settingApi?.setRedDotNotify(enable: enable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.currentSetting?.userSetting.muteRedDotNotify = !enable
                finish(true)
            }, onError: { error in
                Self.logger.error("setRedDotNotify error", error: error)
                finish(false)
            }).disposed(by: self.disposeBag)
    }
}
