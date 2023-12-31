//
//  MinutesLarkLiveDependencyImpl.swift
//  MinutesMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import Minutes
import Swinject
import EENavigator
import LarkContainer
import LarkLiveInterface
import RxSwift

public class MinutesLarkLiveDependencyImpl: MinutesLarkLiveDependency {
    private let userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    public var isInLiving: Bool {
        if let service = try? userResolver.resolve(assert: LarkLiveService.self) {
            return service.isLiving()
        }
        return false
    }

    public func stopLiving() {
        if let service = try? userResolver.resolve(assert: LarkLiveService.self) {
            service.startVoip()
        }
    }
}

