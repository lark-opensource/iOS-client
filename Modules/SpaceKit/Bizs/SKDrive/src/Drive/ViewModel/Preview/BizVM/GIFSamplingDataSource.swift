//
//  DriveGifDataSource.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/12/9.
//
//  Included OSS: SwiftyGif
//  Copyright (c) 2016 Alexis Creuzot
//  spdx license identifier: MIT

import UIKit
import ImageIO
import CoreServices
import SKCommon
import SKFoundation

class GIFSamplingDataSource: GIFDataSource {
    typealias Element = UIImage
    private let maxSize: CGFloat
    private let defaultAvgFramePerSec: Float = 12.0
    private let renderQueue = DispatchQueue(label: "drive.gif.parse")

    private let imageSource: CGImageSource
    private var loop: Bool
    private var displayOrder: [Int] = [] // 采样后的帧索引数组
    private var frameCount: Int = 0 // 采样后的帧数
    private var displayRefreshFactor: Int? // 刷新周期因子，间隔几个周期刷新一帧（一个周期为1/60s）
    private var syncFactor = 0
    private var displayOrderIndex: Int = 0 // 当前播放的帧索引
    private var currentImage: UIImage? // 当前播放的帧
    private var timer: CADisplayLink?

    var renderFrame: ((Result<UIImage, Error>) -> Void)?
    var needDownsample: Bool = false

    init(imageSource: CGImageSource, maxSize: CGFloat, loop: Bool = true) {
        self.imageSource = imageSource
        self.maxSize = maxSize
        self.loop = loop
    }

