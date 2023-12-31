//
//  DocSDKAPIImpl.swift
//  Lark
//
//  Created by Yuguo on 2018/8/19.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import SpaceKit
import RxSwift
import SKCommon
import SpaceInterface

class DocSDKAPIImpl: DocSDKAPI {
    private let docSDK: DocsSDK

    init(docSDK: DocsSDK) {
        self.docSDK = docSDK
    }

    func preloadDocFeed(_ url: String, from source: String) {
        self.docSDK.preloadFile(url, from: source)
    }

    func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        return self.docSDK.isSupportURLType(url: url)
    }

    func canOpen(url: String) -> Bool {
        return self.docSDK.canOpen(url)
    }

    func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage> {
        return docSDK.getThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageSize: imageViewSize)
    }

    func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize, forceUpdate: Bool) -> Observable<UIImage> {
        return docSDK.getThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageSize: imageViewSize, forceUpdate: forceUpdate)
    }

    func syncThumbnail(token: String, fileType: Int, completion: @escaping (Error?) -> Void) {
        return docSDK.syncThumbnail(token: token, fileType: fileType, completion: completion)
    }

    func notifyEnterChatPage() {
        docSDK.notifyEnterChatPage()
    }

    func notifyLeaveChatPage() {
        docSDK.notifyLeaveChatPage()
    }
}
