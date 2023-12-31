//
//  DailyDetailViewController+DynamicModal.swift
//  ByteView
//
//  Created by huangshun on 2020/2/5.
//

import RichLabel
import SnapKit
import WebKit
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewUI

extension DailyDetailViewController {
    var fixedHeight: CGFloat {
        var height: CGFloat = 0
        height += topHeight
        height += topicLabelHeight * CGFloat(topicLabelLineNum)
        if viewModel.isMeetingShareViewVisible || viewModel.isEnterGroupButtonVisible {
            height += stackSpacing + buttonHeight
            if viewModel.isMeetingShareViewVisible && viewModel.isEnterGroupButtonVisible {
                height += buttonSpacing + buttonHeight
            }
        }
        height += bottomHeight
        return height
    }

    // 手动计算popover的高度，原理是先尽可能让subviews布局，然后统计实际高度总和，作为popover的高度
    var popoverHeight: CGFloat {
        var height: CGFloat = fixedHeight
        let views = contentStack.arrangedSubviews.filter { !$0.isHidden }
        if !views.isEmpty {
            height += stackSpacing + scrollView.contentInset.top + scrollView.contentInset.bottom
            let spacing = contentStack.spacing
            views.forEach { (view) in
                height += spacing + view.frame.height
            }
            height -= spacing
        }
        return min(maxHeight, height)
    }
}

extension DailyDetailViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isPopover = isRegular
    }
}

extension DailyDetailViewController: PanChildViewControllerProtocol {

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        return .contentHeight(popoverHeight + 15)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        guard Display.phone else { return .fullWidth }
        switch axis {
        case .landscape:
            // nolint-next-line: magic number
            return .maxWidth(width: 420)
        default: return .fullWidth
        }
    }

    var defaultLayout: RoadLayout {
        return .shrink
    }

    var panScrollable: UIScrollView? {
        return scrollView
    }

    var backgroudColor: UIColor {
        return self.view.backgroundColor ?? UIColor.ud.bgBody
    }
}
