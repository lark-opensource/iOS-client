//
//  TableView.swift
//  LarkSegmentController
//
//  Created by kongkaikai on 2018/12/7.
//  Copyright © 2018 kongkaikai. All rights reserved.
//

import Foundation
import UIKit

extension PageViewController {
    final class PageTableView: UITableView, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

            // 处理手势冲突
            if gestureRecognizer.view?.isKind(of: UITableView.self) == true,
                otherGestureRecognizer.view?.isKind(of: UITableView.self) == true,
                gestureRecognizer.isKind(of: UIPanGestureRecognizer.self),
                otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
                return true
            }
            return false
        }
    }

    final class PageEmptyView: UIView {
        override var isHidden: Bool {
            didSet {
                updateIsHidden?(isHidden)
            }
        }

        var updateIsHidden: ((_ isHidden: Bool) -> Void)?
    }
}
