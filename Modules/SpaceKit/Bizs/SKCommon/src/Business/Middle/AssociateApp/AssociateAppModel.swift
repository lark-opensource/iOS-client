//
//  AssociateAppModel.swift
//  SKCommon
//
//  Created by ByteDance on 2023/10/13.
//

import Foundation

//"references": [{
//            "obj_token": "MFvxdiNW6oQmNjxLBwRbW1pqcAe",
//            "obj_type": 22,
//            "title": "自定义图标",
//            "url": "https://bytedance.feishu-boe.cn/docx/MFvxdiNW6oQmNjxLBwRbW1pqcAe",
//            "create_time": 1697189680,
//            "creator_id": 7127906919309639700,
//            "permitted": true
//        }, {
//            "permitted": true,
//            "obj_token": "Wmm4dFekfoPMpkxIe9JbVUy1cWg",
//            "obj_type": 22,
//            "title": "",
//            "url": "https://bytedance.feishu-boe.cn/docx/Wmm4dFekfoPMpkxIe9JbVUy1cWg",
//            "create_time": 1697187712,
//            "creator_id": 6949899603831422995
//        }],
//        "bp": "CJOAgILk78GUZQ",
//        "hasmore": false

public final class AssociateAppModel: Codable {
    public var references: [ReferencesModel]?
    public var urlMetaId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case references
        case urlMetaId = "url_meta_id"
    }
    
    public final class ReferencesModel: Codable {
        public var objToken: String?
        public var objType: Int?
        public var url: String?
        public var title: String?
        public var previeToken: String?
        public var needLocalPreview: Bool?
        public var isLazyLoad: Bool?
        public var urlMetaId: Int?
        
        
        private enum CodingKeys: String, CodingKey {
            case objToken = "obj_token"
            case objType = "obj_type"
            case url
            case title
            case previeToken = "previe_token"
            case needLocalPreview = "need_local_preview"
            case isLazyLoad = "is_lazy_load"
            case urlMetaId = "url_meta_id"
        }
        public init() {}
    }
}


