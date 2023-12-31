//
//  TroubleKillerTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import UIKit
import Foundation
import BootManager
import AppContainer
import EETroubleKiller
import Homeric
import LKCommonsTracker
import LarkUIKit

final class TroubleKillerTask: FlowBootTask, Identifiable { // Global
    static var identify = "TroubleKillerTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        self.setupTroubleKiller()
        self.setupWindow(window: context.window)
    }

    func setupTroubleKiller() {
        // start EETroubleKiller
        // TroubleKiller must start fastly before first UI create.
        TroubleKiller.start()
        TroubleKiller.hook.endCaptureHook = {
            Tracker.post(TeaEvent(Homeric.TK_WRITE_CAPTURE_FILE))
        }
    }

    func setupWindow(window: UIWindow?) {
        let tkWindowName = "MainWindow"
        window?.captureName = tkWindowName
        TroubleKiller.registerDefaultWindowName(tkWindowName)
    }
}
