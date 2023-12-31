//
//  SetupGuideTask.swift
//  LarkMessenger
//
//  Created by zhenning on 2020/08/27.
//

import Foundation
import BootManager
import LarkGuide
import LarkContainer
import LarkFeatureGating
import LKCommonsLogging

final class NewSetupGuideTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupGuideTask"

    @ScopedProvider private var guideManager: GuideService?
    @ScopedProvider private var newGuideManager: NewGuideService?
    static let log = Logger.log(NewSetupGuideTask.self, category: "LaunchTask.SetupGuideTask")

    override func execute(_ context: BootContext) {
        // new guide fetch
        newGuideManager?.fetchUserGuideInfos(finish: nil)
        // old guide fetch
        guideManager?.asyncUpdateProductGuideList()
        Self.log.info("[LarkGuide]: fetchUserGuideInfos LaunchTask fetch new & old guide")
    }
}
