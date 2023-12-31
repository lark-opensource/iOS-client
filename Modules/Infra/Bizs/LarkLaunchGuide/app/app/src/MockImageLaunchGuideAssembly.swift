//
//  MockImageLaunchGuideAssembly.swift
//  LarkLaunchGuideDev
//
//  Created by Miaoqi Wang on 2020/4/2.
//

import UIKit
import Foundation
import LKLaunchGuide
import Swinject

class MockImageLaunchGuideAssembly: Assembly {
    func assemble(container: Container) {
        let resolver = container.synchronize()
        container.register(LaunchGuideService.self) { (_) -> LaunchGuideService in
            return LaunchGuideFactory.create(
                config: MockImageLaunchGuideConfig(),
                resolver: resolver
            )
        }
    }
}

class MockImageLaunchGuideConfig: LaunchGuideConfigProtocol {
    var guideViewItems: [LaunchGuideViewItem] {
        let item = LaunchGuideViewItem(
            title: "Test Image Resource",
            description: "This is a test image resource.\nShow how image resource will be layouted\nAnd xxxxx",
            imageResource: .image(UIImage(named: "launch_guide_team_x")!)
        )
        return [item, item, item]
    }
}
