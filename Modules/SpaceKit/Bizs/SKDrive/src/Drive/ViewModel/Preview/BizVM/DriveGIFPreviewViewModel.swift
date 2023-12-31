//
//  DriveGIFPreviewViewModel.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/11/28.
//  swiftlint:disable nesting

import UIKit
import CoreServices
import SKCommon
import SKFoundation
import SKUIKit
import ByteWebImage

protocol DriveGIFRenderDelegate: AnyObject {
    func updateFrame(newFrame: UIImage)
    func renderFailed()
    func fileUnsupport(reason: DriveUnsupportPreviewType)
}


class DriveGIFPreviewViewModel: NSObject {
    private let fileURL: SKFilePath
    private let renderQueue = DispatchQueue(label: "drive.gif.render")
    private var imageDataSource: GIFDataSource?
    weak var renderDelegate: DriveGIFRenderDelegate?

    init(fileURL: SKFilePath) {
        self.fileURL = fileURL
    }

    func loadContent() {
        renderQueue.async {
            self.parseContent()
        }
    }

    func stop() {
        imageDataSource?.stop()
    }

    private func parseContent() {
        guard let data = try? Data.read(from: fileURL) else {
            DocsLogger.driveInfo("Failed to load gif data.")
            renderFailed()
            return
        }
        
        guard !checkIfSizeOverLimited(imageData: data) else {
            DocsLogger.driveInfo("gif file over size")
            fileUnsupport()
            return
        }
        if UserScopeNoChangeFG.TYP.DriveIMImageEable {
            guard let image = try? ByteImage(data) else {
                fileUnsupport()
                return
            }
            updateFrame(image)
        } else {
            let options: [String: Any] = [kCGImageSourceShouldCache as String: true,
                                          kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
                DocsLogger.driveInfo("Failed to create gif image source.")
                renderFailed()
                return
            }
            let screenSize = SKDisplay.mainScreenBounds.size
            let dataSource = GIFSamplingDataSource(imageSource: imageSource, maxSize: max(screenSize.width, screenSize.height))
            dataSource.needDownsample = imageOverSize(imageData: data)
            dataSource.renderFrame = {[weak self] result in
                guard let self = self else { return }
                guard case let .success(image) = result else {
                    self.handleParseError(imageData: data)
                    return
                }
                self.updateFrame(image)
            }
            dataSource.start()
            self.imageDataSource = dataSource
        }
    }

    private func handleParseError(imageData: Data) {
        guard let image = UIImage(data: imageData) else {
            DocsLogger.driveInfo("invalid gif, load static image faled")
            self.renderFailed()
            return
        }
        self.updateFrame(image)
    }

    private func updateFrame(_ frame: UIImage) {
        DispatchQueue.main.async {
            self.renderDelegate?.updateFrame(newFrame: frame)
        }
    }

    private func renderFailed() {
        DispatchQueue.main.async {
            self.renderDelegate?.renderFailed()
        }
    }
    
    private func fileUnsupport() {
        DispatchQueue.main.async {
            self.renderDelegate?.fileUnsupport(reason: .sizeTooBig)
        }
    }
    private func checkIfSizeOverLimited(imageData: Data) -> Bool {
        // 单帧gif可以通过downsample降低内存，可以不限制大小， 多帧并且size超大验证通过downsample无法降低内存，没有找到好的方法
        return imageOverSize(imageData: imageData) && imageData.bt.imageCount > 1
    }
    
    private func imageOverSize(imageData: Data) -> Bool {
        let screenSize = SKDisplay.mainScreenBounds.size
        let scale = SKDisplay.scale
        // 每一帧最大分辨率为设备分辨率的4倍，目前最大的设备iPad Pro一帧解码后占用内存为 85M
        let maxResolutin = screenSize.width * scale * screenSize.height * scale * 4
        let resolustion = imageData.bt.imageSize.height * imageData.bt.imageSize.width
        return resolustion > maxResolutin
    }
}

extension Data {
    var resolustion: CGFloat {
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any],
            let imageHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat,
            let imageWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat else {
            DocsLogger.driveInfo("get image size from data failed")
            return 0.0
        }
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        return imageSize.width * imageSize.height
    }
    
    var frameCount: Int {
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            DocsLogger.driveInfo("get imagesource from data failed")
            return Int.max
        }
        let frameCount = CGImageSourceGetCount(imageSource)
        return frameCount
    }
}
