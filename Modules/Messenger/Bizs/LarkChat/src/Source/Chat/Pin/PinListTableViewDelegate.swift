//
//  PinListTableViewDelegate.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/24.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkCore
import LarkMessageBase
import LarkMessageCore

final class PinListTableViewDelegateImpl: PinListSearchDisplayControl, UITableViewDelegate, UITableViewDataSource {
    private let viewModel: PinListViewModel
    private unowned let targetVC: UIViewController

    weak var tableView: PinListTableView? {
        didSet {
            tableView?.delegate = self
            tableView?.dataSource = self
            tableView?.pinListTableDelegate = self
        }
    }

    init(viewModel: PinListViewModel, targetVC: UIViewController) {
        self.viewModel = viewModel
        self.targetVC = targetVC
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.pinUIDataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = self.viewModel.pinUIDataSource[indexPath.row]
        let cellId = (cellVM as? HasMessage)?.message.id ?? ""
        return cellVM.dequeueReusableCell(tableView, cellId: cellId)
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.pinUIDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.pinUIDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let cellVM = self.viewModel.pinUIDataSource[indexPath.row]
        if let message = (cellVM as? HasMessage)?.message {
            ChatTracker.trackClickPin(
                message: message,
                groupId: self.viewModel.chat.id,
                isGroupOwner: self.viewModel.dependency.currentChatterId == self.viewModel.chat.ownerId,
                jumpToChat: true,
                location: .inChatPin
            )
        }
        cellVM.didSelect()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.viewModel.dependency.pinBadgeEnable,
            let cellVM = self.viewModel.pinUIDataSource[indexPath.row] as? PinMessageCellViewModel,
            self.viewModel.needShowHighlight(source: cellVM) {
            (cell as? PinListCell)?.highlight()
        }
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            self.viewModel.pinUIDataSource[indexPath.row].willDisplay()
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.viewModel.dependency.pinBadgeEnable,
            indexPath.row < self.viewModel.pinUIDataSource.count,
            let cellVM = self.viewModel.pinUIDataSource[indexPath.row] as? PinMessageCellViewModel {
            self.viewModel.resetShowHighlightIfNeeded(source: cellVM)
        }
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            self.viewModel.pinUIDataSource[indexPath.row].didEndDisplay()
        }
    }

    @objc
    func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let tableView = self.tableView else {
            return
        }
        switch gesture.state {
        case .began:
            let location = gesture.location(in: self.tableView)
            guard let indexPath = tableView.indexPathForRow(at: location),
                let cellVM = self.viewModel.pinUIDataSource[indexPath.row] as? PinMessageCellViewModel else {
                    return
            }
            cellVM.showMenu(location: location, view: self.tableView ?? UIView())
        default:
            break
        }
    }
}

extension PinListTableViewDelegateImpl: PinListTableViewDelegate {
    func loadMorePins(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.loadMorePins(finish: finish)
    }

    var uiDataSource: [PinCellViewModel] {
        return self.viewModel.pinUIDataSource
    }
}
