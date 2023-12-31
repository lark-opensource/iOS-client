//
//  ChatSettingCellBaseModel.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/24.
//

import UIKit
import Foundation

public enum ChatSettingSeparaterStyle {
    /// 将会根据 Cell 位置自动设置分割线
    case auto
    /// 没有分割线
    case none
    /// 并非是50%, 而是前面有一段留白
    case half
    /// 和Cell一样宽
    case full
}

public protocol ChatSettingCellVMProtocol {
    var cellIdentifier: String { get }
    /// 对应Cell的分割线样式
    var style: ChatSettingSeparaterStyle { get set }
    /// 对应的标识符
    var type: ChatSettingCellType { get }
    // 点击标识符
    var tapIdentify: String { get }
}

public extension ChatSettingCellVMProtocol {
    // 点击标识符
    var tapIdentify: String {
        type.rawValue
    }
}

public protocol ChatSettingCellStyleFormat {
    func style(for item: ChatSettingCellVMProtocol, at index: Int, total: Int) -> ChatSettingSeparaterStyle
}

public extension ChatSettingCellStyleFormat {
    func style(for item: ChatSettingCellVMProtocol, at index: Int, total: Int) -> ChatSettingSeparaterStyle {
        if _fastPath(item.style == .auto) {
            if _slowPath(index == total - 1) {
                return .none
            }
            return .half
        } else {
            return item.style
        }
    }
}

public protocol ChatSettingCellProtocol: UITableViewCell {
    /// 填充方法
    ///
    /// Parameter item: 对应的viewModel
    var item: ChatSettingCellVMProtocol? { get set }

    func updateAvailableMaxWidth(_ width: CGFloat)
}

public typealias ChatSettingDatasource = [ChatSettingSectionModel]

public struct ChatSettingSectionModel {
    public var title: String?
    public var description: String?
    public var items: [ChatSettingCellVMProtocol]

    public init(title: String? = nil,
                description: String? = nil,
                items: [ChatSettingCellVMProtocol] = []) {
        self.title = title
        self.description = description
        self.items = items
    }

    @inline(__always)
    public var numberOfRows: Int { items.count }

    @inline(__always)
    public func item(at row: Int) -> ChatSettingCellVMProtocol? {
        _fastPath(row < numberOfRows) ? items[row] : nil
    }
}
