//
//  LaunchGuideAssembly.swift
//  Action
//
//  Created by Miaoqi Wang on 2019/5/23.
//

import Foundation
import Swinject
import LKLaunchGuide
import BootManager
import EENavigator
import LarkAssembler

// swiftlint:disable missing_docs
public enum GuideItemName {
    public static let allInOne: String = "all_in_one"
    public static let vc: String = "video_conference"
    public static let cloud: String = "cloud"
    public static let calendar: String = "calendar"
    public static let platform: String = "open_platform"
}

public final class DefaultLaunchGuideDependencyAssembly: LarkAssemblyInterface {
    public init() {}
}

public final class LaunchGuideAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {
        container.register(LaunchGuideService.self) { _ -> LaunchGuideService in
            return LaunchGuideFactory.create(
                config: LarkLaunchGuideConfig(),
                resolver: container
            )
        }.inObjectScope(.container)
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(LaunchGuideTask.self)
    }
}
// swiftlint:enable missing_docs
