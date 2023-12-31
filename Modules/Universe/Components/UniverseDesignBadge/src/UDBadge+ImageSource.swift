//
//  UDBadge+ImageSource.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/27.
//

import UIKit
import Foundation

/// icon badge image source
public protocol ImageSource: AnyObject {
    /// placeholder image, when image is nil,
    /// icon badge will try fetch image,
    /// and set placeholder image before image fetched
    var placeHolderImage: UIImage? { get }

    /// image show for icon badge
    var image: UIImage? { get }

    /// fetch remote image
    /// - Parameter onCompletion: fetched result
    func fetchImage(onCompletion: @escaping (Result<UIImage, Error>) -> Void)
}

extension ImageSource {
    /// default placeholder image is nil
    public var placeHolderImage: UIImage? { return nil }

    /// default fetch image will do nothing
    public func fetchImage(onCompletion: @escaping (Result<UIImage, Error>) -> Void) {}
}

extension UIImage: ImageSource {
    /// UIImage will return self
    public var image: UIImage? { return self }
}
