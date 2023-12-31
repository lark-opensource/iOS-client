//
//  QuitSearchHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/14.
//

import Foundation

/**
 * 场景4：退出搜索的处理
 * 技术文档：https://bytedance.feishu.cn/wiki/wikcnsrBau9PMm8wSRCSteS35pb#
 */
final class QuitSearchHandler {

    private weak var searchViewModel: MailMessageSearchViewModel?

    init(searchViewModel: MailMessageSearchViewModel?) {
        self.searchViewModel = searchViewModel
    }

    func closedSearch() {
        searchViewModel?.callJSFunction("exitSearch")
    }
}
