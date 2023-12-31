//
//  CommentCommonDefines.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/10/9.
//

import Foundation
import SKFoundation
import UIKit
import SpaceInterface

protocol CommentImagesEventProtocol: NSObjectProtocol {
    func didClickPreviewImage(imageInfo: CommentImageInfo)
    func loadImagefailed(item: CommentItem?, imageInfo: CommentImageInfo)
}


extension CommentImageInfo: CommentImageCacheable {
    var cacheKey: String { src }
}
