//
//  DocSDKAPI.swift
//  Lark
//
//  Created by Yuguo on 2018/8/19.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

public typealias DocSDKAPIProvider = () -> DocSDKAPI

public protocol DocSDKAPI {
    func preloadDocFeed(_ url: String, from source: String)

    func isSupportURLType(url: URL) -> (Bool, type: String, token: String)

    func canOpen(url: String) -> Bool

    func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage>

    func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize, forceUpdate: Bool) -> Observable<UIImage>

    func syncThumbnail(token: String, fileType: Int, completion: @escaping (Error?) -> Void)

    func notifyEnterChatPage()

    func notifyLeaveChatPage()
}
