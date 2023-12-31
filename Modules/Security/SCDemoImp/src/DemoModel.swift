//
//  DemoSection.swift
//  SCDemo
//
//  Created by qingchun on 2022/9/16.
//

import UIKit
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import EENavigator
import LarkDebug
import LarkUIKit
import SecurityComplianceDebug

let customEntrance = SCDebugModel(cellTitle: "高级调试", cellType: .normal, normalHandler: {
    guard let vc = LayoutConfig.currentWindow?.rootViewController else { return }
    Navigator.shared.present( // Global
        body: DebugBody(),
        wrap: LkNavigationController.self,
        from: vc,
        prepare: { $0.modalPresentationStyle = .fullScreen }
    )
})
