//
//  FeedMainViewController+Vibration
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation

extension FeedMainViewController {
    func triggerVibration(_ scrollView: UIScrollView) {
        // 仅在shortcut存在时才执行判断
        guard headerView.preAllowVibrate else { return }

        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        // 判断是否在下拉吸顶中
        guard offset < 0 else { return }

        // 若是在吸顶中上推，则允许再次触发震动
        if scrollDirection == .up && !isAllowVibrate {
            isAllowVibrate = true
        // 若是在吸顶中下拉、尚未震动、置顶未展开，则执行条件判断决定是否触发震动
        } else if scrollDirection == .down && isAllowVibrate {
            let velocityY = scrollView.panGestureRecognizer.velocity(in: scrollView).y
            let percent = -offset / ShortcutLayout.shortcutsLoadingExpansionTrigger

            if (percent >= FeedVibrationCons.minPercent && percent <= FeedVibrationCons.maxPercent) || (velocityY > FeedVibrationCons.velocityY) {
                feedbackGenerator.impactOccurred()
                isAllowVibrate = false
            }
        }
    }

    enum FeedVibrationCons {
        static let minPercent: CGFloat = 1.0
        static let maxPercent: CGFloat = 1.25
        static let velocityY: CGFloat = 1500
    }
}
