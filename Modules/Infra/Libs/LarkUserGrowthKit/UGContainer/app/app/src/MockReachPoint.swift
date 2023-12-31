//
//  File.swift
//  UGContainerDev
//
//  Created by mochangxing on 2021/1/26.
//

import Foundation
import UGContainer
import ServerPB

protocol MockReachPointDelegate: class {
    func onShow(data: ServerPB_Guide_SetBannerStatusRequest) -> Bool
    func onHide() -> Bool
}

class MockReachPoint: BasePBReachPoint, Identifiable {
    weak var delegate: MockReachPointDelegate?
    typealias ReachPointModel = ServerPB_Guide_SetBannerStatusRequest
    static var reachPointType: ReachPointType = "MockReachPoint"
    var data: ServerPB_Guide_SetBannerStatusRequest?

    required init() {}

    func onCreate() {
        print("XXXXXXX MockReachPoint onCreate")
    }

    func onShow() -> Bool {
        print("XXXXXXX MockReachPoint onShow")
        guard let data = data else {
            return false
        }

        return delegate?.onShow(data: data) ?? false
    }

    func onHide() -> Bool {
        print("XXXXXXX MockReachPoint onHide")
        return delegate?.onHide() ?? false
    }

    func onUpdateData(data: ServerPB_Guide_SetBannerStatusRequest) {
        self.data = data
    }
}
