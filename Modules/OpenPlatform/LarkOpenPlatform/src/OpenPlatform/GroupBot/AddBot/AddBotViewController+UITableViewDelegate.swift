//
//  AddBotViewController+UITableViewDelegate.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import LarkUIKit
import LarkMessengerInterface
import EENavigator

// MARK: - UITableViewDelegate
extension AddBotViewController {
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
        // select action
        if let model = cellModel.data as? GroupBotModel {
            guard let botID = model.botID else {
                Self.logger.error("get botID failed with indexPath:\(indexPath)")
                return
            }
            let fromWhere: PersonCardFromWhere = (model.isInvited ?? false) ? .groupBotToRemove : .groupBotToAdd
            let extraParams: [String: String] = [
                groupBotExtraInfoKeyBotType: model.botType.rawValue.description
            ]
            let body = PersonCardBody(chatterId: botID, chatId: chatID, fromWhere: fromWhere, extraParams: extraParams)
            self.resolver.navigator.presentOrPush(
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
                    .appName: model.name ?? "",
                    .appID: model.botID ?? "",
                    .botType: model.botType.rawValue
                ])
                .report()
            return
        } else if let model = cellModel.data as? RecommendBotModel {
            self.openAppTableDetail(botModel: model)
        }
    }

    /// cell高度
    func _tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddBotPageCell.CellConfig.cellHeight
    }
    
    /// headerView
    func _tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let model = viewModel else {
            Self.logger.info("viewModel is emtpy, show page failed")
            return nil
        }
        if model.isShowHeader(at: section) {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: AddBotPageRecommendHeaderView.headerReuseID) as? AddBotPageRecommendHeaderView else {
                Self.logger.error("headerView is not registered")
                return nil
            }
            /// 针对是否包含已经安装的机器人，展示不同文案
            var hasNoInstalledBots = false
            if model.isDataEmpty(at: 0) {
                hasNoInstalledBots = true
            }
            headerView.updateViews(hasNoInstalledBots: hasNoInstalledBots)
            return headerView
        } else {
            return nil
        }
    }

    /// header高度
    func _tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let model = viewModel else {
            Self.logger.info("viewModel is emtpy, show page failed")
            return CGFloat.zero
        }
        if model.isShowHeader(at: section) {
            // 可用应用列表自适应高度
            return UITableView.automaticDimension
        }
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
        if model.isDataEmpty(at: section) {
            return CGFloat.zero
        }
        let emptyHeight: CGFloat = 7.0
        return emptyHeight + model.getBottomSafeInset(at: section)
    }
}
