//
//  TableViewKeyboardHandler.swift
//  LarkKeyCommandKit
//
//  Created by Saafo on 2021/3/14.
//  Powered by SolaWing on 2020/12/30.
//

import UIKit
import Foundation
import LarkKeyboardKit
import RxSwift

/// 快捷键动作
public enum BaseSelectiveAction {
    /// 快捷键向上
    case up
    /// 快捷键向下
    case down
    /// 快捷键选中
    case select
}

/// 方向键方向
public enum Direction {
    /// 快捷键向上
    case up
    /// 快捷键向下
    case down
}

/// TableView 中可以 Focus 的位置
public enum TableViewFocusInfo: Equatable {
    case cell(indexPath: IndexPath)
    case header(section: Int)
    case footer(section: Int)
}

// MARK: - TableViewKeyboardHandlerDelegate

/// 实现列表快捷键选择组件需要遵从的协议
public protocol TableViewKeyboardHandlerDelegate: AnyObject {

    /// 需要实现快捷键控制的 UITableView，业务方要注意实现
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView

    /// UITableView 是否能处理响应，默认在`!isHidden`时能处理响应
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, canFocusOn tableView: UITableView) -> Bool

    /// 是否能选中`TableViewFocusInfo`位置
    /// - Note: 默认可选中所有 cell，不可选中所有 header 和 footer，业务方可按需重写
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, canFocusAt info: TableViewFocusInfo) -> Bool

    /// 在 第一响应者为`responder`时，是否应该响应快捷键
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, canHandleKeyboardIn responder: UIResponder) -> Bool

    /// 重置高亮后，默认的 Focus 位置
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler,
                                  firstFocusPositionFor tableView: UITableView) -> TableViewFocusInfo

    /// Header at section 被选中回调
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, didSelectHeaderAt section: Int)

    /// Footer at section 被选中回调
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, didSelectFooterAt section: Int)
}

/// 协议默认实现
public extension TableViewKeyboardHandlerDelegate {

    /// UITableView 是否能处理响应，默认在`!isHidden`时能处理响应
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler,
                                  canFocusOn tableView: UITableView) -> Bool { !tableView.isHidden }

    /// 是否能选中`TableViewFocusInfo`位置
    /// - Note: 默认可选中所有 cell，不可选中所有 header 和 footer，业务方可按需重写
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, canFocusAt info: TableViewFocusInfo) -> Bool {
        switch info {
        case .cell(indexPath: _):
            return true
        default:
            return false
        }
    }

    /// 在 第一响应者为`responder`时，是否应该响应快捷键
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler,
                                  canHandleKeyboardIn responder: UIResponder) -> Bool { true }

    /// 重置高亮后，默认的 Focus 位置
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler,
                                  firstFocusPositionFor tableView: UITableView) -> TableViewFocusInfo {
        return .cell(indexPath: IndexPath(row: 0, section: 0))
    }

    /// Header at section 被选中回调
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, didSelectHeaderAt section: Int) {}

    /// Footer at section 被选中回调
    func tableViewKeyboardHandler(handler: TableViewKeyboardHandler, didSelectFooterAt section: Int) {}
}

// MARK: - TableViewKeyboardHandler

/// 列表快捷键逻辑辅助类初始化参数
public enum TableViewKeyboardHandlerOption {
    /// 在有外接键盘时，默认选中第一个，默认值为 true
    case selectFirstByDefault(selected: Bool)
    /// 快捷键选择时，列表滚动的位置，默认值为 .middle
    case scrollPosition(position: UITableView.ScrollPosition)
    /// 允许 `Tab` 和 `⇧ + Tab` 上下选择，默认值为 true
    case allowTabSelection(allowed: Bool)
    /// cell 高亮的设置，默认为 true
    case allowCellFocused(focused: Bool)
}

/// 处理列表快捷键逻辑辅助类
public final class TableViewKeyboardHandler {

