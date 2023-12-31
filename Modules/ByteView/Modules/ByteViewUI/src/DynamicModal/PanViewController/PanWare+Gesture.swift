//
//  PanWare+Gesture.swift
//  ByteView
//
//  Created by huangshun on 2020/2/10.
//

import Foundation
import UIKit

//extension PanWare {
//
//    func shouldRespond(to panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
//        return !shouldFail(panGestureRecognizer: panGestureRecognizer)
//    }
//
//    func shouldFail(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
//
//        guard
//            let scrollView = panProxy.panScrollable,
//            scrollView.contentOffset.y > 0
//            else {
//                return false
//        }
//
//        let loc = panGestureRecognizer.location(in: wrapper)
//        return (scrollView.frame.contains(loc) || scrollView.isScrolling)
//    }
//
//}

extension PanWare: UIGestureRecognizerDelegate {

    /** 临时去掉新滑动交互, 滚动时pan手势state 终止于 change 导致未能还原真实高度 **/

//    public func gestureRecognizer(
//        _ gestureRecognizer: UIGestureRecognizer,
//        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
//    ) -> Bool {
//        return false
//    }
//
//    public func gestureRecognizer(
//        _ gestureRecognizer: UIGestureRecognizer,
//        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//    ) -> Bool {
//        return otherGestureRecognizer.view == panProxy.panScrollable
//    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return otherGestureRecognizer.view == panProxy.panScrollable
    }

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {

        guard let scrollable = panProxy.panScrollable
            else { return true }

        guard scrollable.bounds.contains(gestureRecognizer.location(in: scrollable))
            else { return true }
        return scrollable.contentOffset.y + scrollable.contentInset.top <= 1.0
    }

}
