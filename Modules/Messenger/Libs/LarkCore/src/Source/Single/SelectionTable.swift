//
//  SelectionTable.swift
//  LarkCore
//
//  Created by 李晨 on 2020/12/17.
//

import UIKit
import Foundation
import LarkKeyCommandKit

// 支持 table ↑↓ 快捷键选中协议
protocol SelectionTable: AnyObject {
    var selectionTable: UITableView { get }
}
extension SelectionTable {
    public func selectionKeyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: []
            ).binding(
                tryHandle: { _ in true },
                handler: { [weak self] in
                    self?.enterKeyCommand()
                }
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: []
            ).binding(
                tryHandle: { _ in true },
                handler: { [weak self] in
                    self?.upKeyCommand()
                }
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: []
            ).binding(
                tryHandle: { _ in true },
                handler: { [weak self] in
                    self?.downKeyCommand()
                }
            ).wraper
        ]
    }

    func upKeyCommand() {
        if let index = findPrevIndex() {
            selectionTable.selectRow(at: index, animated: true, scrollPosition: .middle)
        }
    }

    func downKeyCommand() {
        if let index = findNextIndex() {
            self.selectionTable.selectRow(at: index, animated: true, scrollPosition: .middle)
        }
    }

    func enterKeyCommand() {
        if let selectIndex = self.selectionTable.indexPathForSelectedRow {
            self.selectionTable.delegate?.tableView?(
                self.selectionTable,
                didSelectRowAt: selectIndex
            )
        }
    }

    func findPrevIndex() -> IndexPath? {
        if let selectIndex = selectionTable.indexPathForSelectedRow {
            let section = selectIndex.section
            let row = selectIndex.row
            if row > 0 {
                return IndexPath(row: row - 1, section: section)
            } else {
                var prevSection = section - 1
                while prevSection >= 0 {
                    let number = selectionTable.numberOfRows(inSection: prevSection)
                    if number > 0 {
                        return IndexPath(row: number - 1, section: prevSection)
                    }
                    prevSection -= 1
                }
            }
        }
        return nil
    }

    func findNextIndex() -> IndexPath? {
        let sectionNumber = selectionTable.numberOfSections

        if let selectIndex = selectionTable.indexPathForSelectedRow {
            let section = selectIndex.section
            let row = selectIndex.row
            let number = selectionTable.numberOfRows(inSection: section)
            if row < number - 1 {
                return IndexPath(row: row + 1, section: section)
            } else {
                var nextSection = section + 1
                while nextSection < sectionNumber {
                    let number = selectionTable.numberOfRows(inSection: nextSection)
                    if number > 0 {
                        return IndexPath(row: 0, section: nextSection)
                    }
                }
                nextSection += 1
            }
        } else {
            return IndexPath(row: 0, section: 0)
        }

        return nil
    }
}
