//
//  SyncBlockReferenceItem.swift
//  SKDoc
//
//  Created by lijuyou on 2023/8/3.
//

import SKFoundation

struct SyncBlockReferenceItem: Codable {
    let url: String
    let createTime: Int
    let objId: String
    let title: String
    let permitted: Bool
    var isSource: Bool = false
    var isCurrent: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case url
        case createTime = "create_time"
        case objId = "obj_id"
        case title
        case permitted
    }
}

struct SyncBlockReferenceListData: Codable, CustomStringConvertible {
    
    struct HostInfo: Codable {
        let title: String
        let url: String
        let permitted: Bool
        
        var isValid: Bool {
            return !url.isEmpty
        }
    }
    
    private(set) var references: [SyncBlockReferenceItem]?
    private(set) var breakPoint: String?
    private(set) var noPermissionCount: Int
    private(set) var hasMore: Bool
    private(set) var host: HostInfo?
    private(set) var parent: HostInfo?
    
    var hasData: Bool {
        !(references?.isEmpty ?? true)
    }
    
    enum CodingKeys: String, CodingKey {
        case references
        case breakPoint = "bp"
        case noPermissionCount = "no_permission_count"
        case hasMore = "has_more"
        case host
        case parent
    }
    
    mutating func merge(other: SyncBlockReferenceListData) {
        self.breakPoint = other.breakPoint
        self.hasMore = other.hasMore
        self.noPermissionCount += other.noPermissionCount
        if let list = other.references, !list.isEmpty {
            if self.references == nil {
                self.references = list
            } else {
                self.references?.append(contentsOf: list)
            }
        }
        if other.host != nil {
            self.host = other.host
        }
        if other.parent != nil {
            self.parent = other.parent
        }
    }
    
    mutating func append(_ item: SyncBlockReferenceItem, insertFirst: Bool) {
        if references == nil {
            references = [item]
        } else {
            if insertFirst {
                references?.insert(item, at: 0)
            } else {
                references?.append(item)
            }
        }
    }
    
    
    var description: String {
        return "[hasMore:\(hasMore)], count:\(self.references?.count ?? -1),noPermCount:\(self.noPermissionCount)]"
    }
}

struct GetSyncBlockReferenceResponse: Codable {
    let code: Int
    let msg: String?
    let data: SyncBlockReferenceListData?
    
    var isSuccess: Bool {
        code == 0
    }
}

struct ShowSyncedBlockReferencesParam: Codable, Equatable {
    let resourceToken: String
    let resourceType: Int
    let docxSyncedBlockHostToken: String
    let docxSyncedBlockHostType: Int
    let limit: Int
    let totalCount: Int
    
    static func == (lhs: ShowSyncedBlockReferencesParam, rhs: ShowSyncedBlockReferencesParam) -> Bool {
        lhs.resourceToken == rhs.resourceToken &&
        lhs.resourceType == rhs.resourceType &&
        lhs.docxSyncedBlockHostToken == rhs.docxSyncedBlockHostToken &&
        lhs.docxSyncedBlockHostType == rhs.docxSyncedBlockHostType &&
        lhs.limit == rhs.limit &&
        lhs.totalCount == rhs.totalCount
    }
}
