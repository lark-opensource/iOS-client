//
//  SetupKeyboardTask.swift
//  SpaceDemo
//
//  Created by bupozhuang on 2020/9/16.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import BootManager
import LarkContainer
import LarkKeyboardKit

class SetupKeyboardTask: FlowBootTask, Identifiable {
    static var identify = "SetupKeyboardTask"

    override func execute(_ context: BootContext) {
        // start keyboard kit observe
        KeyboardKit.shared.start()
    }
}
