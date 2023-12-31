//
//  GroupBotListViewController+UITableViewDelegate.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LarkUIKit
import LarkMessengerInterface
import EENavigator

// MARK: - UITableViewDelegate
extension GroupBotListViewController {
    /// cell点击事件
    func _tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            Self.logger.error("tableView.cellForRow:\(indexPath) is nil")
            return
        }
        /// 获取数据
        guard let itemList = viewModel?.getDataGroup(in: indexPath.section), indexPath.row < itemList.count else {
            Self.logger.error("get item info failed with indexPath:\(indexPath)")
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let cellModel = itemList[indexPath.row]
        let botModel = cellModel.data
        // select action
        guard let botID = botModel.botID else {
            Self.logger.error("get botID failed with indexPath:\(indexPath)")
            return
        }
        let extraParams: [String: String] = [
            groupBotExtraInfoKeyBotType: botModel.botType.rawValue.description
        ]
        let body = PersonCardBody(chatterId: botID, chatId: chatID, fromWhere: .groupBotToRemove, extraParams: extraParams)
        resolver.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            }
        )

        TeaReporter(eventKey: TeaReporter.key_groupbot_visit_detail)
            .withDeviceType()
            .withUserInfo(resolver: resolver)
            .withInfo(params: [
                .isExternal: isCrossTenant,
                .appName: botModel.name ?? "",
                .appID: botModel.botID ?? "",
                .botType: botModel.botType.rawValue
            ])
            .report()
    }

    /// cell高度
    func _tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return GroupBotListPageCell.CellConfig.cellHeight
    }

    /// headerView
    func _tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    /// header高度
    func _tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.zero
    }

    /// footerView
    func _tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    /// footer高度
    func _tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let model = viewModel else {
            Self.logger.info("viewModel is emtpy, show page failed")
            return CGFloat.zero
        }
        let emptyHeight: CGFloat = 7.0
        return emptyHeight + model.getBottomSafeInset(at: section)
    }
}
