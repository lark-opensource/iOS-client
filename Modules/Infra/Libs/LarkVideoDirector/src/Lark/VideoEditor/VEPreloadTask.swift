//
//  VEPreloadTask.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/24.
//

import Foundation
import BootManager
import RunloopTools
import TTVideoEditor
import LKCommonsLogging

final class VEPreloadTask: FlowBootTask, Identifiable {

    static var identify = "VEPreloadTask"

    override var runOnlyOnce: Bool { true }

    override var isLazyTask: Bool { true }

    override var delayScope: Scope? { return .container }

    private static let logger = Logger.log(VEPreloadTask.self)

    override func execute(_ context: BootContext) {
        let start = CACurrentMediaTime()
        VideoEditorManager.shared.setupVideoEditorIfNeeded()
        let setup = CACurrentMediaTime()
        VEPreloadModule.prepareVEContext()
        let preload = CACurrentMediaTime()
        Self.logger.info("time cost: all: \(preload - start)s "
                         + "setupVE: \(setup - start)s "
                         + "preloadVE: \(preload - setup)s")
    }
}
