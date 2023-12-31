//
//  SnapKitDependencyImpl.swift
//  ByteViewMod
//
//  Created by Prontera on 2022/1/28.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import Heimdallr
import LarkFoundation
import LKCommonsTracker
import ByteViewCommon
import LarkSetting
import LarkContainer

class SnapKitDependencyImpl: PreventCrashDependency {
    private static let logger = Logger.getLogger("SnapKit")

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var isFeatureGatingEnable: Bool {
        true
    }

    func trackUserException(_ exceptionType: String, errorType: SnapKitErrorType, logInfo: String) {
        Self.logger.info("snapKit error: trackUserException:\(errorType), logInfo: \(logInfo)")
        // 为了保证Snapkit各种fatalError不会再slardar因为顶堆栈一样而聚类成同一个issue
        // 因此需要删除一定数量的顶堆栈，并加上参数区分
        let skippedDepth: UInt
        let errorTypeString: String
        switch errorType {
        case .noSuperView:
            skippedDepth = 4
            errorTypeString = "noSuperView"
        case .noMatchAttributes:
            skippedDepth = 4
            errorTypeString = "noMatchAttributes"
        case .noExistingConstraint:
            skippedDepth = 5
            errorTypeString = "noExistingConstraint"
        case .noCommonAncestor:
            skippedDepth = 7
            errorTypeString = "noCommonAncestor"
        @unknown default:
            return
        }
        Tracker.post(TeaEvent("vc_snapkit_fatal_error_capture_dev", params: ["type": errorTypeString]))
        HMDUserExceptionTracker.shared().trackAllThreadsLogExceptionType(exceptionType, skippedDepth: skippedDepth, customParams: ["errorType": errorTypeString], filters: nil, callback: { error in
            Self.logger.info("trackUserException Error: \(String(describing: error))")
        })
    }

    var appCanDebug: Bool {
        DebugUtil.isDebug
    }
}
