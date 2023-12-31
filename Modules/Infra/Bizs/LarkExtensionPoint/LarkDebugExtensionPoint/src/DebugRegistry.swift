//
//  DebugRegistry.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/25/19.
//

import Foundation
import UIKit

// swiftlint:disable identifier_name
public var DebugCellItemRegistries: [SectionType: [DebugItemProvider]] = [:]

public typealias DebugItemProvider = () -> DebugCellItem

public enum DebugRegistry {
    /// Register a debug cell item. DebugViewController will create a cell with the item and shows on its tableview.
    ///  - NOTE: Items will be created each time a DebugViewController is showed, and will be dealloced when DebugViewController is dismissed.
    /// - Parameters:
    ///   - item: Debug cell item, which defines one debug function.
    ///   - section: The debug section where the debug item will be showed.
    public static func registerDebugItem(_ item: @escaping @autoclosure DebugItemProvider, to section: SectionType) {
        DispatchQueue.main.async {
            var cellItems = DebugCellItemRegistries[section] ?? []
            cellItems.append(item)
            DebugCellItemRegistries[section] = cellItems
        }
    }
}

/// Each section type represents one tableview section.
@frozen
public enum SectionType: CaseIterable {
    case switchEnv
    case basicInfo
    case debugTool
    case dataInfo
    #if DEBUG || ALPHA || BETA
    public var name: String {
        switch self {
        case .switchEnv:
            return "切换环境"
        case .basicInfo:
            return "基本信息"
        case .debugTool:
            return "调试工具"
        case .dataInfo:
            return "数据信息"
        }
    }
    #endif
}

@frozen
public enum DebugCellType {
    case none
    case disclosureIndicator // with a disclosure indicator at right of the cell.
    case switchButton // with a switch view at right of the cell.
}

/// Represents one cell of debug view controller.
public protocol DebugCellItem {
    /// Title will appear at left of the cell.
    var title: String { get }
    /// Detail will appear at right of the cell.
    var detail: String { get }
    /// Type property controls the right area apperance of the cell.
    var type: DebugCellType { get }
    /// Controls whether switch button is on. Only works when self.type equals .switchButton.
    var isSwitchButtonOn: Bool { get }
    /// Called when switch view changes its value. Only works when self.type equals .switchButton.
    var switchValueDidChange: ((Bool) -> Void)? { get }
    /// Whether item can perform table view cell action.
    /// DebugViewController forwards its table view conrresponding method to this method.
    var canPerformAction: ((Selector) -> Bool)? { get }
    /// Perform the action
    /// DebugViewController forwards its table view conrresponding method to this method.
    var perfomAction: ((Selector) -> Void)? { get }
    /// Called when the corresponding cell is selected.
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController)
}

public extension DebugCellItem {
    var detail: String { return "" }
    var type: DebugCellType { return .none }

    var isSwitchButtonOn: Bool { return false }
    var switchValueDidChange: ((Bool) -> Void)? { return nil }

    var canPerformAction: ((Selector) -> Bool)? { return nil }
    var perfomAction: ((Selector) -> Void)? { return nil }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) { }
}
// swiftlint:enable identifier_name
