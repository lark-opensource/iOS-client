//
//  DocsHomeAnimator.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/1/6.
//

import UIKit
import SKCommon
import SKUIKit

public protocol DocsHomeAnimatorDelegate: AnyObject {
    func canHiddenNavBar(_ animator: DocsHomeAnimator) -> Bool
    func canPinSwitchTab(_ animator: DocsHomeAnimator) -> Bool
    func switchBarMinY(_ animator: DocsHomeAnimator) -> CGFloat

    @discardableResult
    func floatSwitchTab(_ animator: DocsHomeAnimator) -> Bool

    @discardableResult
    func pinSwitchTab(_ animator: DocsHomeAnimator) -> Bool
}

public protocol DocsHomeAnimatorNavBarDelegate: AnyObject {
    func docsAnimatorShouldChangeVisibility(_ animator: DocsHomeAnimator, toHidden isHidden: Bool)
}

public final class DocsHomeAnimator {
    weak var delegate: DocsHomeAnimatorDelegate?
    weak var navBarDelegate: DocsHomeAnimatorNavBarDelegate?
    weak var larkNavBarDelegate: DocsHomeNavBarDelegate?

    weak var navBar: SKNavigationBar?
    weak var searchBar: DocsSearchBar?
    weak var switchBar: UIView?

    private(set) var isNavigationBarHide: Bool = false {
        didSet {
            if oldValue != isNavigationBarHide {
                navigationBarChanged?(isNavigationBarHide)
            }
        }
    }
    var navigationBarChanged: ((_ isHidden: Bool) -> Void)?

    // MARK: Helper Calculation Properties
    private var searchBarInherentHeight: CGFloat {
        return searchBar?.inherentHeight ?? 0
    }
    private var navBarInherentHeight: CGFloat {
        return navBar?.intrinsicHeight ?? 0
    }
    private var searchBarHeight: CGFloat {
        return searchBar?.frame.height ?? 0
    }
    private var docsNavShowAlpha: CGFloat {
        1
    }
    private var isNavBarHidden: Bool {
        return navBar?.alpha == 0
    }
    private var isSearchBarHidden: Bool {
        return searchBarHeight == 0
    }

    // MARK: State Properties
    private var isAnimating: Bool = false

    public init(navBar: SKNavigationBar? = nil, searchBar: DocsSearchBar? = nil, switchBar: UIView? = nil) {
        self.navBar = navBar
        self.searchBar = searchBar
        self.switchBar = switchBar
    }

    // MARK: External Interface
    /// 立即显示导航栏和搜索栏
    func forceShow(animated: Bool, completion: (() -> Void)? = nil) {
        isAnimating = true
        larkNavBarDelegate?.changeLarkNaviBarPresentation(show: true, animated: animated)
        isNavigationBarHide = false
        UIView.animate(withDuration: animated ? 0.15 : 0, animations: {
            self.navBar?.alpha = self.docsNavShowAlpha
            self.navBarDelegate?.docsAnimatorShouldChangeVisibility(self, toHidden: false)
        }, completion: { ( _ ) in
            UIView.animate(withDuration: animated ? 0.15 : 0, animations: {
                self.searchBar?.setHeight(to: self.searchBarInherentHeight, animated: true)
            }, completion: { _ in
                self.isAnimating = false
            })
            completion?()
        })
    }

    /// 刷新SwitchBar位置
    func refreshSwitchBarTop(animated: Bool) {
        if let switchBar = switchBar {
            doChangeSwitchBarTop(by: switchBar.frame.minY, animated: animated)
        }
    }

