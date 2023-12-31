//
//  SetupKVTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2020/10/29.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import BootManager
import AppContainer
import LarkAccountInterface
import LarkFileKit
import Swinject
import RxSwift

final class SetupFileTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupFileTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        FileTrackInfoHandlerRegistry.register(handler: FileHandler())
    }
}

struct FileHandler: FileTrackInfoHandler {
    func track(info: FileTrackInfo) {
        Tracker.post(
            SlardarEvent(name: "default_file_monitor",
                         metric: [
                            "latency": info.duration * 1_000,
                            "size": info.size ?? 0
                         ],
                         category: [
                            "mainThread": info.isMainThread,
                            "operation": info.operation.rawValue
                         ],
                         extra: [
                            "path": info.path.rawValue,
                            "error": info.error?.localizedDescription ?? ""
                         ])
        )
    }
}
