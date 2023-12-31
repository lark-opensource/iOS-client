//
//  SearchViewController+listSync.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/9/20.
//

import Foundation
import LarkUIKit
import EENavigator
import LarkSplitViewController

extension MailSearchCallBack: MailThreadListItemType {
    var threadId: String {
        return viewModel.threadId
    }

    var labels: [MailClientLabel] {
        get {
            return viewModel.labels
        }
        set {
            viewModel.labels = newValue
        }
    }

    var fullLabels: [String] {
        get {
            return viewModel.fullLabels
        }
        set {
            viewModel.fullLabels = newValue
        }
    }

    var folders: [String] {
        get {
            return viewModel.folders
        }
        set {
            viewModel.folders = newValue
        }
    }

    var messageId: String {
        get {
            return viewModel.messageId
        }
        set {
            viewModel.messageId = newValue
        }
    }
    
    var summary: String {
        get {
            return viewModel.msgSummary
        }
    }

    mutating func updateIsRead(isRead: Bool) {
        viewModel.isRead = isRead
    }

    mutating func updateIsFlagged(isFlagged: Bool) {
        viewModel.isFlagged = isFlagged
    }

    mutating func updateMsgCount(count: Int) {
        viewModel.msgNum = count
    }

    mutating func updateFolders(folders: [String]) {
        viewModel.folders = folders
    }

    mutating func updateMsgSummary(plainText: String) {
        viewModel.msgSummary = plainText
    }
}

extension MailSearchViewController: MailThreadListFullAbility {
    var currentNavigator: Navigatable {
        accountContext.navigator
    }

    /// list data items
    var threadItems: [MailThreadListItemType] {
        get {
            self.searchViewModel.getResultItems()
        }
        set {
            if let values = newValue as? [MailSearchCallBack] {
                self.searchViewModel.setResultItems(values)
            } else {
                assert(false, "could not set none CallbackItem Type")
            }
        }
    }

    var threadRemoteItems: [MailThreadListItemType] {
        get {
            self.searchViewModel.getRemoteResultItems()
        }
        set {
            if let values = newValue as? [MailSearchCallBack] {
                self.searchViewModel.setRemoteResultItems(values)
            } else {
                assert(false, "could not set none CallbackItem Type")
            }
        }
    }

    /// 当前的Label Id
    var currentLabelId: String {
        let fromLabelID: String = {
            if let filter = capsuleViewModel.capsulePage.selectedFilters.first(where: { $0.tagID != nil }),
               let tagID = filter.tagID {
                return tagID
            } else {
                return searchLabel
            }
        }()
        return fromLabelID
    }

    /// label id that should be filter
    var syncFilterLabelIds: [String] {
        if FeatureManager.open(.searchTrashSpam, openInMailClient: true) || FeatureManager.open(.searchFilter, openInMailClient: false) {
            return []
        } else {
            return [MailLabelId.Trash.rawValue, MailLabelId.Spam.rawValue]
        }
    }

    /// tableview
    var listTableView: UITableView {
        return resultView.tableview
    }

    // MARK: UI Action
    func showEmptyView() {
        if let searchText = self.searchField.text {
            if footer.checkTrashMail {
                self.resultView.status = .noNormalResult
            } else {
                self.resultView.status = .noResult
            }
            self.resultView.refreshNoResultView(searchText)
            self.exitMultiSelect()
            if Display.pad {
                navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            }
        }
    }

    func enterThread(at indexPath: IndexPath, scrollPosition: UITableView.ScrollPosition) {
        guard indexPath.row < searchViewModel.getSectionItems(indexPath.section).count else {
            return
        }
        resultView.tableview.selectRow(at: indexPath, animated: true, scrollPosition: scrollPosition)
        tableView(resultView.tableview, didSelectRowAt: indexPath)
    }
}
