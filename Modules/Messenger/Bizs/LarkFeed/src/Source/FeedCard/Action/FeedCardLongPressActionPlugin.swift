//
//  FeedCardLongPressActionPlugin.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/6/8.
//

import Foundation
import LarkSwipeCellKit
import RustPB
import RxSwift
import RxCocoa
import LarkZoomable
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignToast
import UIKit
import LarkModel
import LarkFeatureGating
import UniverseDesignIcon
import LarkOpenFeed
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignDialog
import LKCommonsLogging
import LarkPerf
import AppReciableSDK
import LKCommonsTracker
import Homeric
import EENavigator
import LarkUIKit

// MARK: 长按菜单
final class FeedCardLongPressActionPlugin {
    let isSupportLongPress: Bool
    init() {
        if #available(iOS 14.0, *) {
            /// 由于 iOS 13 没有 willDisplayContextMenu 和 willEndContextMenuInteraction 的回调函数。将里边逻辑进行移动。
            /// 移动这两个函数里边的逻辑会导致会话卡死。https://meego.feishu.cn/larksuite/issue/detail/4883932
            /// 最后结论，逻辑迁移回原来位置，初始化只支持 iOS 14 以上的设备。
            /// case study : https://bytedance.feishu.cn/docx/doxcn6UGgTRR7HahbOHH9xwJxzh
            isSupportLongPress = true
        } else {
            isSupportLongPress = false
        }
    }

    // 定制 ContextMenu Preview，不定制会有操作白屏的现象
    @available(iOS 13.0, *)
    func highlightingMenu(tableView: UITableView, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 14.0, *)
    func willDisplayMenu(tableView: UITableView, configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        FeedTracker.Press.View()
    }

    /// menu 消失
    @available(iOS 14.0, *)
    func willEndMenu(tableView: UITableView, configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {}

    @available(iOS 13.0, *)
    func dismissMenu(tableView: UITableView, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return targetPreview(for: tableView, with: configuration)
    }

    @available(iOS 13.0, *)
    private func targetPreview(for tableView: UITableView, with configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath),
              tableView.window != nil else { return nil }
        cell.setHighlighted(false, animated: true)
        guard let copy = cell.snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        return UITargetedPreview(view: copy, parameters: UIPreviewParameters(),
                                 target: UIPreviewTarget(container: tableView, center: cell.center))
    }
}
