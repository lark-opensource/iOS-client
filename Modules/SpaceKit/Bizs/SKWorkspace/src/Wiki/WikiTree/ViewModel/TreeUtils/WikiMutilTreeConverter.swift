//
//  WikiMutilTreeConverter.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/18.
//

import Foundation


public class WikiMutilTreeConverterProvider {
    public weak var clickHandler: WikiTreeConverterClickHandler?
    public let offlineChecker: WikiTreeOfflineCheckerType
    
    public init(offlineChecker: WikiTreeOfflineCheckerType) {
        self.offlineChecker = offlineChecker
    }
    
    public func converter(treeState: WikiTreeState, isReachable: Bool) -> WikiTreeConverterType {
        let config = WikiTreeConverterConfig(filter: nil, enableChecker: { [weak self] meta in
            if isReachable {
                return true
            }
            return self?.offlineChecker.checkOfflineEnable(meta: meta) ?? false
        }, clickStateHandler: { [weak self] (meta, treeNode) in
            self?.clickHandler?.configDidToggleNode(meta: meta, node: treeNode)
        }, clickContentHandler: { [weak self] (meta, treeNode) in
            self?.clickHandler?.configDidClickNode(meta: meta, node: treeNode)
        }, accessoryItemProvider: { [weak self] (meta, treeNode) in
            self?.clickHandler?.configAccessoryItem(meta: meta, node: treeNode)
        })
        return converter(treeState: treeState, config: config)
    }
    
    public func converter(treeState: WikiTreeState, config: WikiTreeConverterConfig) -> WikiTreeConverterType {
        return WikiTreeNodeConverter(treeState: treeState, config: config)
    }
}
