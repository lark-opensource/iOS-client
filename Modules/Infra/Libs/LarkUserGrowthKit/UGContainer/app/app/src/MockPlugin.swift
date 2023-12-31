//
//  MockPlugin.swift
//  UGContainerDev
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation
import UGContainer

class MockPlugin: BasePlugin<MockReachPoint> {
    override init() {
        super.init()
        print("XXXXXXX MockPlugin init")
    }

    override func onShow(reachPointId: String, data: Data) {
        print("XXXXXXX MockPlugin onShow")
        super.onShow(reachPointId: reachPointId, data: data)
    }

    override func onHide(reachPointId: String) {
        print("XXXXXXX MockPlugin onHide")
        super.onHide(reachPointId: reachPointId)
    }
}
