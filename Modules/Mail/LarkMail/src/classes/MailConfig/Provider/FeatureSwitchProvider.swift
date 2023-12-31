//
//  File.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/7/19.
//

import Foundation
import MailSDK
import Swinject
import LarkFeatureGating
import RxSwift
import LarkSetting
import LarkContainer

class FeatureSwitchProvider: MailSDK.FeatureSwitchProxy {
    private let resolver: UserResolver
    private let featureGatingService: FeatureGatingService

    init(resolver: UserResolver) throws {
        self.resolver = resolver
        self.featureGatingService = try resolver.resolve(assert: FeatureGatingService.self)
    }

    func getFeatureBoolValue(for key: String) -> Bool {
        return featureGatingService.staticFeatureGatingValue(with: .init(stringLiteral: key))
    }

    func getFeatureBoolValue(for key: MailSDK.FeatureGatingKey) -> Bool {
        return featureGatingService.staticFeatureGatingValue(with: .init(stringLiteral: key.rawValue))
    }

    func getRealTimeFeatureBoolValue(for key: MailSDK.FeatureGatingKey) -> Bool {
        return featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: key.rawValue))
    }

    func getFeatureNotify() -> Observable<Void> {
        /// TODO: 用户隔离服务还不支持监听，支持后再改造
        return FeatureGatingManager.shared.fgObservable
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
    }
}
