//
// Created by duanxiaochen.7 on 2021/5/26.
// Affiliated with SKBitable.
//
// Description:


import Foundation
import UIKit
import EENavigator
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

// MARK: - UICollectionViewDelegateFlowLayout
extension BTRecord: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 { return .zero }
        return CGSize(width: self.bounds.width, height: 40)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        delegate?.saveEditing(animated: true)
        guard indexPath.item < recordModel.wrappedFields.count else { return }
        let fieldModel = recordModel.wrappedFields[indexPath.item]
        if fieldModel.extendedType == .hiddenFieldsDisclosure {
            let futureValue = !fieldModel.isHiddenFieldsDisclosed
            delegate?.didClickHiddenFieldsDisclosureItem(toDisclosed: futureValue)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        guard let cell = cell as? BTFieldCellProtocol else {
            return
        }
        if delegate?.shouldHighlightField(recordId: recordID, fieldId: cell.fieldID) == true {
            cell.updateContainerHighlight(true)
        } else {
            cell.updateContainerHighlight(false)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        guard let cell = cell as? BTFieldCellProtocol else {
            return
        }
        cell.updateContainerHighlight(false)
    }

    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView).y > 0 {
            // down
            delegate?.didScrollDown()
        } else {
            // up
            delegate?.didScrollUp()
        }
        delegate?.didScroll(scrollView)
        UIMenuController.shared.docs.hideMenu()
        headerView.setHeaderAlpha(alpha: getHeaderViewAlpha())

        for cell in fieldsView.visibleCells {
            guard let realCell = cell as? BTAttachmentCoverCell else {
                continue
            }
            realCell.scrollViewDidScroll(offsetY: scrollView.contentOffset.y)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndScroll(scrollView)
        }
    }

    func scrollViewDidEndScroll(_ scrollView: UIScrollView) {
        notifyFirstVisibleFieldID()
    }
}
