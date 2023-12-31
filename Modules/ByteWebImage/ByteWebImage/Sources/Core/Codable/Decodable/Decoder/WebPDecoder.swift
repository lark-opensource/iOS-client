//
//  WebPDecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/25.
//

import Foundation

public enum WebP {

    public final class Decoder: ImageDecoder {

        typealias Res = WebpBridge

        private var webpRes: Res!

        public var config = ImageDecoderConfig()

        public init() {}

        public func preprocess(_ data: Data) throws -> ImageDecoderResource {
            guard let webpRes = WebpBridge(data: data) else {
                throw ImageError(.badImageData, description: "Invalid Image Data")
            }
            return .webP(webpRes)
        }

        public func image(_ res: Resources, at index: Int) throws -> CGImage {
            createWebpBridgeIfNeeded(res)

            return try DispatchImageQueue.sync {
                let downsampleSize: CGSize = config.downsamplePixelSize > 0 ? CGSize(width: config.downsamplePixelSize, height: 1) : .notDownsample
                guard let image = webpRes.copyImage(at: UInt(index), decodeForDisplay: config.forceDecode, cropRect: config.cropRect, downsampleSize: downsampleSize, gifLimitSize: config.limitSize)?.takeRetainedValue() else {
                    throw ImageError.Decoder.invalidIndex(index)
                }
                return image
            }
        }

        public func delay(_ res: Resources, at index: Int) throws -> TimeInterval {
            createWebpBridgeIfNeeded(res)

            var delay = webpRes.frameDelay(at: UInt(index))
            if delay < config.delayMinimum {
                delay = config.delayMinimum
            }
            return delay
        }

        public var supportAnimation: Bool {
            true
        }

        public func imageCount(_ res: Resources) -> Int {
            createWebpBridgeIfNeeded(res)

            return Int(webpRes.imageCount())
        }

        public func loopCount(_ res: Resources) -> Int {
            createWebpBridgeIfNeeded(res)

            return Int(webpRes.loopCount())
        }

        public func pixelSize(_ res: Resources) throws -> CGSize {
            createWebpBridgeIfNeeded(res)

            return webpRes.originSize()
        }

        public func orientation(_ res: Resources) throws -> UIImage.Orientation {
            return .up
        }

        public var imageFileFormat: ImageFileFormat { .webp }

        private func createWebpBridgeIfNeeded(_ resource: Resources) {
            if webpRes == nil, case .webP(let res) = resource {
                webpRes = res
            }
        }
    }
}
