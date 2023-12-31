//
//  LauncherQueue.swift
//  Launcher
//
//  Created by nine on 2020/1/2.
//  Copyright © 2020 nine. All rights reserved.
//

import Foundation
import ThreadSafeDataStructure

class LauncherQueue {
    var syncStages: SafeArray<StageNode> = [] + .semaphore
    var asyncStages: SafeArray<AsyncStageNode> = [] + .semaphore
}
