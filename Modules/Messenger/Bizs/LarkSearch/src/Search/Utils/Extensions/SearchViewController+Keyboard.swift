//
//  SearchViewController+Keyboard.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/12/30.
//

import Foundation
import LarkKeyCommandKit
import LarkUIKit
import RxSwift
import RxRelay
import UIKit
import LarkSearchCore
import LarkKeyboardKit

protocol KeyBoardFocusHandler: AnyObject {
    func canHandle(binding: KeyBinding) -> Bool
    func handleKBDown()
    func handleKBUp()
    func handleKBConfirm()
}
extension KeyBoardFocusHandler {
    func focusChangeKeyBinding() -> [KeyBindingWraper] {
        weak var me = self
        let tryHandle = { me?.canHandle(binding: $0) ?? false }
        return [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: []
                // discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcutsPreviousMessage
            ).binding(
                tryHandle: tryHandle,
                handler: { me?.handleKBUp() }
            )
            .wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: []
                // discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcusNextMessage
            ).binding(
                tryHandle: tryHandle,
                handler: { me?.handleKBDown() }
            ).wraper,
            KeyCommandBaseInfo(
                input: "\r",
                modifierFlags: []
            ).binding(
                tryHandle: tryHandle,
                handler: { me?.handleKBConfirm() }
            ).wraper
        ]
    }
    func canHandle(binding: KeyBinding) -> Bool { KeyBinding.defaultTryHanlde(binding) }
}

final class ExternalKeyboardObserver: NSObject {
    // 使用单例使得状态持久化
    static let shared = ExternalKeyboardObserver()
    // 因为目前是用监控keyboard显示来实现的，所以需要检查通知，不一定是实时的情况
    var hasExternalKeyboardRelay = BehaviorRelay<Bool>(value: false)
    private(set) var hasExternalKeyboard: Bool {
        get { hasExternalKeyboardRelay.value }
        set {
            hasExternalKeyboardRelay.accept(newValue)
        }
    }
    override init() {
        super.init()
        if Display.pad { // 目前仅在iPad上开启keyboard区分, 对应的使用场景需要注意
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        }
    }
    @objc
    func keyboardWillShow(notification: NSNotification) {
        func hasExternalKeyboard(notification: NSNotification) -> Bool {
            guard
                let userInfo = notification.userInfo,
                let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else { return false }
            // https://stackoverflow.com/questions/2893267/how-can-i-detect-if-an-external-keyboard-is-present-on-an-ipad/5760910#5760910
            // 有外接硬盘时，要么height很小(<=66), 要么超出屏幕
            // 如果用户把键盘收起，目前会误判
            return keyboardScreenEndFrame.height < 70 || keyboardScreenEndFrame.maxY > UIScreen.main.bounds.height
        }
        self.hasExternalKeyboard = hasExternalKeyboard(notification: notification)
    }
}

protocol KeyBoardFocusable {
    func setFocused(_ focused: Bool, animated: Bool)
}

extension UITableViewCell: KeyBoardFocusable {
    func setFocused(_ focused: Bool, animated: Bool = false) {
        setHighlighted(focused, animated: animated)
    }

    func updateCellStyle(animated: Bool) {
        let action: () -> Void = {
            switch (self.isHighlighted, self.isSelected) {
            case (_, true):
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillActive
            case (true, false):
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillFocus
            default:
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.bgBody
            }
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: action)
        } else {
            action()
        }
    }

    func updateCellStyleForPad(animated: Bool, view: UIView) {
        let action: () -> Void = {
            switch (self.isHighlighted, self.isSelected) {
            case (_, true):
                view.backgroundColor = UIColor.ud.fillActive
            case (true, false):
                view.backgroundColor = UIColor.ud.fillFocus
            default:
                view.backgroundColor = UIColor.ud.bgBody
            }
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: action)
        } else {
            action()
        }
    }
}

