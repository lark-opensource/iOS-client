//
//  EmotionResouceDependency.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/3.
//

import UIKit
import Foundation
import RustPB

public struct AnimationItem {
    public let key: String  // animatin key
    public let path: String // absolute path

    public init(key: String, path: String) {
        self.key = key
        self.path = path
    }
}

/// LarkEmotionResouce内部依赖
public protocol EmotionResouceDependency {
    /// 通过imageKey拉取对应的图片
    func fetchImage(imageKey: String, emojiKey: String, callback: @escaping (UIImage) -> Void)
    /// 从服务端同步资源：指定单个或者全部
    func fetchResouce(key: String?, version: Int32, callback: @escaping ([String: Resouce], Int32) -> Void)
    /// 从服务端同步资源：批量指定
    func fetchResouce(keys: [String], version: Int32, callback: @escaping ([String: Resouce], Int32) -> Void)
}
