//
//  LibHEIFDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2023/3/7.
//

import Foundation

public protocol LibHEIFDecoder: ImageDecoder {}

extension HEICBridge: ImageExternSource {}

extension LibHEIFDecoder {

    public func preprocess(_ data: Data) throws -> ImageDecoderResource {
        guard let res = HEICBridge(data: data) else {
            throw ImageError(.badImageData, description: "Invalid Image Data")
        }

        return .extern(res)
    }

    public func image(_ res: Resources, at index: Int) throws -> CGImage {
        let bridge = try createBridgeIfNeeded(res)

        return try DispatchImageQueue.sync {
            let downsampleSize: CGSize = config.downsamplePixelSize > 0
                ? CGSize(width: config.downsamplePixelSize, height: 1)
                : .notDownsample
            if config.cropRect != .zero {
                var orientatedImageRect = CGRect(origin: .zero, size: bridge.originSize())
                if [.right, .left, .rightMirrored, .leftMirrored].contains(bridge.imageOrientation()) {
                    (orientatedImageRect.size.width, orientatedImageRect.size.height) =
                    (orientatedImageRect.size.height, orientatedImageRect.size.width)
                }
                let validCropRect = config.cropRect.integral.intersection(orientatedImageRect)
                config.cropRect = validCropRect
            }
            guard let image = bridge.copyImage(at: index,
                                               decodeForDisplay: config.forceDecode,
                                               cropRect: config.cropRect,
                                               downsampleSize: downsampleSize,
                                               limitSize: config.limitSize) else {
                throw ImageError.Decoder.invalidIndex(index)
            }
            return image
        }
    }

    public func delay(_ res: Resources, at index: Int) throws -> TimeInterval {
        let bridge = try createBridgeIfNeeded(res)

        var delay = bridge.frameDelay(at: index)
        if delay < config.delayMinimum {
            delay = config.delayMinimum
        }
        return delay
    }

    public var supportAnimation: Bool {
        true
    }

    public func imageCount(_ res: Resources) -> Int {
        let bridge = try? createBridgeIfNeeded(res)

        return bridge?.imageCount() ?? 0
    }

    public func loopCount(_ res: Resources) -> Int {
        let bridge = try? createBridgeIfNeeded(res)

        return bridge?.loopCount() ?? 0
    }

    public func pixelSize(_ res: Resources) throws -> CGSize {
        let bridge = try createBridgeIfNeeded(res)

        return bridge.originSize()
    }

    public func orientation(_ res: Resources) throws -> UIImage.Orientation {
        let bridge = try createBridgeIfNeeded(res)

        return ImageDecoderUtils.imageOrientation(from: bridge.imageOrientation())
    }

    private func createBridgeIfNeeded(_ resource: Resources) throws -> HEICBridge {
        guard case .extern(let source) = resource,
              let bridge = source as? HEICBridge else {
            throw ImageError(.badImageData, description: "Invalid Image Data")
        }
        return bridge
    }
}
