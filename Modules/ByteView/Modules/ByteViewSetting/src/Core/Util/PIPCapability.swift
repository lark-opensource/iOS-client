//
//  PIPCapability.swift
//  ByteViewSetting
//
//  Created by fakegourmet on 2023/3/9.
//

import Foundation
import AVFoundation
import ByteViewCommon

final class PIPCapability {
    /// 是否存在后台摄像头权限
    /// https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_avfoundation_multitasking-camera-access
    static var isMultiTaskingCameraAccessEnabled: Bool = {
        let hasCapability = Bundle.main.infoDictionary?["HAS_MULTITASKING_CAMERA_ACCESS"] as? Bool ?? false
        if #available(iOS 16.0, *), !hasCapability {
            let session = AVCaptureSession()
            if Thread.isMainThread {
                DispatchQueue.global().async {
                    // 避免主线程释放导致卡死/卡顿
                    _ = session
                }
            }
            return session.isMultitaskingCameraAccessSupported
        } else {
            return hasCapability
        }
    }()
}
