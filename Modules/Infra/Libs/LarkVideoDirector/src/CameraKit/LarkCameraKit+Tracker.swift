//
//  LarkCameraKit+Tracker.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/8/17.
//

import Foundation
import LarkStorage
import AVFoundation
import LKCommonsTracker

internal enum CameraTracker {
    enum CameraType: String {
        case lark, ve, system
    }
    private static let resultTrackerName = "camera_result_dev"

    static func didTakePhoto(from camera: CameraType, image: UIImage, with lensName: String?) {
        var params: [String: Any] = [
            "camera": camera.rawValue,
            "type": "image",
            "resolution": "\(image.size.width * image.scale)*\(image.size.height * image.scale)"
        ]
        if let lensName {
            params["primary_lens"] = lensName
        }
        LarkCameraKit.logger.debug("\(resultTrackerName) \(params)")
        Tracker.post(TeaEvent(resultTrackerName, params: params))
    }

    static func didRecordVideo(from camera: CameraType, url: URL) {
        let start = CACurrentMediaTime()
        let asset = AVURLAsset(url: url)
        let time = asset.duration
        let duration = (Double(time.value) / Double(time.timescale)).rounded()
        var resolution: String?
        if let track = asset.tracks(withMediaType: .video).first {
            let naturalSize = track.naturalSize
            resolution = "\(naturalSize.width)*\(naturalSize.height)"
        }
        var fileSize: NSNumber?
        let absPath = url.asAbsPath()
        if let size = absPath.fileSize {
            fileSize = NSNumber(value: size)
        }
        var params: [String: Any] = [
            "camera": camera.rawValue,
            "type": "video",
            "duration": duration
        ]
        if let resolution {
            params["resolution"] = resolution
        }
        if let fileSize {
            params["size"] = fileSize
        }
        let extraCost = CACurrentMediaTime() - start
        LarkCameraKit.logger.debug("\(resultTrackerName) \(params), extra video info cost: \(extraCost)s")
        Tracker.post(TeaEvent(resultTrackerName, params: params))
    }
}

