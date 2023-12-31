//
//  UserPostCellManager.swift
//  Moment
//
//  Created by liluobin on 2021/3/12.
//

import Foundation
import UIKit
import LarkButton
import UniverseDesignEmpty
protocol UserTransitionCellManagerDelegate: AnyObject {
    func emptyBtnStyle() -> (String, TypeButton.Style?)?
    func emptyTitle() -> String
    func emptyType() -> UDEmptyType
    func emptyBtnClick()
}
final class UserTransitionCellManager {
    var firstScreenDataLoading = true
    var isEmptyData = false
    var showCornerForCell = false
    weak var delegate: UserTransitionCellManagerDelegate?
    func isTransitionStatus() -> Bool {
        return firstScreenDataLoading || isEmptyData
    }
    func cellHeight() -> CGFloat {
        if firstScreenDataLoading {
            return 200
        }
        if isEmptyData {
            return 347
        }
        return 0
    }

    func cellForTableView(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if firstScreenDataLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: PostSkeletonlTableViewCell.identifier, for: indexPath)
            addCornerForCell(cell, indexPath: indexPath)
            return cell
        }
        if isEmptyData {
            let cell = tableView.dequeueReusableCell(withIdentifier: UserPostEmptyCell.identifier, for: indexPath)
            if let emptyCell = cell as? UserPostEmptyCell {
                emptyCell.title = self.delegate?.emptyTitle() ?? ""
                emptyCell.emptyType = self.delegate?.emptyType() ?? .defaultPage
                emptyCell.emptyBtnStyle = self.delegate?.emptyBtnStyle()
                emptyCell.emptyBtnCallBack = { [weak self] in
                    self?.delegate?.emptyBtnClick()
                }
                emptyCell.updateUI()
            }
            return cell
        }
        return UITableViewCell()
    }

    func numberOfCell() -> Int {
        if firstScreenDataLoading {
            return FeedList.skeletonCellCount
        }
        if isEmptyData {
            return 1
        }
        return 0
    }

    /// 给cell添加圆角
    private func addCornerForCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        guard showCornerForCell else {
            return
        }
        let count = numberOfCell()
        if indexPath.row == 0 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            cell.clipsToBounds = true
        } else if indexPath.row == count - 1 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.clipsToBounds = true
        } else {
            cell.layer.cornerRadius = 0
            cell.layer.maskedCorners = []
            cell.clipsToBounds = false
        }
    }
}
