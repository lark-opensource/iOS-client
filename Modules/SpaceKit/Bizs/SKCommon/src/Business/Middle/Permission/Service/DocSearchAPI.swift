//
//  DocSearchAPI.swift
//  SKCommon
//
//  Created by yinyuan on 2023/6/9.
//

import Foundation
import SpaceInterface

public struct SearchDocResult: Codable {
    public var id: String?
    public var title: String?
    // Search Broker V2 自带高亮 优先使用这个
//    public var attributedTitle: NSAttributedString?
    public var ownerID: String?
    public var ownerName: String?
    public var updateTime: Int64?
    public var url: String?
    public var docType: Int?
    public var isCrossTenant: Bool?
    // wiki 真正类型
    public var wikiSubType: Int?
    
    public init() {
        
    }
}

public protocol DocSearchAPI {
    func searchDoc(_ searchText: String?, docTypes: [String]?, callback: @escaping (_ results: [SearchDocResult]?, _ error: Error?) -> Void)
}

