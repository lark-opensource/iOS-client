//
//  NewEventPushable.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/28.
//  Copyright © 2017年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import LarkUIKit

protocol NewEventPushable: AnyObject {
    var displayedView: UIView { get }
    var birthView: UIView? { get set }
    var navLeftItem: UIButton? { get set }
    var navRightItem: UIButton? { get set }
    var navigator: NewEventNavigatable? { get set }
    /// push新的页面(覆盖在当前页面上面)进来时当前页面上移的距离
    var pushedToTy: CGFloat { get set }
    // 被push进来时往下移动的距离
    var pushFromTy: CGFloat { get set }
}

extension NewEventPushable {
    func leftNavItem(image: UIImage?, title: String?) -> UIButton {
        let btn = UIButton.cd.button(type: .system)
        btn.titleLabel?.font = NewEventViewUIStyle.Font.save
        btn.setTitleColor(NewEventViewUIStyle.Color.normalText, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        btn.setTitle(title, for: .normal)
        btn.setImage(image, for: .normal)
        btn.contentHorizontalAlignment = .left
        btn.backgroundColor = UIColor.ud.bgBody
        return btn
    }

    // 回退箭头的item
    func backNavItem() -> UIButton {
        return self.leftNavItem(image: NewEventViewUIStyle.Image.close, title: nil)
    }

}

protocol NewEventNavigatable: AnyObject {

    var view: UIView { get set }

    var pushedViews: [NewEventPushable] { get set }

    var titleView: NewEventTitleView { get set }

    func push(_ pushObj: NewEventPushable, from birthView: UIView?, animated: Bool)
}

extension NewEventNavigatable {
    func push(_ pushObj: NewEventPushable, from birthView: UIView? = nil, animated: Bool = true) {
        assertLog(self.titleView.bounds.height > 0)
        self.transform(leftTitleItem: pushObj.navLeftItem,
                       oldLeftTitleItem: self.pushedViews.last?.navLeftItem,
                       rightTitleItem: pushObj.navRightItem,
                       oldRightTitleItem: self.pushedViews.last?.navRightItem,
                       animated: animated)

        var viewFrame = self.view.bounds
        viewFrame.origin.y = self.titleView.frame.height
        if viewFrame.size.height - self.titleView.frame.height > 0 {
            viewFrame.size.height -= self.titleView.frame.height
        }
        pushObj.displayedView.frame = viewFrame
        self.view.insertSubview(pushObj.displayedView, at: 0)
        pushObj.navigator = self

        pushObj.displayedView.alpha = 0.0
        var distance = pushObj.displayedView.frame.size.height / 2.0
        if let birthView = birthView {
            let baseView = self.pushedViews.last?.displayedView ?? self.view
            distance = birthView.convert(birthView.bounds, to: baseView).origin.y
            pushObj.birthView = birthView
        }
        pushObj.displayedView.transform = CGAffineTransform(translationX: 0, y: distance)
        pushObj.pushFromTy = distance
        self.pushedViews.last?.displayedView.endEditing(true)
        let animationAction = { [weak self] in
            self?.pushedViews.last?.displayedView.alpha = 0.0
            self?.pushedViews.last?.displayedView.transform = CGAffineTransform(translationX: 0, y: -distance)
            self?.pushedViews.last?.pushedToTy = -distance
            pushObj.displayedView.transform = CGAffineTransform.identity
            pushObj.displayedView.alpha = 1.0
        }
        if animated {
            UIView.animate(withDuration: NewEventViewUIStyle.animationDuration, animations: animationAction)
        } else {
            animationAction()
        }
        self.pushedViews.append(pushObj)
    }

    private func transform(leftTitleItem: UIButton?,
                           oldLeftTitleItem: UIButton?,
                           rightTitleItem: UIButton?,
                           oldRightTitleItem: UIButton?,
                           animated: Bool) {
        self.titleView.transformLeftItem(item: leftTitleItem, oldItem: oldLeftTitleItem, animated: animated)
        self.titleView.transformRightItem(item: rightTitleItem, oldItem: oldRightTitleItem, animated: animated)
    }

    private func transform(leftTitleItem: UIButton?,
                           oldLeftTitleItem: UIButton?,
                           rightTitleItem: UIButton?,
                           oldRightTitleItem: UIButton?,
                           progress: Float) -> () -> Void {
        let removeLeftItem = self.titleView.transformLeftItem(item: leftTitleItem,
                                                              oldItem: oldLeftTitleItem,
                                                              progress: progress)
        let removeRightItem = self.titleView.transformRightItem(item: rightTitleItem,
                                                                oldItem: oldRightTitleItem,
                                                                progress: progress)
        return {
            removeLeftItem()
            removeRightItem()
        }
    }

    func pop(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.pop(to: self.pushedViews.suffix(2).first, animated: animated, completion: completion)
    }

    func pop(progress: Float) -> () -> Void {
        return self.pop(to: self.pushedViews.suffix(2).first, progress: progress)
    }

    private func pop(to page: NewEventPushable?, animated: Bool, completion: (() -> Void)? = nil) {
        var clearNavItem: (() -> Void)?
        let animationAction = {
           clearNavItem = self.pop(to: page, progress: 1.0)
        }
        let clear = {
            guard let lastPage = self.pushedViews.last, let destinationPage = page, destinationPage !== lastPage, self.pushedViews.contains(where: { destinationPage === $0 }) else {
                assertionFailureLog()
                return
            }
            while self.pushedViews.last !== destinationPage {
                self.pushedViews.popLast()?.displayedView.removeFromSuperview()
            }
            clearNavItem?()
        }
        if animated {
            UIView.animate(withDuration: NewEventViewUIStyle.animationDuration, animations: animationAction, completion: { (_) in
                clear()
                completion?()
            })
        } else {
            animationAction()
            clear()
            completion?()
        }
    }

    private func pop(to page: NewEventPushable?, progress: Float) -> () -> Void {
        guard let lastPage = self.pushedViews.last else {
            assertionFailureLog()
            return {}
        }
        guard let destinationPage = page, destinationPage !== lastPage, self.pushedViews.contains(where: { destinationPage === $0 }) else {
            assertionFailureLog()
            return {}
        }
        lastPage.displayedView.endEditing(true)

        destinationPage.displayedView.alpha = CGFloat(1.0 * progress)
        lastPage.displayedView.alpha = CGFloat(1.0 - progress)

        destinationPage.displayedView.transform = CGAffineTransform(translationX: 0, y: destinationPage.pushedToTy * CGFloat(1.0 - progress))
        lastPage.displayedView.transform = CGAffineTransform(translationX: 0, y: lastPage.pushFromTy * CGFloat(progress))
        return self.transform(leftTitleItem: destinationPage.navLeftItem,
                              oldLeftTitleItem: lastPage.navLeftItem,
                              rightTitleItem: destinationPage.navRightItem,
                              oldRightTitleItem: lastPage.navRightItem,
                              progress: progress)
    }

    // only for pad mode
    func resize(to size: CGSize) {
        var size = size
        if size.height == Display.height {
            size.height -= 40 // ipad 特殊walk around：fromSheet 没办法全屏幕
        }
        size.height -= UIApplication.shared.statusBarFrame.height // 为了美观， pad模式下仍保留这个view跟 parent top的边距
        if size.height - self.titleView.frame.height > 0 {
            size.height -= self.titleView.frame.height
        }
        pushedViews.forEach {
            $0.displayedView.frame.size = self.view.frame.size
        }
    }
}
