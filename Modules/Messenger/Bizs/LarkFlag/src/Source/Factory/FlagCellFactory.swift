//
//  FlagCellFactory.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkContainer
import LarkMessengerInterface
import LarkSwipeCellKit
import LarkOpenFeed

public protocol FlagCellFactory {
    func dequeueReusableCell(with identifier: String,
                             screenWidth: CGFloat,
                             flagItem: FlagItem) -> SwipeTableViewCell
}

public final class FlagListCellFactory: FlagCellFactory {

    var tableView: UITableView

    fileprivate let dispatcher: RequestDispatcher

    public init(dispatcher: RequestDispatcher, tableView: UITableView) {
        self.tableView = tableView
        self.dispatcher = dispatcher
        // 注册Message类型的Cell
        self.registerMessageCellTypes(self.tableView)
        // 注册Feed类型的Cell
        FeedCardContext.registerCell?(tableView, dispatcher.userResolver)
    }

    func registerMessageCellTypes(_ tableView: UITableView) {
        let classes: [FlagMessageCell.Type] = [
            FlagUnknownMessageCell.self,
            FlagPostMessageCell.self,
            FlagImageMessageCell.self,
            FlagLocationMessageCell.self,
            FlagVideoMessageCell.self,
            FlagStickerMessageCell.self,
            FlagFileMessageCell.self,
            FlagFolderMessageCell.self,
            FlagAudioMessageCell.self,
            FlagMergeForwardMessageCell.self,
            FlagMergeForwardPostCardMessageCell.self,
            FlagRecallMessageCell.self,
            FlagMessageComponentCell.self
        ]
        classes.forEach { (cls) in
            tableView.register(cls, forCellReuseIdentifier: cls.identifier)
        }
    }

    public func dequeueReusableCell(with identifier: String,
                                    screenWidth: CGFloat,
                                    flagItem: FlagItem) -> SwipeTableViewCell {
        if flagItem.type == .message, let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FlagMessageCell, let messageVM = flagItem.messageVM {
            cell.dispatcher = dispatcher
            cell.viewModel = messageVM
            (cell as? FlagPostMessageCell)?.screenWidth = screenWidth
            return cell
        } else if flagItem.type == .feed, let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FeedCardCellInterface, let feedVM = flagItem.feedVM {
            cell.set(cellViewModel: feedVM)
            return cell
        }
        return BaseFlagListTableCell()
    }
}
