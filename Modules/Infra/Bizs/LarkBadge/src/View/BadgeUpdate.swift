//
//  BadgeUpdate.swift
//  LarkBadge
//
//  Created by KT on 2019/4/18.
//

import Foundation
import UIKit
import SnapKit

// MARK: - BadgeUpdate
extension BadgeAddable {
    public func configBadgeView(_ observers: [Observer], with path: [NodeName]) {
        DispatchQueue.main.mainSafe {
            guard let view = self.badgeTarget else { return }

            // 第一个非.none节点
            guard let firstUnNoneNode = NodeTrie.firstDisplayNode(path) else { return }
            guard var display = NodeTrie.allBadgeNode(path).first else { return }

            // 如果当前节点type是none， 取第一个非none节点type
            if case .none = display.info.type {
                // hidden 属性每个节点可以单独配置
                let hidden = display.info.isHidden
                display.info = firstUnNoneNode.info
                display.info.isHidden = hidden
            }

            // 显示优先级高的nodee配置
            display.info = display.info.merge(view.badge.initialInfo)

            // 当前没有badge，添加
            guard let currentBadge = view.badge.badgeView else {
                self.addBadge(display, on: view, path: path)
                return
            }
            // 类型不一致，清空之前再添加
            currentBadge.type = display.info.type
            self.update(display, badgeView: currentBadge, path: path)
        }
    }

    private func addBadge(_ node: BadgeNode, on view: UIView, path: [NodeName]) {
        // 容器初始化
        let badgeView = BadgeView(with: node.info.type, in: view)
        update(node, badgeView: badgeView, path: path)
    }

    private func update(_ node: BadgeNode, badgeView: BadgeView, path: [NodeName]) {
        let info = node.info

        // Hidden 控制
        badgeView.isHidden = false
        let selfNode = NodeTrie.shared.node(path)
        if let selfNode = selfNode, selfNode == node {
            if node.info.isHidden {
                badgeView.isHidden = true
            } else {
                switch node.info.type {
                case .label(.number), .label(.plusNumber):
                    badgeView.isHidden = NodeTrie.totalCount(path) <= 0
                case .none: badgeView.isHidden = true
                default: break
                }
            }
        } else {
            let allChild = NodeTrie.allBadgeNode(path).filter { $0.isElement }
            badgeView.isHidden = allChild.filter { $0.info.isHidden }.count == allChild.count
        }

        badgeView.setupBackColor(backgroundColor: info.backgroundColor,
                                 cornerRadius: info.cornerRadius)

        // update Positon
        badgeView.updateOffset(offsetX: info.offset.x, offsetY: info.offset.y)
        badgeView.updateSize(to: info.size)

        // border
        badgeView.setupBorder(color: info.borderColor, width: info.borderWidth)

        // update Label Props
        _setupLabel(badgeView, with: info, path: path)

        // style
        badgeView.style = info.style

        // update Image Props
        badgeView.setupImageView(with: info.type)

        // callback
        guard let observeNode = ObserveTrie.shared.node(path) else { return }
        observeNode.info.primaryObserver?.callback?(observeNode, node)
    }

    private var contentView: UIView? {
        return badgeTarget?.badge.badgeView?.subviews.first
    }

    // update Label Props
    private func _setupLabel(_ badgeView: BadgeView, with info: NodeInfo, path: [NodeName]) {
        badgeView.setupLabel(textSize: info.textSize, textColor: info.textColor)
        // text 优先级 大于 count
        switch info.type {
        case let .label(.text(text)):
            badgeView.updateText(text: text,
                                 size: info.size,
                                 cornerRadius: info.cornerRadius,
                                 horizontalMargin: info.horizontalMargin,
                                 borderWidth: info.borderWidth,
                                 forceLayout: true)
        case .label(.number), .label(.plusNumber):
            let count = NodeTrie.totalCount(path)
            badgeView.updateText(number: count,
                                 size: info.size,
                                 cornerRadius: info.cornerRadius,
                                 horizontalMargin: info.horizontalMargin,
                                 borderWidth: info.borderWidth,
                                 forceLayout: true)
        default:
            break
        }
    }
}
