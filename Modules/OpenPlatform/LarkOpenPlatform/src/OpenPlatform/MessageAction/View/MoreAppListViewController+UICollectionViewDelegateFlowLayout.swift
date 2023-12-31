//
//  MoreAppListViewController+UICollectionViewDelegateFlowLayout.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/26.
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

// MARK: collectionView - UICollectionViewDelegateFlowLayout
extension MoreAppListViewController {
    /// 设置每个item大小
    func _collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.op_width - 2 * MoreAppCollectionViewCell.contentViewInsetHorizontal
        /// 获取数据
        guard let _ = viewModel, let itemList = viewModel?.getSectionDataList(in: indexPath.section), indexPath.row < itemList.count else {
            GuideIndexPageVCLogger.warn("get item info failed with indexPath:\(indexPath)")
            return .zero
        }
        /// 刷新cell
        let cellViewModel = itemList[indexPath.row]
        let text = cellViewModel.getDescText()
        return CGSize(width: width, height: MoreAppCollectionViewCell.cellHeight(containerViewWidth: width, text: text))
    }

    /// 设置section的header高度
    func _collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = collectionView.op_width
        let defaultSize: CGSize = .zero
        guard let model = viewModel else {
            GuideIndexPageVCLogger.warn("GuideIndexPageView viewModel is empty, show page failed")
            return defaultSize
        }
        var height: CGFloat = 0.0
        if section == MoreAppListSectionMode.externalList.rawValue {
            if model.hasExternalItemList {
                height = MoreAppExternalItemListHeaderView.viewHeightWithExternalItems
            } else {
                height = MoreAppExternalItemListHeaderView.viewHeightWithNoExternalItems(containerViewWidth: width)
            }
        } else if section == MoreAppListSectionMode.availabelList.rawValue {
            let linkTipsHidden = !jumpUrlValid()
            if linkTipsHidden {
                height = MoreAppAvailableItemListHeaderView.viewHeightWithLinkTipsHidden
            } else {
                height = MoreAppAvailableItemListHeaderView.viewHeightWithLinkTipsShowing(containerViewWidth: width, hasAvailableItem: model.hasAvailabeItemList)
            }
        }
        return CGSize(width: width, height: height)
    }

    /// 配置section的间距
    func _collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    /// item之间的水平距离
    func _collectionView(_ collectionView: UICollectionView,

                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2 * MoreAppCollectionViewCell.contentViewInsetHorizontal
    }

    /// item之间的垂直距离
    func _collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2 * MoreAppCollectionViewCell.contentViewInsetVertical
    }
}
