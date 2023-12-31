//
//  MediaCompressDependency.swift
//  SKCommon
//
//  Created by tanyunpeng on 2022/10/10.
//  

import Photos
import UIKit
import Foundation

/// dependency struct and protocols
public typealias TaskID = String
public struct CompressImageResult {
    public let image: UIImage?
    public let data: Data?
    public let taskID: TaskID
    public init(image: UIImage?, data: Data?, taskID: TaskID) {
        self.image = image
        self.data = data
        self.taskID = taskID
    }
}

public struct DriveVideoParseInfo {
    public let originPath: URL
    public let exportPath: URL
    public let videoSize: CGSize
    public init(originPath: URL, exportPath: URL, videoSize: CGSize) {
        self.originPath = originPath
        self.exportPath = exportPath
        self.videoSize = videoSize
    }
}

public enum CompressVideoStatus {
    case success(taskID: TaskID)
    case progress(progress: Double, taskID: TaskID)
    case failed(msg: String, taskID: TaskID)

}

public protocol MediaCompressDependency {
    func compressImage(asset: PHAsset, taskID: TaskID, complete: @escaping (CompressImageResult) -> Void)
    func compressVideo(videoParseInfo: DriveVideoParseInfo, taskID: TaskID, complete: @escaping (CompressVideoStatus) -> Void)
    func cancelCompress(taskIDs: [String])
}
