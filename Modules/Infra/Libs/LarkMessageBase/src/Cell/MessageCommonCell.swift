//
//  MessageCommonCell.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/30.
//

import UIKit
import Foundation
import AsyncComponent
import EETroubleKiller

/// 通用的消息相关的Cell
open class MessageCommonCell: UITableViewCell {
    public static let highlightViewKey = "MessageComponentKey_highlight_key"
    public static let highlightBubbleViewKey = "MessageComponentKey_highlight_bubble_key"
    public static let highlightDuration: TimeInterval = 3

    /// trouble killer打印日志需要的数据
    public var tkDescription: (() -> [String: String])?

    /// cell的唯一标识符（例如消息id）
    public private(set) var cellId: String = ""

    private var renderer: ASComponentRenderer?

    /// 更新cell
    ///
    /// - Parameters:
    ///   - renderer: 渲染引擎（包含布局等信息）
    ///   - cellId: cell的唯一标识（例如消息id）
    open func update(with renderer: ASComponentRenderer, cellId: String) {
        self.cellId = cellId
        renderer.bind(to: self.contentView)
        UIView.setAnimationsEnabled(false)
        renderer.render(self.contentView)
        UIView.setAnimationsEnabled(true)
        self.renderer = renderer
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
    }

    /// 内容区域高亮
    public func highlightView() {
        guard let blinkView = self.getView(by: MessageCommonCell.highlightViewKey) else { return }
        let blinkInsets = UIEdgeInsets.zero
        blinkView.lu.blink(
            color: UIColor.ud.Y100,
            borderColor: UIColor.ud.Y200,
            rectInset: blinkInsets,
            duration: MessageCommonCell.highlightDuration
        )
    }

    /// 通过key获取cell上的view
    ///
    /// - Parameter key: 指定的cell的key
    /// - Returns: 对应的view
    public func getView(by key: String) -> UIView? {
        return renderer?.getView(by: key)
    }

    /// 通过baseKey获取cell上的view
    /// - Parameter key: 指定的cell的baseKey
    /// - Returns: 对应的view数组
    public func getViews(by baseKey: String) -> [UIView]? {
        return renderer?.getViews(by: baseKey)
    }

    open override var description: String {
        "\(super.description); cellID: \(cellId)"
    }
}

// MARK: - EETroubleKiller
extension MessageCommonCell: CaptureProtocol & DomainProtocol {

    public var isLeaf: Bool {
        return true
    }

    public var domainKey: [String: String] {
        var tkDescription = self.tkDescription?() ?? [:]
        tkDescription["id"] = "\(cellId)"
        tkDescription["cellIdentifier"] = "\(reuseIdentifier ?? "unknown")"
        return tkDescription
    }
}
