//
//  Helpers.swift
//  SegmentedTableView
//
//  Created by Hayden on 2021/6/24.
//

import Foundation
import UIKit

extension UIView {

    var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
}

final class NestedTableView: UITableView, UIGestureRecognizerDelegate {

    // swiftlint:disable all
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) && otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)
    }
    // swiftlint:enable all
}
