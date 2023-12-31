//
//  CenterStageCapability.swift
//  ByteView
//
//  Created by chentao on 2021/5/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AVFoundation
import ByteViewCommon

final class CenterStageCapability {
    //设备能力是否支持
    private static let deviceCanSupport: Bool = {
        var canSupport = false
        if Display.pad {
            if #available(iOS 14.5, *) {
                let deviceModelNums: DeviceModelNumber = DeviceUtil.modelNumber
                Logger.util.debug("current device model number:\(deviceModelNums)")
                //从 iPad13,4一直到 iPad13,11
                // nolint-next-line: magic number
                if (deviceModelNums.major > 13) || (deviceModelNums.major >= 13 && deviceModelNums.minor >= 4) {
                    canSupport = true
                } else {
                    canSupport = false
                }
            } else {
                canSupport = false
            }
        } else {
            canSupport = false
        }
        return canSupport
    }()

    private let storage: TypedLocalStorage<UserSettingStorageKey>
    init(storage: TypedLocalStorage<UserSettingStorageKey>) {
        self.storage = storage
        Logger.util.debug("center stage isBizAllowed: true, deviceCanSupport:\(CenterStageCapability.deviceCanSupport)")
    }

    var canUse: Bool {
        CenterStageCapability.deviceCanSupport
    }

    var hasOpened: Bool {
        if #available(iOS 14.5, *), CenterStageCapability.deviceCanSupport {
            return AVCaptureDevice.isCenterStageEnabled
        }
        return false
    }

    func start() {
        if #available(iOS 14.5, *), CenterStageCapability.deviceCanSupport {
            Logger.util.debug("start center stage")
            AVCaptureDevice.centerStageControlMode = .app
            AVCaptureDevice.isCenterStageEnabled = true
            Logger.util.debug("after start center stage then current value is \(AVCaptureDevice.isCenterStageEnabled)")
        }
    }

    func stop() {
        if #available(iOS 14.5, *), CenterStageCapability.deviceCanSupport {
            Logger.util.debug("stop center stage")
            AVCaptureDevice.isCenterStageEnabled = false
            Logger.util.debug("after stop center stage then current value is \(AVCaptureDevice.isCenterStageEnabled)")
        }
    }

    //第一期启动，如果没有
    func dealForFirstLaunch() {
        guard CenterStageCapability.deviceCanSupport else {
            return
        }
        // 如果以前没有启动过，则默认开启
        if !storage.bool(forKey: .centerStageUsed) {
            Logger.util.debug("first launch start center stage by default")
            start()
            storage.set(true, forKey: .centerStageUsed)
        }
    }
}
