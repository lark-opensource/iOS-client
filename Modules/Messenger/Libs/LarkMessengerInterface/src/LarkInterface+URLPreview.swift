//
//  LarkInterface+URLPreview.swift
//  LarkMessengerInterface
//
//  Created by 袁平 on 2021/8/4.
//

import UIKit
import Foundation
import RustPB
import TangramService
import LarkModel
import EENavigator

// Inline数据来源
public enum InlineSourceType: Int {
    case sdk = 0
    case server = 1
    case sdkPush = 2
    case memory = 3
}

/// LarkProfile在infra里，通过Interface解依赖
public protocol TextToInlineService {
    typealias Completion = (_ attriubuteText: NSMutableAttributedString,
                            _ urlRangeMap: [NSRange: URL],
                            _ textUrlRangeMap: [NSRange: String],
                            _ sourceType: InlineSourceType) -> Void

    typealias CompleteHandler = (_ attriubuteText: NSMutableAttributedString,
                                 _ urlRangeMap: [NSRange: (URL, InlinePreviewEntity)],
                                 _ textUrlRangeMap: [NSRange: String],
                                 _ sourceType: InlineSourceType) -> Void

    /// 替换文本中链接为Inline，即使命中内存缓存，也会触发SDK数据拉取
    ///
    /// - Parameters:
    ///     - sourceID: chatID或chatterID等
    ///     - sourceText: 目标文本
    ///     - completion: 不保证线程，会回调两次，一次内存缓存数据（相同线程回调），一次从SDK拉取数据（子线程回调）
    func replaceWithInlineTrySDK(sourceID: String,
                                 sourceText: String,
                                 type: Url_V1_UrlPreviewSourceType,
                                 strategy: Basic_V1_SyncDataStrategy,
                                 textColor: UIColor,
                                 linkColor: UIColor,
                                 font: UIFont,
                                 completion: @escaping Completion)

    /// 替换文本中链接为Inline，即使命中内存缓存，也会触发SDK数据拉取, 返回inlineEntity
    ///
    /// - Parameters:
    ///     - sourceID: chatID或chatterID等
    ///     - sourceText: 目标文本
    ///     - completion: 主线程回调；会回调两次，一次内存缓存数据（主线程同步），一次从SDK拉取数据（主线程异步）
    func replaceWithInlineEntityTrySDK(sourceID: String,
                                 sourceText: String,
                                 type: Url_V1_UrlPreviewSourceType,
                                 strategy: Basic_V1_SyncDataStrategy,
                                 textColor: UIColor,
                                 linkColor: UIColor,
                                 font: UIFont,
                                 completion: @escaping CompleteHandler)

    /// Push监听，先存内存缓存之后再回调
    ///
    /// - Parameters:
    ///     - sourceIDs
    func subscribePush(sourceIDHandler: @escaping ([String]) -> Void)

    func trackURLParseClick(sourceID: String,
                            sourceText: String,
                            type: Url_V1_UrlPreviewSourceType,
                            originURL: String,
                            scene: String)

    /// url_preview_sign_inline_render_dev：签名Inline渲染埋点
    ///
    /// - Returns:
    ///     - 是否上报埋点
    @discardableResult
    func trackURLInlineRender(sourceID: String,
                              sourceText: String,
                              type: Url_V1_UrlPreviewSourceType,
                              sourceType: InlineSourceType,
                              scene: String,
                              startTime: CFTimeInterval,
                              endTime: CFTimeInterval,
                              isFromPush: Bool) -> Bool
}

public extension TextToInlineService {
    @discardableResult
    func trackURLInlineRender(sourceID: String,
                              sourceText: String,
                              type: Url_V1_UrlPreviewSourceType,
                              sourceType: InlineSourceType,
                              scene: String,
                              startTime: CFTimeInterval,
                              endTime: CFTimeInterval) -> Bool {
        return trackURLInlineRender(sourceID: sourceID,
                                    sourceText: sourceText,
                                    type: type,
                                    sourceType: sourceType,
                                    scene: scene,
                                    startTime: startTime,
                                    endTime: endTime,
                                    isFromPush: false)
    }
}

public final class URLPreviewSceneContext { //分屏预览URL需要的上下文
    public var url: URL
    public var context: [String: Any]
    public init(url: URL,
                context: [String: Any]) {
        self.url = url
        self.context = context
    }
}
