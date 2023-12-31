//
//  ASLDebugProtocol.swift
//  LarkSearchCore
//
//  Created by chenziyue on 2021/12/13.
//

import Foundation
import UIKit

@frozen
public enum ASLDebugCellType {
    case none
    case disclosureIndicator // with a disclosure indicator at right of the cell.
    case switchButton // with a switch view at right of the cell.
    case uiTextField // with a text filed at the right of the cell
}

/// Represents one cell of debug view controller.
public protocol ASLDebugCellItem {
    /// Title will appear at left of the cell.
    var title: String { get }
    /// Detail will appear at right of the cell.
    var detail: String { get set }
    /// Type property controls the right area apperance of the cell.
    var type: ASLDebugCellType { get }
    /// Controls whether switch button is on. Only works when self.type equals .switchButton.
    var isSwitchButtonOn: Bool { get set }
    /// Called when switch view changes its value. Only works when self.type equals .switchButton.
    var switchValueDidChange: ((Bool) -> Void)? { get }
    /// Whether item can perform table view cell action.
    /// DebugViewController forwards its table view conrresponding method to this method.
    var canPerformAction: ((Selector) -> Bool)? { get }
    /// Perform the action
    /// DebugViewController forwards its table view conrresponding method to this method.
    var perfomAction: ((Selector) -> Void)? { get }
    /// Called when the corresponding cell is selected.
    func didSelect(_ item: ASLDebugCellItem, debugVC: UIViewController)
}

public extension ASLDebugCellItem {
    var detail: String { return "" }
    var type: ASLDebugCellType { return .none }

    var isSwitchButtonOn: Bool { return false }
    var switchValueDidChange: ((Bool) -> Void)? { return nil }

    var canPerformAction: ((Selector) -> Bool)? { return nil }
    var perfomAction: ((Selector) -> Void)? { return nil }

    func didSelect(_ item: ASLDebugCellItem, debugVC: UIViewController) { }
}
