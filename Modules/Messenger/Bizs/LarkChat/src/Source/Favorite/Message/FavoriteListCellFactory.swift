//
//  FavoriteListCellFactory.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import LarkContainer

public protocol FavoriteCellFactory {
    func dequeueReusableCell(with identifier: String,
                             maxContentWidth: CGFloat,
                             viewModel: FavoriteCellViewModel) -> UITableViewCell
}

public final class FavoriteDetailCellFactory: FavoriteListCellFactory {
    override func register(tableView: UITableView) {
        let classes: [FavoriteDetailCell.Type] = [
            FavoriteUnknownDetailCell.self,
            NewFavoritePostMessageDetailCell.self,
            FavoriteImageMessageDetailCell.self,
            FavoriteLocationMessageDetailCell.self,
            FavoriteVideoMessageDetailCell.self,
            FavoriteStickerMessageDetailCell.self,
            FavoriteFileMessageDetailCell.self,
            FavoriteFolderMessageDetailCell.self,
            FavoriteAudioMessageDetailCell.self,
            FavoriteMergeForwardMessageDetailCell.self
        ]
        classes.forEach { (cls) in
            tableView.register(cls, forCellReuseIdentifier: cls.identifier)
        }
    }

    override public func dequeueReusableCell(with identifier: String,
                                             maxContentWidth: CGFloat,
                                             viewModel: FavoriteCellViewModel) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FavoriteDetailCell {
            cell.dispatcher = dispatcher
            cell.viewModel = viewModel
            (cell as? NewFavoritePostMessageDetailCell)?.maxWidth = maxContentWidth
            return cell
        }

        return FavoriteListCell()
    }
}

public class FavoriteListCellFactory: FavoriteCellFactory {
    var tableView: UITableView

    fileprivate let dispatcher: RequestDispatcher

    public init(
        dispatcher: RequestDispatcher,
        tableView: UITableView
    ) {
        self.tableView = tableView
        self.dispatcher = dispatcher
        self.register(tableView: self.tableView)
    }

    func register(tableView: UITableView) {
        let classes: [FavoriteListCell.Type] = [
            FavoriteUnknownCell.self,
            NewFavoritePostMessageCell.self,
            FavoriteImageMessageCell.self,
            FavoriteLocationMessageCell.self,
            FavoriteVideoMessageCell.self,
            FavoriteStickerMessageCell.self,
            FavoriteFileMessageCell.self,
            FavoriteFolderMessageCell.self,
            FavoriteAudioMessageCell.self,
            FavoriteMergeForwardMessageCell.self,
            FavoriteMergeForwardPostCardMessageCell.self
        ]
        classes.forEach { (cls) in
            tableView.register(cls, forCellReuseIdentifier: cls.identifier)
        }
    }

    public func dequeueReusableCell(with identifier: String,
                                    maxContentWidth: CGFloat,
                                    viewModel: FavoriteCellViewModel) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FavoriteListCell {
            cell.bubbleContentMaxWidth = maxContentWidth - 2 * cell.contentInset
            cell.dispatcher = dispatcher
            cell.viewModel = viewModel
            return cell
        }

        return FavoriteListCell()
    }
}
