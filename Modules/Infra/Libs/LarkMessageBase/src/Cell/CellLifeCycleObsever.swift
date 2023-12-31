//
//  CellLifeCycleObsever.swift
//  LarkMessageBase
//
//  Created by zc09v on 2022/4/28.
//

import Foundation
import LarkModel
import RustPB

open class CellLifeCycleObseverRegister {
    public let obsevers: [CellLifeCycleObsever]
    public init(obsevers: [CellLifeCycleObsever]) {
        self.obsevers = obsevers
    }
}

public protocol CellLifeCycleObsever {
    func initialized(metaModel: CellMetaModel, context: PageContext)
    func willDisplay(metaModel: CellMetaModel, context: PageContext)
}

public extension CellLifeCycleObsever {
    func initialized(metaModel: CellMetaModel, context: PageContext) {}
    func willDisplay(metaModel: CellMetaModel, context: PageContext) {}
}

public extension Message {
    //获取text/post消息中有效的可点击链接
    public func getTextPostEnableUrls() -> [String] {
        var richText: Basic_V1_RichText?
        if self.type == .text, let content = self.content as? TextContent {
          richText = content.richText
        } else if self.type == .post, let content = self.content as? PostContent {
          richText = content.richText
        }
        guard let richText = richText else { return [] }
        var urls = Set<String>()
        richText.elements.forEach { _, element in
          if element.tag == .a, !element.property.anchor.href.isEmpty {
            urls.insert(element.property.anchor.href)
          } else if element.tag == .link, !element.property.link.url.isEmpty {
            urls.insert(element.property.link.url)
          }
        }
        return Array(urls)
    }
}