// MARK: Default TableView Keyboard focus handling
/// default keyboard focus handler for a single result tableview
/// NOTE: you may need to call updateFocusForWillDisplay and resetKBFocus
protocol TableViewKeyBoardFocusHandler: KeyBoardFocusHandler {
    associatedtype FocusInfo = IndexPath
    /// 用于保存本页面键盘焦点的纯属性, 下面会封装检查
    /// NOTE: 当数据源变化后，焦点不一定有效，所以使用时需要校验有效性
    var _currentKBFocus: FocusInfo? { get set }
    var kbTableView: UITableView { get }
    func canHandleKeyBoard(in responder: UIResponder) -> Bool
    // optional command dependency
    var currentKBFocus: FocusInfo? { get set }
    /// can be called to reset focus, eg: reload data
    func resetKBFocus()
    func focusView(for info: FocusInfo) -> KeyBoardFocusable?
    func scrollToVisible(for focus: FocusInfo, animated: Bool)
    /// 默认返回IndexPath(0,0), 需要自己保证canFocus(info:)。否则有可能focus到错误的对象
    func firstFocusPosition() -> FocusInfo?
    func canFocus(info: FocusInfo) -> Bool
}
protocol MoreTableViewKeyBoardFocusHandler: TableViewKeyBoardFocusHandler {
    typealias FocusInfo = TableFocusInfo
    func showMore(section: Int) -> Bool
    func jumpMore(section: Int)
}

enum TableFocusInfo {
    case Cell(indexPath: IndexPath)
    case Footer(section: Int)
}

/// this extension put common logic, not known specific FocusInfo Type
extension TableViewKeyBoardFocusHandler {
    /// call this method to enable check hardware keyboard and focus on first row
    func observeKeyboardType() -> Disposable {
        if Display.pad {
            return ExternalKeyboardObserver.shared.hasExternalKeyboardRelay.observeOn(MainScheduler.instance)
            .bind { [weak self] value in
                self?.externalKeyboardChange(value: value)
            }
        }
        return Disposables.create()
    }

    func setCurrentKBFocus(_ value: FocusInfo?, animated: Bool) {
        assert(Thread.isMainThread, "should occur on main thread!")
        if let oldValue = _currentKBFocus {
            // NOTE: 目前数据源更新会reload, 所以即使不更新focus，旧值reload也会清理掉
            focusView(for: oldValue)?.setFocused(false, animated: animated)
        }
        _currentKBFocus = value
        if let newValue = value {
            if let view = focusView(for: newValue) {
                view.setFocused(true, animated: animated)
            }
            scrollToVisible(for: newValue, animated: animated) // will set focus when loaded
        }
    }
    var currentKBFocus: FocusInfo? {
        get { _currentKBFocus }
        set { setCurrentKBFocus(newValue, animated: true) }
    }
    func resetKBFocus() {
        if hasExternalKeyboard {
            if let focus = firstFocusPosition() {
                setCurrentKBFocus(focus, animated: false)
            }
        } else {
            self.currentKBFocus = nil
        }
    }

    /// 有外接键盘时，自动选中第一个, 目前仅在iPad上开启
    var hasExternalKeyboard: Bool { ExternalKeyboardObserver.shared.hasExternalKeyboard }
    func externalKeyboardChange(value: Bool) {
        if self.currentKBFocus == nil, value { self.resetKBFocus() }
    }
    func canFocus() -> Bool { !kbTableView.isHidden }
    func canHandle(binding: KeyBinding) -> Bool {
        let info = binding.info
        var isSpecialKey: Bool { // TODO: check virtual keyboard return
            info.input == UIKeyCommand.inputUpArrow || info.input == UIKeyCommand.inputDownArrow
        }
        var canHandleReturn: Bool {
            info.input == "\r" && hasExternalKeyboard
        }
        var validResponder: Bool {
            guard let responder = KeyboardKit.shared.firstResponder else { return true }
            return self.canHandleKeyBoard(in: responder)
        }
        var specialHandled: Bool {
            (isSpecialKey || canHandleReturn) && validResponder
        }
        return canFocus() && (KeyBinding.defaultTryHanlde(binding) || specialHandled)
    }
    func canFocus(info: FocusInfo) -> Bool { true }
    func updateFocus(info: FocusInfo, animated: Bool = true) -> Bool {
        if canFocus(info: info) {
            setCurrentKBFocus(info, animated: animated)
            return true
        }
        return false
    }
}

