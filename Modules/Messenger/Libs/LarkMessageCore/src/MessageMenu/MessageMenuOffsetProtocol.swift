//
//  MessageMenuOffsetProtocol.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/6/20.
//

import UIKit
import LarkOpenChat

public protocol LongMessageMenuOffsetProtocol {
    func autoOffsetForLargeSizeView(_ view: UIView,
                                    fromVC: UIViewController?,
                                    tableView: UITableView,
                                    tableTopBlockHeight: CGFloat?)
}

public extension LongMessageMenuOffsetProtocol {
    func autoOffsetForLargeSizeView(_ view: UIView,
                                    fromVC: UIViewController?,
                                    tableView: UITableView,
                                    tableTopBlockHeight: CGFloat?) {
        guard let fromVC = fromVC else { return }
        if let superView = view.superview {
            let point = superView.convert(view.frame.origin, to: fromVC.view)
            let contentOffset = tableView.contentOffset
            let targetPoint = tableView.convert(CGPoint(x: contentOffset.x, y: (tableTopBlockHeight ?? 0) + contentOffset.y),
                                                to: fromVC.view)
            /// 顶部对齐距离20
            let offsetY = point.y - targetPoint.y - 20
            if offsetY > 0 {
                UIView.animate(withDuration: 0.25) {
                    tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                                       y: tableView.contentOffset.y + offsetY),
                                               animated: false)
                }
            }
        }
    }
}

public protocol MessageMenuHideProtocol: AnyObject {
    func hideSheetMenuIfNeedForMenuService(_ menuService: MessageMenuOpenService?) -> Bool
}

public extension MessageMenuHideProtocol {

    func hideSheetMenuIfNeedForMenuService(_ menuService: MessageMenuOpenService?) -> Bool {
        guard let menuOpenService = menuService else {
            return false
        }
        if menuOpenService.hasDisplayMenu,
           menuOpenService.isSheetMenu {
            menuOpenService.dissmissMenu(completion: nil)
            return true
        }
        return false
    }
}
