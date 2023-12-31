//
//  RichTextNonWideStylePreProcessor.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2021/6/10.
//

import Foundation
import RustPB
import LarkModel
import LarkZoomable
import RichLabel

struct KeyStylePreProcessor {
    static let keyNarrow = "narrow"
    static let keyWide = "wide"
    static let keyStyle = "style"
    static let keyAspectRatio = "aspectRatio"
    static let keyVersion = "version"
    static let keyWidth = "width"
    static let keyMinWidth = "minWidth"
}

class RichTextNonWideStylePreProcessor {
    private let context: LDContext?
    private let originRichText: RichText

    init(context: LDContext?, richText: RichText) {
        self.context = context
        self.originRichText = richText
    }
    /// wide style是否全部为空
    func hasNoWideStyle() -> Bool {
        #if DEBUG
        return true
        #endif
        if originRichText.elements.isEmpty {
            return false
        }
        for (_, element) in originRichText.elements {
            if element.wideStyle.isEmpty {
                continue
            } else {
                /// wide style exist
                return false
            }
        }
        return true
    }
    /// 本地添加宽版信息
    func richTextApplyWideStyle() -> RichText {
        guard hasNoWideStyle() else {
            return originRichText
        }
        /// V1 卡片不做处理
        guard let context = context,
              context.cardVersion >= 2 else {
            return originRichText
        }
        guard let style = context.messageCardStyle(),
              let narrow = style[KeyStylePreProcessor.keyNarrow] as? [String: Any],
              let wide = style[KeyStylePreProcessor.keyWide] as? [String: Any],
              let narrowStyle = narrow[KeyStylePreProcessor.keyStyle] as? [String: [String: String]],
              let wideStyle = wide[KeyStylePreProcessor.keyStyle] as? [String: [String: String]] else {
            return originRichText
        }
        var resultRichText = originRichText
        for (elementId, element) in originRichText.elements {
            var wideDarkStyleResult: [String: String] = [:]
            for key in element.styleKeys {
                if let wideDarkStyle = wideStyle[key] {
                    wideDarkStyleResult.merge(wideDarkStyle, uniquingKeysWith: { (_, right) -> String in
                        return right
                    })
                }
            }
            if !wideDarkStyleResult.isEmpty {
                resultRichText.elements[elementId]?.wideStyle = wideDarkStyleResult
            }
            /// patch Image element aspectRatio property
            if element.tag == .img {
                let aspectRatioKey = KeyStylePreProcessor.keyAspectRatio
                if let aspectRatioValue = element.style[aspectRatioKey] {
                    resultRichText.elements[elementId]?.wideStyle[aspectRatioKey] = aspectRatioValue
                }
            }
        }
        return resultRichText
    }
}
