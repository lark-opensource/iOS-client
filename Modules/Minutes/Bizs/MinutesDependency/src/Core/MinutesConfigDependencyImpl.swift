//
//  MinutesConfigDependencyImpl.swift
//  MinutesMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import Minutes
import Swinject
import EENavigator
import LarkContainer
import LarkKAFeatureSwitch
import LarkSDKInterface
import RustPB
import RxSwift

public class MinutesConfigDependencyImpl: MinutesConfigDependency {
    private let userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    public func getUserAgreementURL() -> URL? {
        if let string = FeatureSwitch.share.config(for: .suiteSoftwareUserAgreementLink).first, let url = URL(string: string) {
            return url
        }
        let userAppConfig = try? userResolver.resolve(assert: UserAppConfig.self)
        if let str = userAppConfig?.resourceAddrWithLanguage(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpUserAgreement) {
            return URL(string: str)
        }
        return nil
    }
}

