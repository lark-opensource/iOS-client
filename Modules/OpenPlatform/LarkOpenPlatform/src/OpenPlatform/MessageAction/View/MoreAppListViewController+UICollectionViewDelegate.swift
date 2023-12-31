//
//  MoreAppListViewController+UICollectionViewDelegate.swift
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
import LarkBoxSetting

// MARK: - UICollectionViewDelegate
extension MoreAppListViewController {
    /// cell点击事件
    func _collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView.cellForItem(at: indexPath) != nil else {
            GuideIndexPageVCLogger.error("collectionView.cellForItem:\(indexPath) is nil")
            return
        }
        /// 获取数据
        guard let itemList = viewModel?.getSectionDataList(in: indexPath.section), indexPath.row < itemList.count else {
            GuideIndexPageVCLogger.error("get item info failed with indexPath:\(indexPath)")
            return
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        let cellModel = itemList[indexPath.row]
        openAppMessageAction(viewModel: cellModel)
    }

    /// headerView
    func _collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is empty, show page failed")
            return UICollectionReusableView()
        }
        var headerView = UICollectionReusableView()
        let section = indexPath.section
        if section == MoreAppListSectionMode.externalList.rawValue {
            let identifier = MoreAppExternalItemListHeaderView.identifier
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as? MoreAppExternalItemListHeaderView ??
                MoreAppExternalItemListHeaderView()
            // 1、当只添加了 1 张卡片时，仅展示“我的常用”标题，卡片此时不支持拖拽
            // 2、当添加 2-3 张卡片时，新增支持拖拽的副标题文案
            let availableItemCountGreaterThan1 = model.externalItemListCountGreaterThan1
            view.updateViews(
                bizScene: self.bizScene,
                hasAvailableItem: model.hasExternalItemList,
                availableItemCountGreaterThan1: availableItemCountGreaterThan1,
                containerView: collectionView
            )
            headerView = view
        } else if section == MoreAppListSectionMode.availabelList.rawValue {
            let identifier = MoreAppAvailableItemListHeaderView.identifier
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as? MoreAppAvailableItemListHeaderView ??
                MoreAppAvailableItemListHeaderView()
            let linkTipsHidden = BoxSetting.isBoxOff() ? true : !jumpUrlValid()
            view.updateViews(
                textViewDelegate: self,
                linkTipsHidden: linkTipsHidden,
                hasAvailableItem: model.hasAvailabeItemList
            )
            headerView = view
        }
        return headerView
    }
}
