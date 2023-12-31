//
//  UGDialogFetchTask.swift
//  LarkTour
//
//  Created by aslan on 2022/1/13.
//

import Foundation
import BootManager
import LarkContainer

final class UGDialogFetchTask: UserFlowBootTask, Identifiable {
    static var identify = "UGDialogFetchTask"

    override var scheduler: Scheduler { return .concurrent }
    @ScopedProvider private var dialogManager: SwitchTabDialogManager?

    override func execute(_ context: BootContext) {
        dialogManager?.excute()
    }
}
