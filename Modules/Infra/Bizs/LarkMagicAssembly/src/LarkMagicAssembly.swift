//
//  FeelGoodAssembly.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/10/19.
//

import Foundation
import Swinject
import BootManager
import LarkRustClient
import LarkAccountInterface
import LarkLocalizations
import LarkMagic
#if canImport(ByteViewInterface)
import ByteViewInterface
#endif
#if canImport(LarkGuide)
import LarkGuide
#endif
import LarkAssembler

public final class LarkMagicAssembly: LarkAssemblyInterface {
    public init() {}

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        MagicAssembly()
    }

    public func registContainer(container: Container) {
        container.register(LarkMagicDependency.self) { r -> LarkMagicDependency in
            return LarkMagicDependencyImpl(resolver: r)
        }
    }
}

final class LarkMagicDependencyImpl: LarkMagicDependency {

    let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func checkConflict() -> (isConflict: Bool, extra: [String: String]) {
        var isInMeeting = false
#if canImport(ByteViewInterface)
        isInMeeting = (try? resolver.resolve(assert: MeetingService.self))?.currentMeeting?.isActive == true
#endif
        var isGuideShowing = false
#if canImport(LarkGuide)
        isGuideShowing = resolver.resolve(NewGuideService.self)?.checkIsCurrentGuideShowing() ?? false
#endif
        let isConflict = isInMeeting || isGuideShowing
        let extra = [
            "isInMeeting": "\(isInMeeting)",
            "isGuideShowing": "\(isGuideShowing)"
        ]
        return (isConflict, extra)
    }
}
