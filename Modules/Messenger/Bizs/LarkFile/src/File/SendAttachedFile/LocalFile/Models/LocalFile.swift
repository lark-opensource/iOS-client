//
//  LocalFile.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import UIKit
import LarkUIKit
import Foundation
import AVFoundation
import LarkCore
import LarkMessengerInterface
import UniverseDesignIcon

/// 本地沙盒文件
struct LocalFile: AttachedFile {
    let filePath: String
    var id: String {
        return filePath
    }
    let type: AttachedFileType
    let name: String
    let size: Int64
    let videoDuration: TimeInterval?
    let createDate: Date

    let previewImage: () -> UIImage?

    init(type: AttachedFileType, filePath: String, name: String, size: Int64, createDate: Date, videoDuration: TimeInterval?) {
        self.type = type
        self.filePath = filePath
        self.name = name
        self.size = size
        self.createDate = createDate
        self.videoDuration = videoDuration

        var pImage: UIImage?
        self.previewImage = {
            if pImage == nil {
                switch type {
                case .albumVideo:
                    assertionFailure("LocalFile不应该有albumVideo这个类型")
                case .localVideo:
                    let asset = AVURLAsset(url: URL(fileURLWithPath: filePath))
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
                    var actualTime = CMTime.zero
                    let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
                    let defaultIconSize = CGSize(width: 48, height: 48)
                    if cgImage == nil {
                        pImage = UDIcon.getIconByKey(.fileVideoColorful, size: defaultIconSize)
                    } else {
                        pImage = cgImage.flatMap { UIImage(cgImage: $0) }
                    }
                case .PDF, .EXCEL, .WORD, .PPT, .TXT, .MD, .JSON, .HTML, .unkown:
                    pImage = LarkCoreUtils.fileIcon(with: filePath)
                }
            }
            return pImage
        }
    }
}
