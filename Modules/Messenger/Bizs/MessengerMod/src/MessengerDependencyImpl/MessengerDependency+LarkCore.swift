//
//  MessengerMockDependency+LarkCore.swift
//  LarkMessenger
//
//  Created by 袁平 on 2020/11/20.
//

import UIKit
import Foundation
import LarkCore
import Swinject
import RxSwift
import SwiftyJSON
import LarkContainer
#if GagetMod
import LarkOPInterface
#endif
#if CCMMod
import SpaceInterface
#endif

public final class LarkCoreDependencyImpl: LarkCoreDependency {
    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func showQuataAlertFromVC(_ vc: UIViewController) {
        #if CCMMod
        (try? self.resolver.resolve(assert: QuotaAlertService.self))?.showQuotaAlert(type: .saveToSpace, from: vc)
        #endif
    }

    public func fetchRawAvatarApplicationList(appVersion: String, accessToken: String) -> Observable<(Int?, JSON)> {
        #if GagetMod
        (try? self.resolver.resolve(assert: OpenPlatformService.self))?.fetchApplicationAvatarList(appVersion: appVersion, accessToken: accessToken) ?? .empty()
        #else
        .empty()
        #endif
    }
}
