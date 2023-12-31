//
//  AddBotViewController+UITableViewDataSource.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import UIKit
import RoundedHUD

// MARK: - UITableViewDataSource
extension AddBotViewController {
    func _tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let model = viewModel else {
            Self.logger.info("viewModel is emtpy, show page failed")
            return 0
        }
        return model.getDataGroup(in: section).count
    }

    func _tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// 获取cell
        let cell = (tableView.dequeueReusableCell(withIdentifier: AddBotPageCell.CellConfig.cellID)) as? AddBotPageCell ??
            AddBotPageCell(style: .default, reuseIdentifier: AddBotPageCell.CellConfig.cellID)
        /// 获取数据
        guard let itemList = viewModel?.getDataGroup(in: indexPath.section), indexPath.row < itemList.count else {
            Self.logger.error("get item info failed with indexPath:\(indexPath)")
            return cell
        }
        /// 刷新cell
        let isLastCellInSection = (indexPath.row == itemList.count - 1)
        let (_, searchText) = isSearchingMode()
        cell.refresh(
            viewModel: itemList[indexPath.row],
            isLastCellInSection: isLastCellInSection,
            searchText: searchText,
            buttonEvent: { [weak self] viewModel in
                // action
                guard let self = self else {
                    Self.logger.error("AddBotViewController: self is nil")
                    return
                }
                let botModel = viewModel.data
                if viewModel.canAddToGroup {
                    let chatID = self.chatID
                    let window = self.view.window
                    let isCrossTenant = self.isCrossTenant
                    self.dataProvider.addBotToGroup(botModel: botModel, chatID: chatID, completion: { [weak self] result in
                        guard let self = self else {
                            return
                        }
                        let success = result.success
                        if success {
                            self.gotoChat(chatID: chatID)

                            if let model = botModel as? GroupBotModel {
                                TeaReporter(eventKey: TeaReporter.key_groupbot_addbot_success)
                                    .withDeviceType()
                                    .withUserInfo(resolver: self.resolver)
                                    .withInfo(params: [
                                        .isExternal: isCrossTenant,
                                        .appName: model.name ?? "",
                                        .appID: model.botID ?? "",
                                        .botType: model.botType.rawValue
                                    ])
                                    .report()
                            }
                        } else {
                            if let window = window {
                                RoundedHUD.showFailure(with: result.errorMessageToShow ?? BundleI18n.GroupBot.Lark_GroupBot_AddBotFailed, on: window)
                            }
                        }
                    })
                } else if viewModel.canRecommendToGroup {
                    self.openAppTableInstall(botModel: botModel)
                }
            }
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
