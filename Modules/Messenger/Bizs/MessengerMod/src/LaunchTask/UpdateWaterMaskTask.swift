//
//  UpdateWaterMaskTask.swift
//  LarkMessenger
//
//  Created by KT on 2020/7/2.
//

import Foundation
import LarkMessengerInterface
import LarkContainer
import BootManager
import LarkWaterMark

final class NewUpdateWaterMaskTask: UserFlowBootTask, Identifiable {
    static var identify = "UpdateWaterMaskTask"

    @ScopedProvider private var waterMaskService: WaterMarkService?

    override func execute(_ context: BootContext) {
        waterMaskService?.updateUser()
    }
}
