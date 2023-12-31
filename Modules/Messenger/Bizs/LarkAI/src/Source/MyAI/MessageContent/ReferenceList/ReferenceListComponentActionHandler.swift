//
//  ReferenceListComponentActionHandler.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import Foundation
import LKRichView
import LarkMessageBase
import LarkRichTextCore
import LarkMessengerInterface

public protocol ReferenceListActionHanderContext: ViewModelContext {}

class ReferenceListComponentActionHandler<C: ReferenceListActionHanderContext>: ComponentActionHandler<C>, ReferenceListTagAEventDelegate {
    /// 点击了某个文档链接
    public func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?, listView: ReferenceListView) {
        guard let anchor = element as? LKAnchorElement, let href = anchor.href else { return }

        do {
            let url = try URL.forceCreateURL(string: href)
            if let httpUrl = url.lf.toHttpUrl() {
                context.navigator(type: .push, url: httpUrl, params: nil)
            } else {
                assertionFailure()
            }
        } catch {
            MyAIPageServiceImpl.logger.info("my ai tap reference error, error: \(error.localizedDescription), url: \(href)")
        }
    }
}
