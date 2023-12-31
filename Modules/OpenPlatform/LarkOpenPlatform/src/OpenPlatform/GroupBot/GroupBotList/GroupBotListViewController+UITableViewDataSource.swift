//
//  GroupBotListViewController+UITableViewDataSource.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import UIKit

// MARK: -UITableViewDataSource
extension GroupBotListViewController {
    func _tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let model = viewModel else {
            Self.logger.info("viewModel is emtpy, show page failed")
            return 0
        }
        return model.getDataGroup(in: section).count
    }

    func _tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// 获取cell
        let cell = (tableView.dequeueReusableCell(withIdentifier: GroupBotListPageCell.CellConfig.cellID)) as? GroupBotListPageCell ??
            GroupBotListPageCell(style: .default, reuseIdentifier: GroupBotListPageCell.CellConfig.cellID)
        /// 获取数据
        guard let model = viewModel, let itemList = viewModel?.getDataGroup(in: indexPath.section), indexPath.row < itemList.count else {
            Self.logger.error("get item info failed with indexPath:\(indexPath)")
            return cell
        }
        /// 刷新cell
        let isLastCellInSection = (indexPath.row == itemList.count - 1)
        cell.refresh(
            viewModel: itemList[indexPath.row],
            isLastCellInSection: isLastCellInSection
        )
        return cell
    }

    func _numberOfSections(in tableView: UITableView) -> Int {
        guard let model = viewModel else {
            Self.logger.info("viewModel is emtpy, show page failed")
            return 0
        }
        return model.getDataGroupCount()
    }
}