    /// 当前 Focus 的位置
    private var _currentFocus: TableViewFocusInfo?
    /// Wrapper，设置值后有滚动到可视区域的效果
    var currentFocus: TableViewFocusInfo? {
        get { _currentFocus }
        set { setFocus(at: newValue, animated: true) }
    }

    /// 有外接键盘时，自动选中第一个, 目前仅在iPad上开启
    var hasExternalKeyboard: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && KeyboardKit.shared.keyboardType == .hardware
    }

    // Configurations
    /// 在有外接键盘时，默认选中第一个，默认值为 true
    public var scrollPosition: UITableView.ScrollPosition = .middle
    /// 快捷键选择时，列表滚动的位置，默认值为 .middle
    public var allowTabSelection: Bool = true
    /// 允许 `Tab` 和 `⇧ + Tab` 上下选择，默认值为 true
    public var selectFirstByDefault: Bool = true {
        didSet {
            updateWillDisplayCellSubscription()
        }
    }
    /// cell 高亮的设置，默认为 true
    private var allowCellFocused: Bool = true

    // Subscriptions
    private var disposeBag = DisposeBag()
    private var willDisplayCellSubscription: Disposable?
    private var didSelectRowAtSubscription: Disposable?

    /// - Note: 在对 tableView 设置 delegate 之后再对此变量赋值。
    ///         如果 tableView delegate 被更改，需要对此变量重新赋值。
    ///         否则原有设置默认选中效果的`willDisplayCell`订阅关系会失效
    public weak var delegate: TableViewKeyboardHandlerDelegate? {
        didSet {
            updateWillDisplayCellSubscription()
            updateDidSelectRowAtSubscription()
        }
    }

    /// - Note: options 支持初始化时配置，也支持初始化后单独更改
    public init(options: [TableViewKeyboardHandlerOption]? = nil) {
        // Setup options
        options?.forEach { option in
            switch option {
            case .selectFirstByDefault(selected: let selected):
                selectFirstByDefault = selected
            case .scrollPosition(position: let position):
                scrollPosition = position
            case .allowTabSelection(allowed: let allowed):
                allowTabSelection = allowed
            case .allowCellFocused(focused: let focused):
                allowCellFocused = focused
            }
        }
        // Setup Keyboard change subscription
        KeyboardKit.shared.keyboardChange.drive(onNext: { [weak self] (keyboard) in
            guard let keyboard = keyboard, let `self` = self else { return }
            if keyboard.type == .hardware {
                if self.currentFocus == nil { self.resetFocus(shouldScrollToVisiable: false) }
            } else {
                self.currentFocus = nil
            }
        }).disposed(by: disposeBag)
    }

    // MARK: - Interfaces

    /// 设置 Focus 位置
    /// - Parameters:
    ///   - info: Focus 位置，设置为 nil 以取消高亮
    ///   - animated: Focus 时是否有动画
    public func setFocus(at info: TableViewFocusInfo?, animated: Bool, shouldScrollToVisiable: Bool = true) {
        assert(Thread.isMainThread, "should occur on main thread!")
        if allowCellFocused, let oldValue = _currentFocus {
            // NOTE: 目前数据源更新会reload, 所以即使不更新focus，旧值reload也会清理掉
            focusView(for: oldValue)?.setFocused(false, animated: animated)
        }
        // 验证非空 info 位置是否合法
        // 有时刷新 table 时 table 为空，所以 path invalid 仍然需要重置 Focus
        var info = info
        if let guardedInfo = info, !pathValid(at: guardedInfo) {
            info = getFirstPosition()
        }
        _currentFocus = info
        if let newValue = info {
            if shouldScrollToVisiable {
                scrollToVisible(for: newValue, animated: animated) // will set focus when loaded
            }
            if allowCellFocused, let view = focusView(for: newValue) {
                view.setFocused(true, animated: animated)
            }
        }
    }

    /// 重置 Focus 位置
    /// - Note: 如果有外接键盘并且`selectFirstByDefault`为 true，则会重置到 delegate 中的`firstFocusPosition`位置，否则取消高亮
    public func resetFocus(shouldScrollToVisiable: Bool = true) {
        let info = getFirstPosition()
        if hasExternalKeyboard {
            setFocus(at: info,
                     animated: false,
                     shouldScrollToVisiable: shouldScrollToVisiable)
        } else {
            self.currentFocus = nil
        }
    }

    // MARK: - Public helper attribute & methods

    /// 基础选择快捷键，包括上下、选择、（按配置）Tab & shift + Tab 上下选中
    public var baseSelectiveKeyBindings: [KeyBindingWraper] {
        weak var `self` = self
        let tryHandle = { self?.canHandle(keyBinding: $0) ?? false }
        let tabKeyBinding = [
            KeyCommandBaseInfo(input: UIKeyCommand.inputTab, modifierFlags: [.shift])
                .binding(tryHandle: tryHandle, handler: { self?.handle(action: .up) })
                .wraper,
            KeyCommandBaseInfo(input: UIKeyCommand.inputTab, modifierFlags: [])
                .binding(tryHandle: tryHandle, handler: { self?.handle(action: .down) })
                .wraper
        ]
        return [
            KeyCommandBaseInfo(input: UIKeyCommand.inputUpArrow, modifierFlags: [])
                .binding(tryHandle: tryHandle, handler: { self?.handle(action: .up) })
                .wraper,
            KeyCommandBaseInfo(input: UIKeyCommand.inputDownArrow, modifierFlags: [])
                .binding(tryHandle: tryHandle, handler: { self?.handle(action: .down) })
                .wraper,
            KeyCommandBaseInfo(input: UIKeyCommand.inputReturn, modifierFlags: [])
                .binding(tryHandle: tryHandle, handler: { self?.handle(action: .select) })
                .wraper
        ] + (allowTabSelection ? tabKeyBinding : [])
    }

    /// - Note: 如果 Header 有选中态，需要手动在 tableView delegate `viewForHeaderInSection`方法中调用此方法
    ///         以切换 Header view 的选中态
    public func updateFocusForHeader(_ header: TableViewFocusable, at section: Int) {
        guard allowCellFocused else { return }
        if case .header(section: let focusSection) = currentFocus, focusSection == section {
            header.setFocused(true, animated: false)
        } else {
            header.setFocused(false, animated: false)
        }
    }

    /// - Note: 如果 Footer 有选中态，需要手动在 tableView delegate `viewForFooterInSection`方法中调用此方法
    ///         以切换 Footer view 的选中态
    public func updateFocusForFooter(_ footer: TableViewFocusable, at section: Int) {
        guard allowCellFocused else { return }
        if case .footer(section: let focusSection) = currentFocus, focusSection == section {
            footer.setFocused(true, animated: false)
        } else {
            footer.setFocused(false, animated: false)
        }
    }

    // MARK: - Internal helper methods

    // MARK: Handle key commands & focus

    func handle(action: BaseSelectiveAction) {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self) else { return }
        guard delegate?.tableViewKeyboardHandler(handler: self, canFocusOn: tableView) ?? false else { return }
        guard let currentFocus = self.currentFocus else {
            if action == .up || action == .down {
                self.currentFocus = delegate?.tableViewKeyboardHandler(handler: self,
                                                                       firstFocusPositionFor: tableView)
            }
            return
        }
        switch action {
        case .up:
            tryAndSetNextValidFocus(info: currentFocus, direction: .up)
        case .down:
            tryAndSetNextValidFocus(info: currentFocus, direction: .down)
        case .select:
            guard pathValid(at: currentFocus) else { return }
            if focusView(for: currentFocus) == nil {
                scrollToVisible(for: currentFocus, animated: false)
            }
            switch currentFocus {
            case .cell(indexPath: let path):
                tableView.selectRow(at: path, animated: true, scrollPosition: scrollPosition)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: path)
            case .header(section: let section):
                delegate?.tableViewKeyboardHandler(handler: self, didSelectHeaderAt: section)
            case .footer(section: let section):
                delegate?.tableViewKeyboardHandler(handler: self, didSelectFooterAt: section)
            }
        }
    }

    func canHandle(keyBinding: KeyBinding) -> Bool {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self) else { return false }
        let info = keyBinding.info
        var isSpecialKey: Bool {
            info.input == UIKeyCommand.inputUpArrow ||
            info.input == UIKeyCommand.inputDownArrow ||
            (allowTabSelection ? info.input == UIKeyCommand.inputTab : false)
        }
        var canHandleReturn: Bool {
            info.input == UIKeyCommand.inputReturn && hasExternalKeyboard
        }
        var validResponder: Bool {
            guard let responder = KeyboardKit.shared.firstResponder else { return true }
            return self.delegate?.tableViewKeyboardHandler(handler: self, canHandleKeyboardIn: responder) ?? false
        }
        var specialHandled: Bool {
            isSpecialKey || canHandleReturn
        }
        return (delegate?.tableViewKeyboardHandler(handler: self, canFocusOn: tableView) ?? false) &&
            (KeyBinding.defaultTryHanlde(keyBinding) || specialHandled) && validResponder
    }

    func focusView(for info: TableViewFocusInfo) -> TableViewFocusable? {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self),
              pathValid(at: info) else { return nil }
        switch info {
        case .cell(indexPath: let indexPath):
            return tableView.cellForRow(at: indexPath)
        case .header(section: let section):
            return tableView.headerView(forSection: section) as? TableViewFocusable
        case .footer(section: let section):
            return tableView.footerView(forSection: section) as? TableViewFocusable
        }
    }

    func updateFocusForWillDisplay(cell: UITableViewCell, at: IndexPath) {
        // set highlight in cellForRow will be overwritten of tableview configuration
        if allowCellFocused, case .cell(indexPath: let focusPath) = currentFocus, focusPath == at {
            cell.setFocused(true)
        } else {
            cell.setFocused(false)
        }
    }

    // MARK: Calculate position

    func tryAndSetNextValidFocus(info: TableViewFocusInfo, direction: Direction) {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self) else { return }
        /// 如果位置不合法，直接退出
        guard pathValid(at: info, sectionOnly: true) else { return }
        /// 先尝试能否更新当前（非原始）path，能更新则更新完退出
        guard info == currentFocus || !tryUpdateFocus(at: info) else { return }
        switch direction {
        case .up:
            switch info {
            case .cell(indexPath: let path):
                if path.row > 0 {
                    let prevPath = IndexPath(row: path.row - 1, section: path.section)
                    tryAndSetNextValidFocus(info: .cell(indexPath: prevPath), direction: .up)
                } else {
                    // 触达了一个 section 的顶部，尝试找 header
                    tryAndSetNextValidFocus(info: .header(section: path.section), direction: .up)
                }
            case .header(section: let section):
                tryAndSetNextValidFocus(info: .footer(section: section - 1), direction: .up)
            case .footer(section: let section):
                let prevPath = IndexPath(row: tableView.numberOfRows(inSection: section) - 1, section: section)
                tryAndSetNextValidFocus(info: .cell(indexPath: prevPath), direction: .up)
            }
        case .down:
            switch info {
            case .cell(indexPath: let path):
                if path.row < tableView.numberOfRows(inSection: path.section) - 1 {
                    let nextPath = IndexPath(row: path.row + 1, section: path.section)
                    tryAndSetNextValidFocus(info: .cell(indexPath: nextPath), direction: .down)
                } else {
                    // 触达了一个 section 的底部，尝试找 footer
                    tryAndSetNextValidFocus(info: .footer(section: path.section), direction: .down)
                }
            case .header(section: let section):
                tryAndSetNextValidFocus(info: .cell(indexPath: IndexPath(row: 0, section: section)), direction: .down)
            case .footer(section: let section):
                tryAndSetNextValidFocus(info: .header(section: section + 1), direction: .down)
            }
        }
    }

    /// 判断位置是否合法，合法位置是否可选中
    func pathValid(at info: TableViewFocusInfo, sectionOnly: Bool = false) -> Bool {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self) else { return false }
        switch info {
        case .cell(indexPath: let path):
            let rowValid = path.row > -1 &&
                path.section > -1 &&
                path.section < tableView.numberOfSections &&
                path.row < tableView.numberOfRows(inSection: path.section)
            return path.section > -1 &&
                   path.section < tableView.numberOfSections &&
                   (sectionOnly ? true : rowValid)
        case .header(section: let section):
            return section > -1 && section < tableView.numberOfSections
        case .footer(section: let section):
            return section > -1 && section < tableView.numberOfSections
        }
    }

    func tryUpdateFocus(at info: TableViewFocusInfo) -> Bool {
        if pathValid(at: info) && (delegate?.tableViewKeyboardHandler(handler: self, canFocusAt: info) ?? false) {
            self.currentFocus = info
            return true
        }
        return false
    }

    func getFirstPosition() -> TableViewFocusInfo? {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self) else { return nil }
        return selectFirstByDefault ? delegate?.tableViewKeyboardHandler(handler: self,
                                                                         firstFocusPositionFor: tableView) : nil
    }

    // new showing view should check focus view
    func scrollToVisible(for focus: TableViewFocusInfo, animated: Bool) {
        guard let tableView = delegate?.tableViewKeyboardHandler(handlerToGetTable: self) else { return }
        guard delegate?.tableViewKeyboardHandler(handler: self, canFocusOn: tableView) ?? false,
              pathValid(at: focus) else { return }
        switch focus {
        case .cell(indexPath: let path):
            tableView.scrollToRow(at: path, at: scrollPosition, animated: animated)
        case .header(section: let section):
            tableView.scrollRectToVisible(tableView.rectForHeader(inSection: section), animated: animated)
        case .footer(section: let section):
            tableView.scrollRectToVisible(tableView.rectForFooter(inSection: section), animated: animated)
        }
    }

    // MARK: Subscriptions

    private func updateWillDisplayCellSubscription() {
        willDisplayCellSubscription?.dispose() // clear subscription before
        willDisplayCellSubscription = delegate?.tableViewKeyboardHandler(handlerToGetTable: self)
            .rx.willDisplayCell.subscribe(
                onNext: { [weak self] cell, indexPath in
                self?.updateFocusForWillDisplay(cell: cell, at: indexPath)
            }
        )
        willDisplayCellSubscription?.disposed(by: disposeBag)
    }
    private func updateDidSelectRowAtSubscription() {
        didSelectRowAtSubscription?.dispose()
        didSelectRowAtSubscription = delegate?.tableViewKeyboardHandler(handlerToGetTable: self)
            .rx.itemSelected.subscribe(
                onNext: { [weak self] (indexPath) in
                // 在手动点击的时候，也调整高亮位置，但不改变列表滚动位置
                let info: TableViewFocusInfo = .cell(indexPath: indexPath)
                guard let `self` = self, self.pathValid(at: info) else { return }
                self.setFocus(at: info, animated: true, shouldScrollToVisiable: false)
            }
        )
        didSelectRowAtSubscription?.disposed(by: disposeBag)
    }
}

/// 支持高亮协议
/// - Note: Header & Footer view 可以遵循此协议以统一实现高亮
public protocol TableViewFocusable {
    /// 设置为高亮与否
    func setFocused(_ focused: Bool, animated: Bool)
}

extension UITableViewCell: TableViewFocusable {
    public func setFocused(_ focused: Bool, animated: Bool = false) {
        setHighlighted(focused, animated: animated)
    }
}
