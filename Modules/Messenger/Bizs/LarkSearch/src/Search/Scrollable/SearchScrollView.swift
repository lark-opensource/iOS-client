//
//  SearchScrollView.swift
//  LarkSearch
//
//  Created by Patrick on 2022/2/27.
//

import Foundation
import UIKit

final class SearchScrollView: UIScrollView, UIGestureRecognizerDelegate {
    static let scrollGestureSimultaneousTag = 12_138
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let otherView = otherGestureRecognizer.view {
            if otherView.tag == Self.scrollGestureSimultaneousTag {
                return true
            }
        }
        return false
    }

}
