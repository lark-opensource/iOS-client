//
//  ProcedureTracker.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/4/7.
//

import Foundation
import AppReciableSDK
import LKCommonsTracker

class ImageProcessTrackerEvent {
    public var scene: Scene
    public var biz: Biz = .Messenger
    public var success: Int = 1
    public var errorCode: Int = 0 {
        didSet {
            self.success = 0
        }
    }
    public var chatType: TrackInfo.ChatType = .single
    public var imageType: ImageFileFormat = .unknown
    public var inputType: String = ""
    public var contentLength: Int = 0
    public var resourceWidth: Float = 0
    public var resourceHeight: Float = 0
    public var resourceFrames: Int = 1
    public var afterLength: Int = 0
    public var afterWidth: Float = 0
    public var afterHeight: Float = 0
    public let start: TimeInterval
    public var wantToConvert: ImageSourceResult.SourceType = .jpeg

    init(scene: Scene = .Chat) {
        self.scene = scene
        self.start = CACurrentMediaTime()
    }

    public func addSourceParams(input: ImageProcessSourceType) {
        switch input {
        case .image(let image):
            self.inputType = "UIImage"
            self.resourceWidth = Float(image.size.width * image.scale)
            self.resourceHeight = Float(image.size.height * image.scale)
        case .imageData(let data):
            self.contentLength = data.count
            self.inputType = "Data"
            if let image = UIImage(data: data) {
                self.resourceHeight = Float(image.size.height * image.scale)
                self.resourceWidth = Float(image.size.width * image.scale)
            }
        }
    }

    public func addResultParams(result: ImageProcessResult) {
        self.afterLength = result.imageData.count
        self.afterWidth = Float(result.image.size.width * result.image.scale)
        self.afterHeight = Float(result.image.size.height * result.image.scale)
        self.imageType = result.imageType
        if result.imageType == .gif {
            self.resourceFrames = result.imageData.bt.imageCount
        }
    }

    public func toParams() -> [AnyHashable: Any] {
        let params: [AnyHashable: Any] = [
            "scene": scene.rawValue,
            "biz": biz.rawValue,
            "total_cost": (CACurrentMediaTime() - self.start) * 1000,
            "is_success": success,
            "error_code": errorCode,
            "chat_type": chatType.rawValue,
            "image_type": imageType.description,
            "input_type": inputType,
            "resource_content_length": contentLength,
            "resource_width": resourceWidth,
            "resource_height": resourceHeight,
            "resource_frames": resourceFrames,
            "upload_content_length": afterLength,
            "upload_width": afterWidth,
            "upload_height": afterHeight,
            "want_to_convert": wantToConvert.description
        ]
        return params
    }
}

final class ImageProcessTracker {
    static let name = "image_compress_dev"
    static func send(event: ImageProcessTrackerEvent) {
        let params = event.toParams()
        let event = TeaEvent(name, params: params, md5AllowList: [], bizSceneModels: [])
        Tracker.post(event)
    }
}
