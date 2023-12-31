//
//  AtViewType.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import Foundation

/// @出现位置
///
/// - docs: 文档中插入
/// - comment: 评论中插入
/// - mindnote: 在思维笔记中插入（比 .docs 少群名片功能）
public enum AtViewType: Int {
    case docs = 0
    case comment = 1
    case mindnote = 2
    case larkDocs = 3  // 单品
    case gadget = 4
    case minutes
    case syncedBlock //sync block
    
    /// 是否支持@群
    public var supportGroup: Bool {
        return self != .mindnote && self != .larkDocs && self != .syncedBlock
    }
}

public enum ExtAtViewType: String {
    case syncedBlock
    
    public var viewType: AtViewType? {
        switch(self) {
        case .syncedBlock: return .syncedBlock
        }
        return nil
    }
}
