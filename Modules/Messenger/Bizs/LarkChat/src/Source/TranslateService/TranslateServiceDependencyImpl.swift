//
//  TranslateServiceDependencyImpl.swift
//  LarkApp
//
//  Created by 李勇 on 2019/11/12.
//

import Foundation
import LarkFeatureGating
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import Swinject
import LarkMessageCore
import RxSwift

/// 翻译服务依赖
final class TranslateServiceDependencyImpl: TranslateServiceDependency, UserResolverWrapper {
    let userResolver: UserResolver
    private let pushCenter: PushNotificationCenter

    let translateAPI: TranslateAPI
    let messageAPI: MessageAPI
    let chatAPI: ChatAPI

    var translateLanguageSetting: TranslateLanguageSetting {
        return self.userGeneralSettings.translateLanguageSetting
    }
    var translateInfoObservable: Observable<PushTranslateInfo> {
        return self.pushCenter.observable(for: PushTranslateInfo.self)
    }
    var imageTranslateEnable: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable))
    }
    var userGeneralSettings: UserGeneralSettings

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.translateAPI = try resolver.resolve(assert: TranslateAPI.self)
        self.messageAPI = try resolver.resolve(assert: MessageAPI.self)
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)
        self.userGeneralSettings = try resolver.resolve(assert: UserGeneralSettings.self)
        self.pushCenter = try resolver.userPushCenter
    }

    func pushTranslateInfo(info: PushTranslateInfo) {
        self.pushCenter.post(info)
    }
}