    func start() {
        do {
           calculateFrameDelay(try delayTimes(imageSource))
        } catch {
            DocsLogger.driveInfo("gif is invalid", error: error)
            self.renderFrame?(Result.failure(error as Error))
            return
        }

        // 获取第一帧
        // 兼容帧数据为空的异常情况，通过for循环找到第一帧数据
        var firstFrame: UIImage? = self.next()
        var i = 0
        while firstFrame == nil && i < frameCount {
            i += 1
            firstFrame = self.next()
        }
        
        guard let first = firstFrame else {
            DocsLogger.driveInfo("Failed to get first frame")
            self.renderFrame?(Result.failure(GIFParseError.noImages))
            return
        }
        self.renderFrame?(Result.success(first))

        if frameCount == 1 || i == frameCount - 1 {
            DocsLogger.driveInfo("gif has only one frame")
            return
        }
        setupTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func setupTimer() {
        guard timer == nil else {
            return
        }
        timer = CADisplayLink(target: self, selector: #selector(updateNextFrame))
        timer?.preferredFramesPerSecond = 60
        timer?.add(to: .main, forMode: .common)
    }

    @objc
    private func updateNextFrame() {
        renderQueue.async {
            guard let nextFrame = self.next() else {
                spaceAssertionFailure("drive.gif.render --- get gif next frame should not failed")
                return
            }
            self.renderFrame?(Result.success(nextFrame))
        }
    }
    
    private func frameAtIndex(_ index: Int) -> UIImage? {
        let options: NSDictionary = [kCGImageSourceShouldCache as String: true,
        kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard index < displayOrder.count else {
                assertionFailure("index out of bounds")
                return nil
        }
        if needDownsample {
            DocsLogger.driveInfo("downsample gif frame")
            let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                     kCGImageSourceThumbnailMaxPixelSize: maxSize,
                                     kCGImageSourceShouldCacheImmediately: true,
                                     kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, index, downsampleOptions) else {
                DocsLogger.error("downsample failed")
                return nil
            }

            return UIImage(cgImage: cgImage)
        } else {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, displayOrder[index], options) else {
                DocsLogger.error("createImage failed", extraInfo: ["index": displayOrder[index]])
                return nil
            }
            return UIImage(cgImage: cgImage)
        }
    }

    private func next() -> Element? {
        updateCurrentImage()
        return currentImage
    }

    private func updateCurrentImage() {
        updateFrameIfNeed()
        updateIndex()
    }

    private func updateFrameIfNeed() {
        guard displayOrderIndex >= 0, displayOrderIndex < displayOrder.count else {
            assertionFailure("index out of bounds")
            return
        }
        if displayOrderIndex == 0, let image = frameAtIndex(displayOrderIndex) {
            self.currentImage = image
        } else {
            if displayOrderIndex > 0, displayOrder[displayOrderIndex] != displayOrder[displayOrderIndex - 1],
                let image = frameAtIndex(displayOrderIndex) {
                self.currentImage = image
            }
        }
    }

    private func updateIndex() {
        guard let refreshFactor = displayRefreshFactor,
            refreshFactor > 0 else {
                return
        }

        syncFactor = (syncFactor + 1) % refreshFactor

        if syncFactor == 0, frameCount > 0 {
            if displayOrderIndex == frameCount - 1 { // 最后一帧
                if loop {
                    displayOrderIndex = 0
                } else {
                    return
                }
            } else {
                displayOrderIndex = (displayOrderIndex + 1) % frameCount
            }
        }
    }

    /// 计算刷新频率和采样后帧数组
    private func calculateFrameDelay(_ delaysArray: [Float]) {
        var delays = delaysArray

        // Factors send to CADisplayLink.frameInterval
        // nolint-next-line: magic number
        let displayRefreshFactors = [60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1]

        // maxFramePerSecond,default is 60
        let maxFramePerSecond = displayRefreshFactors[0]

        // frame numbers per second
        let displayRefreshRates = displayRefreshFactors.map { maxFramePerSecond / $0 }

        // time interval per frame
        let displayRefreshDelayTime = displayRefreshRates.map { 1 / Float($0) }

        // caclulate the time when each frame should be displayed at(start at 0)
        for i in delays.indices.dropFirst() {
            delays[i] += delays[i - 1]
        }

        // 根据当前GIF的平均帧率和给定的最大帧率计算采样完整因子
        // levelOfIntegrity的值为0-1，表示采样帧数为 frameCount * levelOfIntegrity
        var levelOfIntegrity: Float = 1
        if let timeRange = delays.last {
            levelOfIntegrity = defaultAvgFramePerSec / (Float(delays.count) / timeRange)
            DocsLogger.driveInfo("avgframePerSec: \((Float(delays.count) / timeRange))")
            levelOfIntegrity = max(0, min(1, levelOfIntegrity))
        }

        //find the appropriate Factors then BREAK
        for (i, delayTime) in displayRefreshDelayTime.enumerated() {
            let displayPosition = delays.map { Int($0 / delayTime) }
            var frameLoseCount: Float = 0

            for j in displayPosition.indices.dropFirst() where displayPosition[j] == displayPosition[j - 1] {
                frameLoseCount += 1
            }

            if displayPosition.first == 0 {
                frameLoseCount += 1
            }

            if frameLoseCount <= Float(displayPosition.count) * (1 - levelOfIntegrity) || i == displayRefreshDelayTime.count - 1 {
                frameCount = displayPosition.last ?? 0
                displayRefreshFactor = displayRefreshFactors[i]
                displayOrder = []
                var oldIndex = 0
                var newIndex = 1

                while newIndex <= frameCount && oldIndex < displayPosition.count {
                    if newIndex <= displayPosition[oldIndex] {
                        displayOrder.append(oldIndex)
                        newIndex += 1
                    } else {
                        oldIndex += 1
                    }
                }
                break
            }
        }
    }

    /// 获取GIF帧间隔数组
    private func delayTimes(_ imageSource: CGImageSource) throws -> [Float] {
        let frameCount = CGImageSourceGetCount(imageSource)

        guard frameCount > 0 else {
            throw GIFParseError.noImages
        }

        var imageProperties = [NSDictionary]()

        for i in 0..<frameCount {
            if let dict = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as NSDictionary? {
                imageProperties.append(dict)
            } else {
                throw GIFParseError.noProperties
            }
        }

        let EPS: Float = 1e-6

        let frameDelays: [Float] = try imageProperties.map { properties in
            guard let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? NSDictionary else {
                throw GIFParseError.noGifDictionary
            }

            let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
            let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber

            if let value = unclampedDelayTime?.floatValue, value >= EPS {
                return value
            }

            if let value = delayTime?.floatValue {
                return value
            }
            throw GIFParseError.noTimingInfo
        }
        return frameDelays
    }

}
