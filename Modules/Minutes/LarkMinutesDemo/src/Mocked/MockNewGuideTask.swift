//
//  MockNewGuideTask.swift
//  Minutes_Example
//
//  Created by lvdaqian on 2021/6/23.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import BootManager
import LarkGuide
import LarkContainer
import LarkFeatureGating
import LKCommonsLogging

class NewSetupGuideTask: FlowBootTask, Identifiable {
    static var identify = "SetupGuideTask"

    @Provider private var guideManager: GuideService
    @Provider private var newGuideManager: NewGuideService
    static let log = Logger.log(NewSetupGuideTask.self, category: "LaunchTask.SetupGuideTask")

    override func execute(_ context: BootContext) {
        // new guide fetch
        newGuideManager.fetchUserGuideInfos(finish: nil)
        // old guide fetch
        guideManager.asyncUpdateProductGuideList()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            if self.newGuideManager.setGuideInfoOfLocalCache(guideKey: "vc_minutes_edit_speaker", canShow: true) {
                Self.log.info("set vc_minutes_edit_speaker success.")
            }
        }


        Self.log.info("[LarkGuide]: fetchUserGuideInfos LaunchTask fetch new & old guide")
    }
}
