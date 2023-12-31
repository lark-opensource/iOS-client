//
//  WikiTreeConverterProvider.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/27.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

public protocol WikiPickerTreeConverterProviderType: WikiTreeConverterProviderType {
    var disabledToken: String? { get }
    var clickHandler: WikiTreeConverterClickHandler? { get set }
    func converter(treeState: WikiTreeState) -> WikiTreeConverterType
}

public class WikiPickerTreeConverterProvider: WikiPickerTreeConverterProviderType {

    public let disabledToken: String?
    weak public var clickHandler: WikiTreeConverterClickHandler?

    public init(disabledToken: String?) {
        self.disabledToken = disabledToken
    }

    public func converter(treeState: WikiTreeState) -> WikiTreeConverterType {
        let token = disabledToken
        // picker tree 需要过滤 shortcut，禁用特定节点
        let config = WikiTreeConverterConfig(filter: { meta in
            !meta.isShortcut
        }, enableChecker: { meta in
            meta.wikiToken != token
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

public protocol WikiMainTreeConverterProviderType: WikiTreeConverterProviderType {
    var clickHandler: WikiTreeConverterClickHandler? { get set }
    func converter(treeState: WikiTreeState, isReachable: Bool) -> WikiTreeConverterType
}

public class WikiMainTreeConverterProvider: WikiMainTreeConverterProviderType {

    weak public var clickHandler: WikiTreeConverterClickHandler?
    let offlineChecker: WikiTreeOfflineCheckerType

    public init(offlineChecker: WikiTreeOfflineCheckerType) {
        self.offlineChecker = offlineChecker
    }

    public func converter(treeState: WikiTreeState, isReachable: Bool) -> WikiTreeConverterType {
        // picker tree 需要过滤 shortcut，禁用特定节点
        let config = WikiTreeConverterConfig(filter: nil, enableChecker: { [weak self] meta in
            if meta.nodeType.isMainRootType {
                return isReachable
            }
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
