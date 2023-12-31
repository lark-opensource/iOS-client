//
//  NaviBarAnimator.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 03/04/2018.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

open class NaviBarAnimator {
    /// 在vc上添加navibar, largeNavibar，scrollView,以及让naviBar监听scrollView的滚动事件
    ///
    /// - Parameters:
    ///   - bottomView: 在naviBar下方的view，如果是nil，则把scrollview放在naviBar下方
    ///   - bottomOffset: bottomView距离vc底部距离， 如果没指定，则到vc的safeArea.bottom
    ///   - scrollView: naviBar和largeNaviBar监听此scroll做动画
    ///   - normalNaviBar: 小的naviBar
    ///   - largeNaviBar: 大的naviBar
    ///   - vc: 需要被添加naviBar和bottomView的VC
    public static func setUpAnimatorWith(bottomView: UIView? = nil,
                                         bottomOffset: CGFloat? = 0,
                                         scrollView: UIScrollView,
                                         normalNaviBar: TitleNaviBar,
                                         largeNaviBar: LargeTitleNaviBar,
                                         toVC vc: UIViewController) {
        let animator = NaviBarAnimator(normalNaviBar: normalNaviBar, largeNaviBar: largeNaviBar)
        animator.addNaviBarToVC(vc: vc)
        animator.addBottomView(bottomView ?? scrollView, bottomOffset: bottomOffset, toVC: vc)
        animator.observeScrollView(scrollView)
    }

    private let disposeBag = DisposeBag()

    private let normalNaviBar: TitleNaviBar
    private let largeNaviBar: LargeTitleNaviBar

    public init(normalNaviBar: TitleNaviBar, largeNaviBar: LargeTitleNaviBar) {
        self.normalNaviBar = normalNaviBar
        self.largeNaviBar = largeNaviBar
    }

    public func addNaviBarToVC(vc: UIViewController) {
        vc.view.addSubview(normalNaviBar)
        normalNaviBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        vc.view.insertSubview(largeNaviBar, aboveSubview: normalNaviBar)
        largeNaviBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
    }

    public func addBottomView(_ bottomView: UIView, bottomOffset: CGFloat? = nil, toVC vc: UIViewController) {
        if !isView(vc.view, superviewOfViewB: bottomView) {
            vc.view.addSubview(bottomView)
        }
        vc.view.sendSubviewToBack(bottomView)
        bottomView.snp.makeConstraints({ make in
            make.top.equalTo(largeNaviBar.contentTop)
            make.left.right.equalToSuperview()
            if let bottomOffset = bottomOffset {
                make.bottom.equalTo(-bottomOffset)
            } else {
                make.bottom.equalTo(vc.view.safeAreaLayoutGuide.snp.bottom)
            }
        })
    }

    public func observeScrollView(_ scrollView: UIScrollView) {
        let naviBarHeight = largeNaviBar.naviBarHeight
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: naviBarHeight, left: 0, bottom: 0, right: 0)
        scrollView.contentInset = UIEdgeInsets(top: naviBarHeight, left: 0, bottom: 0, right: 0)
        scrollView.contentOffset = CGPoint(x: 0, y: -naviBarHeight)
        scrollView.rx.observe(CGPoint.self, "contentOffset")
            .map({ (point) -> CGPoint in
                return point ?? CGPoint.zero
            })
            .map { return $0.y }
            .subscribe(onNext: { (contentOffsetY) in
                var alphaOfLargeNaviBar: CGFloat = 1 - (naviBarHeight + contentOffsetY) / (naviBarHeight / 2)
                alphaOfLargeNaviBar = NaviBarAnimator.normolizedAlpha(alphaOfLargeNaviBar)
                self.largeNaviBar.alpha = alphaOfLargeNaviBar

                var alphaOfNormalNaviBar = 1 + contentOffsetY / (naviBarHeight / 2)
                alphaOfNormalNaviBar = NaviBarAnimator.normolizedAlpha(alphaOfNormalNaviBar)
                self.normalNaviBar.alpha = alphaOfNormalNaviBar
            })
            .disposed(by: disposeBag)
    }

    private func isView(_ viewA: UIView, superviewOfViewB viewB: UIView) -> Bool {
        var tempView = viewB.superview
        while tempView != nil {
            if tempView == viewA {
                return true
            }
            tempView = tempView?.superview
        }
        return false
    }

    public static func normolizedAlpha(_ alpha: CGFloat) -> CGFloat {
        if alpha > 1 { return 1 }
        if alpha < 0 { return 0 }
        return alpha
    }
}
