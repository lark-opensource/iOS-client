//
//  RichTextDarkModePreProcessor.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2021/5/29.
//

import Foundation
import RustPB
import LarkModel
import LarkZoomable
import RichLabel
import LKCommonsLogging

public final class StructWrapper<T>: NSObject {
    public let content: T
    public init(_ _struct: T) {
        self.content = _struct
    }
}
public protocol StyleCache {
    func cacheStyle(key: String, style: [String: String])
    func styleForKey(key: String) -> [String : String]?
}

private let logger = Logger.log(LDContext.self, category: "LarkNewDynamic.LDComponent")
public final class RichTextDarkModePreProcessor {
    private let cardVersion: Int
    private let cardStyle: [String: Any]?
    private let styleCache: StyleCache
    public init(cardVersion: Int, cardStyle: [String: Any]?, styleCache: StyleCache) {
        self.cardVersion = cardVersion
        self.cardStyle = cardStyle
        self.styleCache = styleCache
    }
    
    public func richTextApplyDarkMode(originRichText: RichText) -> RichText {
        guard cardVersion >= 2 else {
            logger.warn("V1 card not process")
            return originRichText
        }
        guard let style = cardStyle else {
            logger.warn("message card style is nil")
            return originRichText
        }
        guard let narrow = style[KeyStylePreProcessor.keyNarrow] as? [String: Any],
              let wide = style[KeyStylePreProcessor.keyWide] as? [String: Any],
              let narrowStyle = narrow[KeyStylePreProcessor.keyStyle] as? [String: [String: String]],
              let wideStyle = wide[KeyStylePreProcessor.keyStyle] as? [String: [String: String]] else {
            logger.warn("message card style is not valid")
            return originRichText
        }
        logger.info("richTextApplyDarkMode narrow version: \(narrow[KeyStylePreProcessor.keyVersion]), wide version: \(wide[KeyStylePreProcessor.keyVersion])")
        var resultRichText = originRichText
        for (elementId, element) in originRichText.elements {
            var narrowDarkStyleResult: [String: String] = [:]
            var wideDarkStyleResult: [String: String] = [:]
            let joinKey = element.styleKeys.joined(separator: "_Key_")
            let narrowCacheKey = KeyStylePreProcessor.keyNarrow + joinKey
            let wideCacheKey = KeyStylePreProcessor.keyWide + joinKey
            if let narrowDarkCacheStyle = styleCache.styleForKey(key: narrowCacheKey),
               let wideDarkCacheStyle = styleCache.styleForKey(key: wideCacheKey) {
                /// cache
                resultRichText.elements[elementId]?.style = narrowDarkCacheStyle
                resultRichText.elements[elementId]?.wideStyle = wideDarkCacheStyle
            } else {
                for key in element.styleKeys {
                    if let narrowDarkStyle = narrowStyle[key] {
                        narrowDarkStyleResult.merge(narrowDarkStyle, uniquingKeysWith: { (_, right) -> String in
                            return right
                        })
                    }
                    if let wideDarkStyle = wideStyle[key] {
                        wideDarkStyleResult.merge(wideDarkStyle, uniquingKeysWith: { (_, right) -> String in
                            return right
                        })
                    }
                }
                /// 一些复合的元素在本地生成的style是没有stylekey的，这个时候，不需要变更这个style
                if !narrowDarkStyleResult.isEmpty {
                    resultRichText.elements[elementId]?.style = narrowDarkStyleResult
                    styleCache.cacheStyle(key: KeyStylePreProcessor.keyNarrow + joinKey,
                                          style: narrowDarkStyleResult)
                }
                if !wideDarkStyleResult.isEmpty {
                    resultRichText.elements[elementId]?.wideStyle = wideDarkStyleResult
                    styleCache.cacheStyle(key: KeyStylePreProcessor.keyWide + joinKey,
                                          style: wideDarkStyleResult)
                }
            }
            /// patch Image element aspectRatio property
            if element.tag == .img {
                detailLog.info("patch Image element aspectRatio property")
                let aspectRatioKey = KeyStylePreProcessor.keyAspectRatio
                if let aspectRatioValue = element.style[aspectRatioKey] {
                    resultRichText.elements[elementId]?.style[aspectRatioKey] = aspectRatioValue
                    resultRichText.elements[elementId]?.wideStyle[aspectRatioKey] = aspectRatioValue
                    detailLog.info("patch Image element aspectRatio property \(aspectRatioValue)")
                }
            }
        }
        /// 染色日志输出所有节点的样式信息
        if detailLog.enableColorLog() {
            for (elementId, element) in originRichText.elements {
                let oldStyle = "origin element style \(elementId) \(element.style) \(element.styleKeys) \(element.wideStyle) \(element.tag) \(element.childIds)"
                var newStyle = "none"
                if let newElement = resultRichText.elements[elementId] {
                    newStyle = "new element style \(elementId) \(newElement.style) \(newElement.styleKeys) \(newElement.wideStyle) \(newElement.tag) \(element.childIds)"
                }
                detailLog.info("\(oldStyle) \n \(newStyle)")
            }
        }
        return resultRichText
    }
}

