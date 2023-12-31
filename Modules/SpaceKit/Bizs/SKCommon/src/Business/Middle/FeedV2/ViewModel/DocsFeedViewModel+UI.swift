//
//  DocsFeedViewModel+UI.swift
//  SKCommon
//
//  Created by huayufan on 2022/1/11.
//  


import UIKit

extension DocsFeedViewModel: FeedRedDotDelegate {
    /// 需要结合本地已读记录来决定是否要显示红点
    func shouldDisplayRedDot(cell: UITableViewCell, data: FeedCellDataSource) -> Bool {
        let markRead = readedMessages[data.messageId] ?? false
        return data.showRedDot && !markRead
    }
}
