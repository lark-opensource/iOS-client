//
//  SearchTask.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/13.
//

import Foundation

/**
 * native搜索结果记录
 */
class SearchTask {
    var messageText: String = ""
    var isMessageTextParseDone = false
    var isNativeSearch = false
    var messageID = ""
    /// SearchKey: Count
    var searchRetMap = [String: Int]()

    init(msgID: String, isNativeSearch: Bool) {
        self.messageID = msgID
        self.isNativeSearch = isNativeSearch
    }
}
