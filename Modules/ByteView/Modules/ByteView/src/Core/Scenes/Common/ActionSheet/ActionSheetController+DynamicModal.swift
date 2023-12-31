//
//  ActionSheetViewController+DynamicModal.swift
//  ByteView
//
//  Created by huangshun on 2020/2/5.
//

import Foundation
import UIKit
import ByteViewUI

extension ActionSheetController: PanChildViewControllerProtocol {

    var containerHeight: CGFloat {
        let bottomMargin: CGFloat = VCScene.safeAreaInsets.bottom
        let minHeight: CGFloat = appearance.textHeight + bottomMargin + 10
        let indicatorHeight: CGFloat = currentLayoutContext.layoutType.isPhoneLandscape ? 0 : 12
        let titleHeight: CGFloat = self.headerHeight
        let actionHeight: CGFloat = self.intrinsicHeight
        let cancelTopOffset = isIPadLayout.value ? 0 : Layout.cancelTopOffset
        let cancelHeight: CGFloat = self.cancelAction == nil ? 0 : (Layout.cancelHeight + cancelTopOffset)
        let bottomOffset = appearance.bottomOffset(isPhoneLandscape: currentLayoutContext.layoutType.isPhoneLandscape)
        let actualHeight: CGFloat = indicatorHeight + titleHeight + actionHeight + cancelHeight + bottomOffset
        let height = max(minHeight, actualHeight)
        return height
    }

    func height(
        _ axis: RoadAxis,
        layout: RoadLayout
    ) -> PanHeight {
        return .contentHeight(containerHeight)
    }

    public func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: Layout.landscapeMaxWidth)
        }
        return .fullWidth
    }

    var showDragIndicator: Bool {
        return appearance.showDragIndicator
    }

    var indicatorColor: UIColor {
        return appearance.indicatorColor
    }

    var backgroudColor: UIColor {
        return appearance.viewControllerBackgroundColor
    }

    var panScrollable: UIScrollView? {
        return tableView
    }

    var showBarView: Bool {
        return appearance.showBarView
    }

    func configurePanWareContentView(_ contentView: UIView) {
        contentView.backgroundColor = appearance.contentViewColor
    }
}

extension ActionSheetController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isIPadLayout.accept(isRegular)
    }
}