extension MoreTableViewKeyBoardFocusHandler {
    func updateFocusForWillDisplay(cell: UITableViewCell, at: IndexPath) {
        // set highlight in cellForRow will be overwritten of tableview configuration
        if case .Cell(indexPath: let focusPath) = currentKBFocus, focusPath == at {
            cell.setFocused(true)
        } else {
            cell.setFocused(false)
        }
    }
    func updateFocusForFooter(_ footer: KeyBoardFocusable, at section: Int) {
        if case .Footer(section: let focusSection) = currentKBFocus, focusSection == section {
            footer.setFocused(true, animated: false)
        } else {
            footer.setFocused(false, animated: false)
        }
    }
    func firstFocusPosition() -> FocusInfo? { .Cell(indexPath: IndexPath(row: 0, section: 0)) }
    func focusView(for info: FocusInfo) -> KeyBoardFocusable? {
        switch info {
        case .Cell(indexPath: let indexPath):
            return self.kbTableView.cellForRow(at: indexPath)
        case .Footer(section: let section):
            return self.kbTableView.footerView(forSection: section) as? KeyBoardFocusable
        }
    }
    // new showing view should check focus view
    func scrollToVisible(for focus: FocusInfo, animated: Bool) {
        guard canFocus(), valid(focus: focus) else { return }
        switch focus {
        case .Cell(indexPath: let path):
            self.kbTableView.scrollToRow(at: path, at: .none, animated: animated)
        case .Footer(section: let section):
            self.kbTableView.scrollRectToVisible(
                self.kbTableView.rectForFooter(inSection: section), animated: animated)
        }
    }
    func valid(focus: FocusInfo) -> Bool {
        switch focus {
        case .Cell(indexPath: let path):
            return path.section < kbTableView.numberOfSections && path.row < kbTableView.numberOfRows(inSection: path.section)
        case .Footer(section: let section):
            return section < kbTableView.numberOfSections && showMore(section: section)
        }
    }
    func handleKBDown() {
        guard canFocus() else { return }
        guard let currentKBFocus = currentKBFocus else {
            if let focus = firstFocusPosition() {
                self.currentKBFocus = focus
            }
            return
        }
        // 按顺序依次检查, 直到有效，或者到底
        func setNextValidValue(path: IndexPath) {
            var path = path
            // check section valid
            while path.section < kbTableView.numberOfSections {
                // check row valid
                if path.row < kbTableView.numberOfRows(inSection: path.section) {
                    if self.updateFocus(info: .Cell(indexPath: path)) { return }
                    path.row += 1
                    continue
                }
                // check more
                if showMore(section: path.section) {
                    if self.updateFocus(info: .Footer(section: path.section)) { return }
                    // fallthrough
                }
                // loop to check next section
                path.section += 1; path.row = 0
            }
            // 已经到最下面了..
        }
        switch currentKBFocus {
        case .Cell(indexPath: var path):
            path.row += 1
            setNextValidValue(path: path)
        case .Footer(section: let section):
            setNextValidValue(path: IndexPath(row: 0, section: section + 1))
        }
    }
    func handleKBUp() {
        guard canFocus() else { return }
        guard let currentKBFocus = currentKBFocus else {
            self.currentKBFocus = firstFocusPosition()
            return
        }
        // FIXME: 这个算高亮的逻辑比较绕，看能不能简化
        func setPreviousValue(path: IndexPath) {
            var path = path
            path.row -= 1
            while path.section >= 0 {
                guard path.row >= 0, path.section < kbTableView.numberOfSections else {
                    path.section -= 1
                    if path.section < 0 { break }
                    path.row = kbTableView.numberOfRows(inSection: path.section)
                    continue
                }
                let max = kbTableView.numberOfRows(inSection: path.section)
                if path.row < max {
                    // valid row
                    if self.updateFocus(info: .Cell(indexPath: path)) { return }
                    // fallthrough
                } else if showMore(section: path.section) {
                    // valid more
                    if self.updateFocus(info: .Footer(section: path.section)) { return }
                    // fallthrough
                }
                // invalid, minus until valid or to next section
                path.row -= 1
            }
            // 已经到最上面了
        }
        switch currentKBFocus {
        case .Cell(indexPath: let path):
            setPreviousValue(path: path)
        case .Footer(section: let section):
            let row: Int
            if section < kbTableView.numberOfSections {
                row = kbTableView.numberOfRows(inSection: section)
            } else {
                row = 0
            }
            setPreviousValue(path: IndexPath(row: row, section: section))
        }
    }
    func handleKBConfirm() {
        guard canFocus(), let currentKBFocus = currentKBFocus, valid(focus: currentKBFocus) else { return }

        if focusView(for: currentKBFocus) == nil {
            scrollToVisible(for: currentKBFocus, animated: false)
        }
        switch currentKBFocus {
        case .Cell(indexPath: let path):
            self.kbTableView.selectRow(at: path, animated: true, scrollPosition: .none)
            kbTableView.delegate?.tableView?(kbTableView, didSelectRowAt: path)
        case .Footer(section: let section):
            jumpMore(section: section)
        }
    }
}