    /// 拖动时根据手指位置移动决定如何显示
    /// 下拉时 transY > 0 , 上拉时 transY < 0
    func update(by transY: CGFloat, animated: Bool, statusBarInherentHeight: CGFloat) {
        let topInherentHeight = navBarInherentHeight + statusBarInherentHeight
        if transY > 0 {
            if isNavBarHidden {
                isAnimating = true
                larkNavBarDelegate?.changeLarkNaviBarPresentation(show: true, animated: true)
                isNavigationBarHide = false
                UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
                    self.navBar?.alpha = self.docsNavShowAlpha
                    self.navBarDelegate?.docsAnimatorShouldChangeVisibility(self, toHidden: false)
                    self.doChangeSwitchBarTop(by: topInherentHeight, animated: true)
                }, completion: { _ in
                    self.isAnimating = false
                })
            } else {
                if !isAnimating {
                    let newHeight = searchBar?.setHeight(to: searchBarHeight + transY, animated: false) ?? 0
                    self.doChangeSwitchBarTop(by: topInherentHeight + newHeight, animated: false)
                } else {
                    self.refreshSwitchBarTop(animated: false)
                }
            }
        } else if transY < 0 {
            if isSearchBarHidden {
                isAnimating = true
                if self.delegate?.canHiddenNavBar(self) == true {
                    larkNavBarDelegate?.changeLarkNaviBarPresentation(show: false, animated: true)
                    isNavigationBarHide = true
                }
                UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
                    if self.delegate?.canHiddenNavBar(self) == true {
                        self.navBar?.alpha = 0
                        self.navBarDelegate?.docsAnimatorShouldChangeVisibility(self, toHidden: true)
                        self.isNavigationBarHide = true
                    }
                    self.doChangeSwitchBarTop(by: statusBarInherentHeight, animated: true)
                }, completion: { _ in
                    self.isAnimating = false
                })
            } else {
                if !isAnimating {
                    let newHeight = searchBar?.setHeight(to: searchBarHeight + transY, animated: false) ?? 0
                    self.doChangeSwitchBarTop(by: topInherentHeight + newHeight, animated: false)
                } else {
                    self.refreshSwitchBarTop(animated: false)
                }
            }
        }
    }

    /// 搜索栏高度自适应，决定显示或隐藏
    func autoAdjust(with scrollView: UIScrollView? = nil, animated: Bool, statusBarInherentHeight: CGFloat) {
        let topInherentHeight = navBarInherentHeight + statusBarInherentHeight
        isAnimating = true
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            if self.searchBarHeight > self.searchBarInherentHeight / 2 {
                self.changeContentOffset(by: self.searchBarInherentHeight - self.searchBarHeight, withScrollView: scrollView)
                let newHeight = self.searchBar?.setHeight(to: self.searchBarInherentHeight, animated: true) ?? 0
                self.doChangeSwitchBarTop(by: topInherentHeight + newHeight, animated: true)
            } else {
                self.changeContentOffset(by: -self.searchBarHeight, withScrollView: scrollView)
                let newHeight = self.searchBar?.setHeight(to: 0, animated: true) ?? 0
                let switchBarTop = statusBarInherentHeight + (self.isNavBarHidden ? 0 : self.navBarInherentHeight) + newHeight
                self.doChangeSwitchBarTop(by: switchBarTop, animated: true)
            }
        }, completion: { _ in
            self.isAnimating = false
        })
    }

    // MARK: Internal Helper Method
    /// 调整标签的顶端，同时将其移出/放回Cell内
    private func doChangeSwitchBarTop(by floatTop: CGFloat, animated: Bool) {
        let cellTop = delegate?.switchBarMinY(self) ?? 0
        if cellTop < floatTop {
            delegate?.floatSwitchTab(self)
            floatSwitchBar(to: floatTop, animated: animated)
        } else {
            if delegate?.canPinSwitchTab(self) ?? false {
                floatSwitchBar(to: floatTop, animated: animated) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.pinSwitchTab(strongSelf)
                }
            }
        }
    }

    /// 单纯改变Switch Bar的位置
    private func floatSwitchBar(to top: CGFloat, animated: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            // 此处在某种情况下，self.switchBar的superView会为nil导致crash，多加一些判空保护
            guard
                let switchBarLocal = self.switchBar,
                let superViewLocal = switchBarLocal.superview else {
                    return
            }
            switchBarLocal.snp.updateConstraints({ (make) in
                make.top.equalTo(top)
            })
            superViewLocal.dongOut()
        }, completion: { _ in
            completion?()
        })
    }

    /// 调整对应scrollView ContentOffset
    private func changeContentOffset(by distance: CGFloat, withScrollView scrollView: UIScrollView?) {
        guard let scrollView = scrollView else { return }
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y - distance)
    }
}
