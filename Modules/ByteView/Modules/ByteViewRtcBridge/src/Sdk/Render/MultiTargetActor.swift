//
//  MultiTargetActor.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/7/20.
//

import Foundation
import ByteViewCommon
import ByteViewRTCRenderer

protocol MultiTargetActor {
    func performRenderAction(_ action: () -> Void)
}

final class LocalMultiTargetActor: MultiTargetActor {
    @RwAtomic var proxy: RtcActionProxy
    init(proxy: RtcActionProxy) {
        self.proxy = proxy
    }

    func performRenderAction(_ action: () -> Void) {
        proxy.performAction(.render, action: action)
    }
}

final class RemoteMultiTargetActor: MultiTargetActor {
    private let proxy: RtcActionProxy
    init(proxy: RtcActionProxy) {
        self.proxy = proxy
    }

    func performRenderAction(_ action: () -> Void) {
        proxy.performAction(.render, action: action)
    }
}

// disable-lint: magic number
extension UIInterfaceOrientation {
    func toRenderDegree() -> Int? {
        switch self {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return 270
        default:
            return nil
        }
    }
}

extension UIDeviceOrientation {
    func toRenderDegree() -> Int? {
        switch self {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .landscapeLeft:
            return 270
        case .landscapeRight:
            return 90
        default:
            return nil
        }
    }
}
// enable-lint: magic number