extension TableViewKeyBoardFocusHandler where Self.FocusInfo == IndexPath {
    func updateFocusForWillDisplay(cell: UITableViewCell, at: IndexPath) {
        // set highlight in cellForRow will be overwritten of tableview configuration
        cell.setFocused(currentKBFocus == at)
    }

    // TODO: 优化默认实现，用KBDown找到第一个有效的焦点
    func firstFocusPosition() -> FocusInfo? { IndexPath(row: 0, section: 0) }
    // MARK: Following method not need to call by external

    func focusView(for info: FocusInfo) -> KeyBoardFocusable? {
        return self.kbTableView.cellForRow(at: info)
    }
    // new showing view should check focus view
    func scrollToVisible(for focus: FocusInfo, animated: Bool) {
        guard canFocus(), valid(focus: focus) else { return }
        self.kbTableView.scrollToRow(at: focus, at: .none, animated: animated)
    }
    func valid(focus path: FocusInfo) -> Bool {
        return path.section < kbTableView.numberOfSections && path.row < kbTableView.numberOfRows(inSection: path.section)
    }
    func handleKBDown() {
        guard canFocus() else { return }
        guard let currentKBFocus = currentKBFocus else {
            self.currentKBFocus = firstFocusPosition()
            return
        }
        // 按顺序依次检查, 直到有效，或者到底
        func setNextValidValue(path: IndexPath) {
            var path = path
            path.row += 1
            // check section valid
            while path.section < kbTableView.numberOfSections {
                // check row valid
                if path.row < kbTableView.numberOfRows(inSection: path.section) {
                    if self.updateFocus(info: path) { return }
                    path.row += 1
                    continue
                }
                // loop to check next section
                path.section += 1; path.row = 0
            }
            // 已经到最下面了..
        }
        setNextValidValue(path: currentKBFocus)
    }
    func handleKBUp() {
        guard canFocus() else { return }
        guard let currentKBFocus = currentKBFocus else {
            self.currentKBFocus = firstFocusPosition()
            return
        }
        // FIXME: 这个算高亮的逻辑比较绕，看能不能简化
        func setPreviousValue(path: IndexPath) {
            var path = path
            path.row -= 1
            while path.section >= 0 {
                guard path.row >= 0, path.section < kbTableView.numberOfSections else {
                    path.section -= 1
                    if path.section < 0 { break }
                    path.row = kbTableView.numberOfRows(inSection: path.section) - 1
                    continue
                }
                let max = kbTableView.numberOfRows(inSection: path.section)
                if path.row < max {
                    // valid row
                    if self.updateFocus(info: path) { return }
                    // fallthrough
                }
                // invalid, minus until valid or to next section
                path.row -= 1
            }
            // 已经到最上面了
        }
        setPreviousValue(path: currentKBFocus)
    }
    func handleKBConfirm() {
        guard canFocus(), let currentKBFocus = currentKBFocus, valid(focus: currentKBFocus) else { return }

        if focusView(for: currentKBFocus) == nil {
            scrollToVisible(for: currentKBFocus, animated: false)
        }
        self.kbTableView.selectRow(at: currentKBFocus, animated: true, scrollPosition: .none)
        kbTableView.delegate?.tableView?(self.kbTableView, didSelectRowAt: currentKBFocus)
    }
}
