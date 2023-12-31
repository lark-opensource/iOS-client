//
//  MoreAppListViewController+UICollectionViewDataSource.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/8.
//

import LKCommonsLogging
import LarkUIKit
import EENavigator
import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import LarkAlertController
import LarkOPInterface
import LarkMessengerInterface
import LarkAppLinkSDK
import RustPB
import LarkRustClient
import LarkModel
import EEMicroAppSDK
import RoundedHUD
import UniverseDesignDialog
import UniverseDesignStyle

// MARK: - UICollectionViewDataSource
extension MoreAppListViewController {
    func _numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is emtpy, show page failed")
            return 0
        }
        return model.getSectionCount()
    }

    func _collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is emtpy, show page failed")
            return 0
        }
        return model.getSectionDataList(in: section).count
    }

    func _collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        /// 获取cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MoreAppCollectionViewCell.cellIdentifier, for: indexPath) as? MoreAppCollectionViewCell ??
            MoreAppCollectionViewCell()
        /// 获取数据
        guard let _ = viewModel, let itemList = viewModel?.getSectionDataList(in: indexPath.section), indexPath.row < itemList.count else {
            GuideIndexPageVCLogger.error("get item info failed with indexPath:\(indexPath)")
            return cell
        }
        /// 刷新cell
        let cellViewModel = itemList[indexPath.row]
        cell.refresh(
            bizScene: bizScene,
            sectionMode: cellViewModel.sectionMode,
            isReachToMaxCommonItems: isReachToMaxCommonItems(),
            onlyPCAvailable: (cellViewModel.data.mobileAvailable == false),
            viewModel: cellViewModel,
            buttonEvent: { [weak self] viewModel in
                if viewModel.sectionMode == .availabelList {
                    self?.addAppToExternal(cellViewModel: viewModel)
                } else if viewModel.sectionMode == .externalList {
                    self?.removeAppFromExternal(cellViewModel: viewModel)
                }
            },
            moreDescriptionClickEvent: { [weak self] viewModel in
                self?.openAppProfile(cellViewModel: viewModel)
            }
        )
        return cell
    }

    /// 常用个数限制检查
    func isReachToMaxCommonItems() -> Bool {
        guard let viewModel = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is emtpy, show page failed")
            return false
        }
        let maxCount = getMaxCommonItems()
        if let currentCount = viewModel.data.externalItemListModel.externalItemList?.count, currentCount >= maxCount {
            return true
        }
        return false
    }

    /// 常用项最大允许个数
    func getMaxCommonItems() -> Int {
        let maxCount = viewModel?.data.externalItemListModel.maxCommonItems ?? 3
        return maxCount
    }

    func addAppToExternal(cellViewModel: MoreAppListCellViewModel) {
        guard let viewModel = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is emtpy, show page failed")
            return
        }
        // 添加个数限制检查
        let maxCount = getMaxCommonItems()
        if isReachToMaxCommonItems() {
            if let window = self.view.window {
                RoundedHUD.showTips(with: BundleI18n.MessageAction.Lark_OpenPlatform_ScMaxFreqAppsMsg(max_count: maxCount), on: window)
            }
            return
        }
        // 从「更多」中添加后，放到「常用」的最下面
        var collection: [MoreAppItemModel] = []
        if let externalItemList = viewModel.data.externalItemListModel.externalItemList {
            // 过滤重复点击
            if (externalItemList.contains(cellViewModel.data)) {
                GuideIndexPageVCLogger.warn("filter reclick to add the same item: \(cellViewModel.data)")
                return
            }
            collection.append(contentsOf: externalItemList)
        }
        collection.append(cellViewModel.data)
        var newAvailableItemList: [MoreAppItemModel] = []
        if let availableItemList = viewModel.data.availableItemListModel.availableItemList {
            for item in availableItemList {
                if item != cellViewModel.data {
                    newAvailableItemList.append(item)
                }
            }
        }
        updateRemoteExternalItemListDataAndRefreshUI(externalItemList: collection, availableItemList: newAvailableItemList)
    }

    func removeAppFromExternal(cellViewModel: MoreAppListCellViewModel) {
        guard let viewModel = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is emtpy, show page failed")
            return
        }
        var collection: [MoreAppItemModel] = []
        if let externalItemList = viewModel.data.externalItemListModel.externalItemList {
            for item in externalItemList {
                if item != cellViewModel.data {
                    collection.append(item)
                }
            }
        }
        // 从「常用」中移除后，放到「更多」的最上面
        var newAvailableItemList: [MoreAppItemModel] = []
        newAvailableItemList.append(cellViewModel.data)
        if let availableItemList = viewModel.data.availableItemListModel.availableItemList {
            // 过滤重复点击
            if (availableItemList.contains(cellViewModel.data)) {
                GuideIndexPageVCLogger.warn("filter reclick to remove the same item: \(cellViewModel.data)")
                return
            }
            newAvailableItemList.append(contentsOf: availableItemList)
        }
        updateRemoteExternalItemListDataAndRefreshUI(externalItemList: collection, availableItemList: newAvailableItemList)
    }

    /// 点击+或者-时，请求后端。在请求失败或网络问题时，显示报错提醒；如果操作成功，则刷新数据和界面
    func updateRemoteExternalItemListDataAndRefreshUI(externalItemList: [MoreAppItemModel], availableItemList: [MoreAppItemModel]) {
        self.userActionBasedExternalItemList = externalItemList
        updateRemoteExternalItemListData(externalItemList: externalItemList) { [weak self] (isSuccess) in
            guard let `self` = self else { return }
            if isSuccess {
                if self.userActionBasedExternalItemList == externalItemList  {
                    self.reorderDataAndRefreshUI(newExternalItemList: externalItemList, shouldUpdateAvailableIteList: true, newAvailableItemList: availableItemList)
                    return
                }
            }
            self.userActionBasedExternalItemList = self.viewModel?.data.externalItemListModel.externalItemList
        }
    }

    /**
    - 点击 应用名称，可查看应用介绍：
      - 商店应用：打开应用目录的介绍页面
      - 自建应用：打开应用的Profile页

     端上逻辑：有字段返回就通过applink打开，没有就端上打开profile页
     */
    func openAppProfile(cellViewModel: MoreAppListCellViewModel) {
        guard let applinkUrl = cellViewModel.data.appstoreDetailApplink, let url = applinkUrl.possibleURL() else {
            GuideIndexPageVCLogger.info("appLinkUrl invalid with data: \(cellViewModel.data)")
            // 点击自建应用，显示查看详情弹窗
            let config = UDDialogUIConfig(cornerRadius:UDStyle.moreLargeRadius, style: .vertical)
            let dialog = UDDialog(config: config)
            // 判断帮助文档是否为空
            let helpDocURL: URL? = cellViewModel.data.helpDoc?.possibleURL()
            let isHelpDocURLEmpty = (helpDocURL == nil)
            let description = isHelpDocURLEmpty ? BundleI18n.MessageAction.Lark_OpenPlatform_ScMblViewAppInfoNoDocs : BundleI18n.MessageAction.Lark_OpenPlatform_ScMblViewAppInfoWithDocs
            dialog.setContent(text: description)
            let contactDeveloperBlock: () -> Void = {
                if let developerUserId = cellViewModel.data.developerUserId {
                    self.gotoChat(userID: developerUserId)
                }
            }
            let viewHelpDocBlock: () -> Void = {
                if let url = helpDocURL {
                    self.openHelpDoc(helpDocURL: url)
                }
            }
            if isHelpDocURLEmpty {
                dialog.addPrimaryButton(text: BundleI18n.MessageAction.Lark_OpenPlatform_ScMblContactDevBttn, dismissCompletion: contactDeveloperBlock)
                dialog.addSecondaryButton(text: BundleI18n.MessageAction.Lark_OpenPlatform_ScIGotItBttn)
            } else {
                dialog.addPrimaryButton(text: BundleI18n.MessageAction.Lark_OpenPlatform_ScMblViewDocBttn, dismissCompletion: viewHelpDocBlock)
                dialog.addSecondaryButton(text: BundleI18n.MessageAction.Lark_OpenPlatform_ScMblContactDevBttn, dismissCompletion: contactDeveloperBlock)
                dialog.addSecondaryButton(text: BundleI18n.MessageAction.Lark_OpenPlatform_ScIGotItBttn)
            }
            guard let mainWindow = Navigator.shared.mainSceneWindow else {
                assertionFailure()
                return
            }
            self.resolver.navigator.present(dialog, from: mainWindow, animated: true)
            return
        }
        GuideIndexPageVCLogger.info("open appstore profile with url: \(applinkUrl)")
        self.resolver.navigator.present(url, context: ["from": fromScene.rawValue], wrap: nil, from: self, prepare: nil, animated: true, completion: nil)
    }

    /// 跳转到会话
    func gotoChat(userID: String) {
        guard let op = try? resolver.resolve(assert: OpenPlatformService.self) else {
            GuideIndexPageVCLogger.error("no register OpenPlatformService")
            return
        }
        op.gotoChat(userID: userID, fromVC: self, completion: nil)
    }

    /// 打开帮助文档
    func openHelpDoc(helpDocURL: URL) {
        let docUrl = helpDocURL
        self.resolver.navigator.push(docUrl, from: self)
        GuideIndexPageVCLogger.info("help doc url(\(docUrl)) is opened success")
    }
}
