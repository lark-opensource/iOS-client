//
//  FileData.swift
//  FileResource
//
//  Created by weidong fu on 24/1/2018.
//

import Foundation
import SwiftyJSON
import SKFoundation

public struct PagingInfo {
    public var hasMore: Bool
    public var total: Int?
    // TODO: pageTitle 已经不再使用，需要清理
    public var pageTitle: String?
    public var lastLabel: String?
    public init(hasMore: Bool, total: Int?, pageTitle: String?, lastLabel: String?) {
        self.hasMore = hasMore
        self.total = total
        self.pageTitle = pageTitle
        self.lastLabel = lastLabel
    }
    public var debugInfo: String {
        var dic = [String: Any]()
        dic["hasMore"] = hasMore
        if let t = total { dic["total"] = t }
        if let p = pageTitle { dic["pageTitle"] = DocsTracker.encrypt(id: p) }
        if let l = lastLabel { dic["lastLabel"] = DocsTracker.encrypt(id: l) }
        return dic.description
    }
}
