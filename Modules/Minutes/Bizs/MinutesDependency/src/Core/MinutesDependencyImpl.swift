//
//  MinutesDependencyImpl.swift
//  MinutesMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import Minutes
import Swinject
import EENavigator
import LarkContainer


public class MinutesDependencyImpl: MinutesDependency {
    private let userResolver: UserResolver
    
    public let meeting: MinutesMeetingDependency?
    public let docs: MinutesDocsDependency?
    public let messenger: MinutesMessengerDependency?
    public let larkLive: MinutesLarkLiveDependency?
    public let config: MinutesConfigDependency?
    
    public init(resolver: UserResolver) throws {
        self.userResolver = resolver
        #if ByteViewMod
        self.meeting = MinutesMeetingDependencyImpl(resolver: userResolver)
        #endif
        #if CCMMod
        self.docs = try MinutesDocsDependencyImpl(resolver: userResolver)
        #endif
        #if MessengerMod
        self.messenger = MinutesMessengerDependencyImpl(resolver: userResolver)
        #endif
        #if LarkLiveMod
        self.larkLive = MinutesLarkLiveDependencyImpl(resolver: userResolver)
        #endif
        self.config = MinutesConfigDependencyImpl(resolver: userResolver)
    }
    
    public func isShareEnabled() -> Bool {
        if let _ = docs {
            return true
        }
        return false
    }
}
