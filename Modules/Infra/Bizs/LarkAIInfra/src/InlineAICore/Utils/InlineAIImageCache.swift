//
//  InlineAIImageCache.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/6/20.
//  


import UIKit

class InlineAIImageCache {

    typealias ImageInfo = (image: UIImage?, success: Bool)

    var imageDownloadCache: [String: ImageInfo] = [:]
}
