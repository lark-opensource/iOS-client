//
//  DocsDetailInfoCountModel.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/18.
//  


import Foundation

public struct DocsDetailInfoCountModel {
    public var title: String
    public var countText: String
    public var newsCountText: NSAttributedString?
    init(title: String, countText: String, newsCountText: NSAttributedString? = nil) {
        self.title = title
        self.countText = countText
        self.newsCountText = newsCountText
    }
}
