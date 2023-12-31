//
//  DependencyImpl.swift
//  LarkWeb
//
//  Created by liuwanlin on 2018/7/7.
//

import Foundation
import RxSwift
import LarkRustClient
import LarkContainer
import LarkModel
import Swinject
import EENavigator
import LarkUIKit
import Kingfisher
import LKCommonsLogging
import RoundedHUD
import Reachability
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import LarkAppConfig
import LKCommonsTracker
import MailSDK
#if MessengerMod
import LarkMessengerInterface
#endif
import RustPB
import LarkWaterMark
import LarkNavigation

class LarkMailServiceDependencyImp: LarkMailServiceDependency {

    private let reach = Reachability()!

    static let logger = Logger.log(LarkMailServiceDependencyImp.self, category: "mail.service.dependency.impl")

    let resolver: UserResolver

    let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    var token: String? {
        return passportService?.user.sessionKey
    }

    var deviceID: String? {
        return try? resolver.resolve(assert: DeviceService.self).deviceId
    }
    var userDomain: String {
        guard let prefix = passportService?.user.tenant.tenantDomain,
              let appConfig = try? resolver.resolve(assert: AppConfiguration.self)
        else {
            let msg = "AppConfiguration have not inject"
            LarkMailServiceDependencyImp.logger.error(msg)
            Tracker.post(TeaEvent("mail_stability_assert", params: ["message": msg]))
            MailSDKManager.assertAndReportFailure(msg)
            return ""
        }
        if let mainDomain = appConfig.mainDomains.first {
            return "\(prefix).\(mainDomain)"
        } else {
            let msg = "mail construct userDomain get nil mainDomain"
            LarkMailServiceDependencyImp.logger.error(msg)
            MailSDKManager.assertAndReportFailure(msg)
            return ""
        }
    }

    var userIsOverSea: Bool {
        // 这个接口目前是gecko使用，gecko租户维度,
        return passportService?.isFeishuBrand == false
    }

    var userAppConfig: UserAppConfig? {
        return try? resolver.resolve(assert: UserAppConfig.self)
    }
    
    var userUniversalSettingService: UserUniversalSettingService? {
        return try? resolver.resolve(assert: UserUniversalSettingService.self)
    }

    var rustService: RustService? {
        return try? resolver.resolve(assert: RustService.self)
    }

    var currentChatter: Chatter? {
        return try? resolver.resolve(assert: ChatterManagerProtocol.self).currentChatter
    }

    var chatterAPI: ChatterAPI? {
        return try? resolver.resolve(assert: ChatterAPI.self)
    }

    var resourceAPI: ResourceAPI? {
        return try? resolver.resolve(assert: ResourceAPI.self)
    }

    var passportService: PassportUserService? {
        try? resolver.resolve(assert: PassportUserService.self)
    }

    var navigationService: NavigationService? {
        return try? resolver.resolve(assert: NavigationService.self)
    }

    var pushNotificationCenter: PushNotificationCenter? {
        return try? resolver.userPushCenter
    }

    var globalWaterMarkOn: Observable<Bool> {
        guard let service = try? resolver.resolve(assert: WaterMarkService.self) else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return service.globalWaterMarkIsShow
    }

    func openURL(_ url: URL?, from controller: UIViewController?) {
        guard let url = url else {
            return
        }
        if let fromVC = controller {
            resolver.navigator.push(url, from: fromVC)
        } else {
            if let fromVC = resolver.navigator.mainSceneWindow?.fromViewController {
                resolver.navigator.push(url, from: fromVC)
            }
        }
    }

    func showUserProfile(_ userId: String, from controller: UIViewController?) {
#if MessengerMod
        let body = PersonCardBody(chatterId: userId, source: RustPB.Basic_V1_ContactSource.email)
        if let fromVC = controller {
            resolver.navigator.push(body: body, from: fromVC)
        } else {
            if let fromVC = resolver.navigator.mainSceneWindow?.fromViewController {
                resolver.navigator.push(body: body, from: fromVC)
            }
        }
#endif
    }
}
