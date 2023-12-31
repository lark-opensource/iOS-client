//
//  MediaCompressModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/9/12.
//

import Foundation
import Photos
import SKFoundation

// input file data for compress service
public struct MediaFile {
    let asset: PHAsset
    let isVideo: Bool
    var exportPath: SKFilePath?
    let taskID: String = UUID().uuidString
}

// output data struct for compressed video
public struct VideoResult {
    public let exportURL: URL
    public let name: String
    public let fileSize: UInt64
    public let videoSize: CGSize
    public let duraion: Double
    public let taskID: String
}

// output data struct for compressed image
public struct ImageResult {
    public let exportURL: URL
    public let name: String
    public let fileSize: UInt64
    public let imageSize: CGSize
    public let taskID: String
}

// output for media compressed result
public enum MediaResult {
    case image(result: ImageResult)
    case video(result: VideoResult)
}

// compress status
enum DriveCompressStatus {
    case start
    case progress(progress: Double)
    case failed
    case success(result: [MediaResult])
}
