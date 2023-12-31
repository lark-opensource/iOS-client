//
//  SearchPinListTableViewDelegate.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkCore
import LarkMessageBase
import EENavigator

final class SearchPinListTableViewDelegate: PinListSearchDisplayControl, UITableViewDelegate, UITableViewDataSource {
    private let viewModel: PinListViewModel
    private unowned let targetVC: UIViewController

    weak var tableView: UITableView? {
        didSet {
            tableView?.delegate = self
            tableView?.dataSource = self
            tableView?.register(SearchPinListTableViewCell.self,
                                forCellReuseIdentifier: String(describing: SearchPinListTableViewCell.self))
        }
    }

    init(viewModel: PinListViewModel, targetVC: UIViewController) {
        self.viewModel = viewModel
        self.targetVC = targetVC
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.searchUIDataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = self.viewModel.searchUIDataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchPinListTableViewCell.self), for: indexPath)
        if let cell = cell as? SearchPinListTableViewCell {
            cell.update(cellVM)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        ChatTracker.trackChatPinSearchClick()
        tableView.deselectRow(at: indexPath, animated: true)
        self.viewModel.saveSearchCache(visitedIndex: indexPath)
        let cellVM = self.viewModel.searchUIDataSource[indexPath.row]
        cellVM.toNextPage(from: self.targetVC)
    }
}
