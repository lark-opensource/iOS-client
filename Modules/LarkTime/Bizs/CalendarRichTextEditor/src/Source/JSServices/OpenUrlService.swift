//
//  OpenUrlService.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/11/22.
//

import Foundation

final class OpenUrlService: JSServiceHandler {

    weak var richTextView: DocsRichTextView?

    init(_ richTextView: DocsRichTextView) {
        self.richTextView = richTextView
    }

    var handleServices: [JSService] {
        return [.rtOpenUrl]
    }

//    bridge 传递出来的参数：
//    docInfo: {
//    preText: '',
//    token: 'BmZSdsXcvocnX3xLGB3cI1xgnRd',
//    type: 'docx',
//    restText: '',
//    protocol: 'https',
//    suiteTypeNum: 22,
//    mentionTypeNum: 22,
//    search: '?a=1&b=2',
//    hash: '#333',
//    url: 'https://bytedance.feishu.cn/docx/BmZSdsXcvocnX3xLGB3cI1xgnRd?a=1&b=2#333'
//  }
    func handle(params: [String: Any], serviceName: String) {
        guard let urlString = params["url"] as? String,
              let url = try? URL.forceCreateURL(string: urlString) else {
            return
        }
        let docInfo = params["docInfo"] as? [String: Any]
        self.richTextView?.customHandle?(url, docInfo)
    }
}
