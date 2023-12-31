//
//  AIChatTableView.swift
//  LarkChat
//
//  Created by ByteDance on 2023/12/13.
//

import Foundation
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import RxSwift

class AIChatTableView: ChatTableView {
    private var containerViewControllerIsShow: Bool = false
    override init(userResolver: UserResolver, isOnlyReceiveScroll: Bool, keepOffset: @escaping () -> Bool, chatFromWhere: ChatFromWhere) {
        super.init(userResolver: userResolver,
                   isOnlyReceiveScroll: isOnlyReceiveScroll,
                   keepOffset: keepOffset,
                   chatFromWhere: chatFromWhere)

        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                if self?.containerViewControllerIsShow ?? false {
                    self?.visibleCellsShow()
                }
            }).disposed(by: self.disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                if self?.containerViewControllerIsShow ?? false {
                    self?.visibleCellsEndShow()
                }
            }).disposed(by: self.disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func containerViewControllerDidAppear() {
        self.containerViewControllerIsShow = true
        self.visibleCellsShow()
    }

    func containerViewControllerDidDisappear() {
        self.containerViewControllerIsShow = false
        self.visibleCellsEndShow()
    }

    private func visibleCellsShow() {
        let cellCount = self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if indexPath.row < cellCount {
                if let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? HasMessage {
                    self.messageShowTracker?.startShow(messsage: cellVM.message)
                }
            } else {
                assertionFailure("indexPath out range \(indexPath), please save the context to contact Zhao Chen troubleshooting repair")
            }
        }
    }

    private func visibleCellsEndShow() {
        let cellCount = self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if indexPath.row < cellCount {
                if let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? HasMessage {
                    self.messageShowTracker?.endShow(messsage: cellVM.message)
                }
            } else {
                assertionFailure("indexPath out range \(indexPath), please save the context to contact Zhao Chen troubleshooting repair")
            }
        }
    }

    lazy private var messageShowTracker: AIMessageShowTracker? = {
        guard let aiChatterId = try? self.userResolver.resolve(assert: MyAIService.self).info.value.id else {
            ChatTableView.logger.error("can not get aiChatterId \(self.chatTableDataSourceDelegate?.chat.id ?? "")")
            return nil
        }
        return AIMessageShowTracker(chat: self.chatTableDataSourceDelegate?.chat,
                                    aiChatterId: aiChatterId)
    }()

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        guard self.willDisplayEnable else {
            return
        }
        // 在屏幕内的才触发vm的willDisplay
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            if let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? HasMessage {
                self.messageShowTracker?.startShow(messsage: cellVM.message)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
        if !(self.indexPathsForVisibleRows?.contains(indexPath) ?? false),
           let cell = cell as? MessageCommonCell,
           let cellVM = self.chatTableDataSourceDelegate?.cellViewModel(by: cell.cellId) as? HasMessage {
            self.messageShowTracker?.endShow(messsage: cellVM.message)
        }
    }
}
