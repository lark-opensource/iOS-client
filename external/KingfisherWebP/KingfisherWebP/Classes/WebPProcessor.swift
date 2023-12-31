//
//  WebPProcessor.swift
//  Pods
//
//  Created by yeatse on 2016/10/19.
//
//

import Foundation
import Kingfisher

public struct WebPProcessor: ImageProcessor {

    public static let `default` = WebPProcessor()

    public let identifier: String

    public init(identifier: String = "com.yeatse.WebPProcessor") {
        self.identifier = identifier
    }

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            if data.isWebPFormat {
                return KingfisherWrapper<Image>.image(webpData: data, scale: options.scaleFactor, onlyFirstFrame: options.onlyLoadFirstFrame)
            } else {
                return DefaultImageProcessor.default.process(item: item, options: options)
            }
        }
    }
}

