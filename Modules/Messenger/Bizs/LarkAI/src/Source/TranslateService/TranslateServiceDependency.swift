//
//  TranslateServiceDependencyImp.swift
//  LarkAI
//
//  Created by bytedance on 2020/9/21.
//

import Foundation
import UIKit
import LarkFeatureGating
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import Swinject

/// 翻译服务依赖
final class TranslateServiceDependency {
    private let userGeneralSettings: UserGeneralSettings
    private let pushCenter: PushNotificationCenter
    let useResolver: UserResolver

    let translateAPI: TranslateAPI
    let messageAPI: MessageAPI
    let chatAPI: ChatAPI
    let userAppConfig: UserAppConfig

    var translateLanguageSetting: TranslateLanguageSetting {
        return self.userGeneralSettings.translateLanguageSetting
    }

    var imageTranslateEnable: Bool {
        return self.useResolver.fg.dynamicFeatureGatingValue(with: "translate.image.chat.menu.enable")
    }

    init(resolver: UserResolver) throws {
        self.useResolver = resolver
        self.translateAPI = try resolver.resolve(assert: TranslateAPI.self)
        self.userGeneralSettings = try resolver.resolve(assert: UserGeneralSettings.self)
        self.messageAPI = try resolver.resolve(assert: MessageAPI.self)
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)
        self.userAppConfig = try resolver.resolve(assert: UserAppConfig.self)
        self.pushCenter = try resolver.userPushCenter
    }
}
