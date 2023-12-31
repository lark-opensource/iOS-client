//
//  BaseFeedsViewController+iPadKeyBind.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/5.
//

import UIKit
import Foundation
import LarkKeyCommandKit

/// For iPad 快捷键绑定
extension BaseFeedsViewController {
    func selectFeedKeyCommand() -> [KeyBindingWraper] {
        var commands = [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: [],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcutsPreviousMessage
            ).binding(
                target: self,
                selector: #selector(selectPrevForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcusNextMessage
            ).binding(
                target: self,
                selector: #selector(selectNextForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: [.command],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcutsPreviousMessage
            ).binding(
                target: self,
                selector: #selector(selectPrevForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [.command],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcusNextMessage
            ).binding(
                target: self,
                selector: #selector(selectNextForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: [.command, .shift],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_NewSettings_ShortcutSwitchPreviousUnreadChat
            ).binding(
                target: self,
                selector: #selector(selectPrevUnreadForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [.command, .shift],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_NewSettings_ShortcutSwitchNextUnreadChat
            ).binding(
                target: self,
                selector: #selector(selectNextUnreadForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: "[",
                modifierFlags: [.command],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_NewSettings_ShortcutSwitchPreviousViewedChat
            ).binding(
                target: self,
                selector: #selector(selectPrevRecordForKC)
            ).wraper,
            KeyCommandBaseInfo(
                input: "]",
                modifierFlags: [.command],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_NewSettings_ShortcutSwitchNextViewedChat
            ).binding(
                target: self,
                selector: #selector(selectNextRecordForKC)
            ).wraper
        ]
        if let viewModel = self.feedsViewModel.findCurrentSelectedVM(),
           viewModel.leftActionTypes.contains(.done) {
            commands.append(
                KeyCommandBaseInfo(
                    input: "d",
                    modifierFlags: .command,
                    discoverabilityTitle: BundleI18n.LarkFeed.Lark_NewSettings_ShortcutMarkAsDone
                ).binding(
                    target: self,
                    selector: #selector(markCurrentFeedForDone)
                ).wraper
            )
        }
        return commands
    }

    func selectPrevFeedForPad() {
        if let (feedId, index) = feedsViewModel.findNextFeedForKeyCommand(arrowUp: true) {
            selectFeedForKC(feedId: feedId, index: index)
        }
    }

    func selectNextFeedForPad() {
        if let (feedId, index) = feedsViewModel.findNextFeedForKeyCommand(arrowUp: false) {
            selectFeedForKC(feedId: feedId, index: index)
        }
    }

    func selectPrevUnreadFeedForPad() {
        if let (feedId, index) = feedsViewModel.findUnreadFeedForKeyCommand(arrowUp: true) {
            selectFeedForKC(feedId: feedId, index: index)
        }
    }

    func selectNextUnreadFeedForPad() {
        if let (feedId, index) = feedsViewModel.findUnreadFeedForKeyCommand(arrowUp: false) {
            selectFeedForKC(feedId: feedId, index: index)
        }
    }

    func selectPrevFeedRecordForPad() {
        if let (feedId, index) = feedsViewModel.findFeedRecordForKeyCommand(arrowUp: true) {
            selectFeedForKC(feedId: feedId, index: index)
        }
    }

    func selectNextFeedRecordForPad() {
        if let (feedId, index) = feedsViewModel.findFeedRecordForKeyCommand(arrowUp: false) {
            selectFeedForKC(feedId: feedId, index: index)
        }
    }

    func markCurrentFeedDoneForPad() {
        if let viewModel = self.feedsViewModel.findCurrentSelectedVM() {
            self.markForDone(viewModel)
        }
    }

    private func selectFeedForKC(feedId: String, index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        self.tableView.delegate?.tableView?(self.tableView,
                                            didSelectRowAt: indexPath)
        feedsViewModel.setSelected(feedId: feedId)
    }
}
