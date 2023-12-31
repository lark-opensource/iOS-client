//
//  RtcDebugger.swift
//  ByteView
//
//  Created by kiri on 2022/10/9.
//

import Foundation

public final class RtcDebugger {
    public static var isOrientationKitEnabled: Bool {
        get { RtcCameraOrientation.isCoreMotionEnabled }
        set { RtcCameraOrientation.isCoreMotionEnabled = newValue }
    }
}
