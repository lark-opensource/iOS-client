//
//  CustomTemplate.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/2.
//  


import Foundation
// 自定义模板使用
public struct CustomTemplates: Codable {
    var hasMore: Bool
    var own: [TemplateModel]
    var share: [TemplateModel]
    var shareIndex: String
    var users: [String: TemplateSharer]

    enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case own
        case share
        case shareIndex = "share_index"
        case users
    }

    static let empty = CustomTemplates(hasMore: false,
                                       own: [],
                                       share: [],
                                       shareIndex: "",
                                       users: [:])

    var isEmpty: Bool {
        own.isEmpty && share.isEmpty
    }
    public init(hasMore: Bool,
                own: [TemplateModel],
                share: [TemplateModel],
                shareIndex: String,
                users: [String: TemplateSharer]) {
        self.hasMore = hasMore
        self.own = own
        self.share = share
        self.shareIndex = shareIndex
        self.users = users
    }
    func customTemplates(byAppendingMore moreDataSource: CustomTemplates) -> CustomTemplates {
        var newDataSource = self
        var shareTemplates = self.share
        shareTemplates.append(contentsOf: moreDataSource.share)
        newDataSource.share = shareTemplates
        newDataSource.shareIndex = moreDataSource.shareIndex
        newDataSource.hasMore = moreDataSource.hasMore
        return newDataSource
    }
    func customTemplates(byRemoveObjToken objToken: String) -> CustomTemplates {
        var dataSource = self
        dataSource.own = self.own.filter({ $0.objToken != objToken })
        dataSource.share = self.share.filter({ $0.objToken != objToken })
        return dataSource
    }
    
    public func addCustomTag() {
        own.forEach { $0.tag = .customOwn }
        share.forEach { $0.tag = .customShare }
    }
}
