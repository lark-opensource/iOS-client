//
//  ImageCodable.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/22.
//

import Foundation
import UIKit

/// UIImage 包装类，支持 Codable
public struct ImageWrapper: Codable {

    enum StorageError: Error {
        case decodingFailed
        case encodingFailed
    }

    public let image: UIImage

    public enum CodingKeys: String, CodingKey {
        case image
    }

    public init(image: UIImage) {
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        guard let image = UIImage(data: data) else {
            throw StorageError.decodingFailed
        }
        self.image = image
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard let data = image.pngData() else {
            throw StorageError.encodingFailed
        }
        try container.encode(data, forKey: CodingKeys.image)
    }
}
