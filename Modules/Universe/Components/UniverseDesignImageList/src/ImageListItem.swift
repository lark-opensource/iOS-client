//
//  ImageListItem.swift
//  UniverseDesignImageList
//
//  Created by 郭怡然 on 2022/9/9.
//

import UIKit
import Foundation

public class ImageListItem {

    public enum Status {
        case inProgress(progressValue: CGFloat)
        case error(message: Error?)
        case success
        case initial
    }

    public var id: String = UUID().uuidString

    var image: UIImage?

    public var status: Status

    /// init一个图片
    /// - Parameters:
    ///   - image:图片
    ///   - status:状态
    public init(image: UIImage?, status: Status) {
        self.image = image
        self.status = status
    }

    func updateLoading(value: CGFloat) {
        self.status = .inProgress(progressValue: value)
    }
}
