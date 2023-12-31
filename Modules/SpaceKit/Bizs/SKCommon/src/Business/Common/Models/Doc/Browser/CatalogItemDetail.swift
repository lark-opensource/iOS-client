//
//  CatalogItemDetail.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation

//From BrowserCatalogSideView.swift
public final class CatalogItemDetail {
    public var identifier: String = ""
    public var title: String = ""
    public var level: Int = 1  // Comment: 此level不是标题level，而是在标题level数组中的相对level，即对于[H1, H2, H8, H9]，level数组为[1, 2, 3, 4]。由前端运算
    public var yOffset: CGFloat = 0.0
    public var showParagraph: Bool = true //3.30新增 - 兼容老逻辑，表示是否显示当前的标题，如果是false可以忽略不显示
    public var showCollapse: Bool = false //是否展示折叠箭头，在此标题下有子标题的时候会是true
    public var collapse: Bool = true //折叠 or 收起 , true 表示折叠
    public var index: Int = -1 //pdf页码索引
    public init(title: String, level: Int, yOffset: CGFloat) {
        self.title = title
        self.level = level
        self.yOffset = yOffset
    }

    public init(identifier: String, title: String, level: Int, index: Int, isCollapsed: Bool, isShowCollapsed: Bool) {
        self.identifier = identifier
        self.title = title
        self.level = level
        self.index = index
        self.collapse = isCollapsed
        self.showCollapse = isShowCollapsed
    }
    
    public init(json: [String: Any]) {
        self.identifier = (json["hash"] as? String) ?? ""
        self.title = (json["title"] as? String) ?? ""
        self.level = (json["level"] as? Int) ?? 1
        self.yOffset = (json["top"] as? CGFloat) ?? 0.0
        self.showParagraph = (json["showParagraph"] as? Bool) ?? true
        self.showCollapse = (json["showCollapse"] as? Bool) ?? false
        self.collapse = (json["collapse"] as? Bool) ?? true
    }
}
