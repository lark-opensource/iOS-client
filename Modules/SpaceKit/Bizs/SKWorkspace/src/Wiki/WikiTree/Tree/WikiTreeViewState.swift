//
//  WikiTreeViewState.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/13.
//

import Foundation
import SKFoundation

// 标识一颗树的 UI 状态
public struct WikiTreeViewState: Equatable {
    // 记录当前选中的 wikiToken，所有 wikiToken 相同的节点会展示选中态
    public var selectedWikiToken: String?
    // 最近一次选中的 nodeUID，包括在目录树上点击或从详情页目录树同步
    public var latestSelectedNodeUID: WikiTreeNodeUID?
    public var expandedUIDs: Set<WikiTreeNodeUID> = []

    public var isEmpty: Bool {
        guard selectedWikiToken == nil else { return false }
        guard latestSelectedNodeUID == nil else { return false }
        guard expandedUIDs.isEmpty else { return false }
        return true
    }

    // 更新当前选中的 wikiToken
    public mutating func select(wikiToken: String?) {
        selectedWikiToken = wikiToken
    }

    public mutating func select(nodeUID: WikiTreeNodeUID?) {
        latestSelectedNodeUID = nodeUID
    }

    // 标记特定 UID 为展开状态
    public mutating func expand(nodeUID: WikiTreeNodeUID) {
        expandedUIDs.insert(nodeUID)
    }

    // 标记特定 UID 为折叠状态
    public mutating func collapse(nodeUID: WikiTreeNodeUID) {
        expandedUIDs.remove(nodeUID)
    }

    // 切换特定 UID 的展开状态
    public mutating func toggle(nodeUID: WikiTreeNodeUID) {
        if expandedUIDs.contains(nodeUID) {
            collapse(nodeUID: nodeUID)
        } else {
            expand(nodeUID: nodeUID)
        }
    }
    
    public init(selectedWikiToken: String? = nil, expandedUIDs: Set<WikiTreeNodeUID> = []) {
        self.selectedWikiToken = selectedWikiToken
        self.expandedUIDs = expandedUIDs
    }
}
