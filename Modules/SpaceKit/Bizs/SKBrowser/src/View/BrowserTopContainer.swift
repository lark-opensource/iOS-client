// 
// Created by duanxiaochen.7 on 2020/4/14.
// Affiliated with SpaceKit.
// 
// Description: Top container determines its height by its subviews' hidden states.
// Be aware to properly update its subviews' `isHidden` property.


import UIKit
import SnapKit
import SKFoundation
import SKUIKit

public protocol BrowserTopContainerDelegate: AnyObject {
    func topContainerDidUpdateSubviews()
}

open class BrowserTopContainer: UIView {

    enum Const {
        static let animationDuration = TimeInterval(UINavigationController.hideShowBarDuration)
        static let animationDurationInMilliseconds = Int(UINavigationController.hideShowBarDuration * 1000.0)
    }

    public weak var delegate: BrowserTopContainerDelegate?

    public var navBar: SKNavigationBar

    public lazy var banners = SKBannerContainer().construct { it in
        it.delegate = self
        it.isHidden = true
    }
    
    public lazy var catalogueContainer = SKCatalogueBannerContainer().construct { it in
        it.isHidden = true
        it.delegate = self
    }

    open var preferredHeight: CGFloat {
        var height: CGFloat = 0
        height += navBar.intrinsicHeight
        height += banners.isHidden ? 0.0 : banners.preferedHeight
        height += catalogueContainer.isHidden ? 0.0 : catalogueContainer.preferedHeight
        return height
    }

    required public init(navBar: SKNavigationBar) {
        self.navBar = navBar
        super.init(frame: .zero)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setup() {
        setupSubviews()
        //delegate?.topContainerDidUpdateSubviews()
    }

    open func setupSubviews() {
        if navBar.superview != nil && navBar.superview != self {
            navBar.removeFromSuperview()
            navBar.snp.removeConstraints()
        }
        addSubview(navBar)
        navBar.snp.makeConstraints { it in
            it.top.leading.trailing.equalToSuperview()
        }
        addSubview(banners)
        banners.isHidden = true
        addSubview(catalogueContainer)
        catalogueContainer.isHidden = true
        updateLayout()
    }

    open func updateSubviewsContraints() {
        delegate?.topContainerDidUpdateSubviews()
    }

    // 沉浸式浏览时用到
    public func setAlpha(to newAlpha: CGFloat) {
        navBar.alpha = newAlpha
        banners.alpha = newAlpha
        catalogueContainer.alpha = newAlpha
    }

    // 单独隐藏导航栏时用到
    public func setNavBarAlpha(to newAlpha: CGFloat) {
        navBar.alpha = newAlpha
    }
    
    // 单独隐藏Banners时用到
    public func setBannersAlpha(to newAlpha: CGFloat) {
        banners.alpha = newAlpha
    }

    public func animateIfNeeded(_ shouldAnimate: Bool, animation: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if shouldAnimate {
            UIView.animate(withDuration: Const.animationDuration, animations: animation, completion: completion)
        } else {
            animation()
            completion?(false)
        }
    }

    open override func point(inside p: CGPoint, with event: UIEvent?) -> Bool {
        guard subviews.count != 0 else {
            return super.point(inside: p, with: event)
        }
        var allSubviewsAreTransparent: Bool = true
        for subview in subviews where subview.alpha != 0 {
            allSubviewsAreTransparent = false
            break
        }
        if allSubviewsAreTransparent {
            return false
        } else {
            return super.point(inside: p, with: event)
        }
    }
    
    open func updateLayout() {
        guard banners.superview != nil, catalogueContainer.superview != nil else {
            return
        }
        banners.snp.remakeConstraints { it in
            it.top.equalTo(navBar.snp.bottom)
            it.leading.trailing.equalToSuperview()
            it.height.equalTo(banners.isHidden ? 0 : banners.preferedHeight)
            if catalogueContainer.isHidden {
                it.bottom.equalToSuperview()
            }
        }
        catalogueContainer.snp.remakeConstraints { it in
            if banners.isHidden {
                it.top.equalTo(navBar.snp.bottom)
            } else {
                it.top.equalTo(banners.snp.bottom)
            }
            it.left.right.equalToSuperview()
            it.height.equalTo(catalogueContainer.isHidden ? 0 : catalogueContainer.preferedHeight)
            if !catalogueContainer.isHidden {
                it.bottom.equalToSuperview()
            }
        }
    }
}


extension BrowserTopContainer: BannerContainerDelegate {
    public func preferedWidth(_ banner: SKBannerContainer) -> CGFloat { bounds.width }

    public func shouldUpdateHeight(_ banner: SKBannerContainer, newHeight: CGFloat) {
        guard banners.superview != nil else {
            DocsLogger.info("banner设置时机过早！！！")
            return
        }
        banners.isHidden = newHeight == 0
        updateLayout()
        delegate?.topContainerDidUpdateSubviews()
        setAlpha(to: 1.0)
    }
}

extension BrowserTopContainer: SKCatalogueBannerContainerDelegate {
    public func preferedWidth(_ banner: SKCatalogueBannerContainer) -> CGFloat { bounds.width }

    public func shouldUpdateHeight(_ banner: SKCatalogueBannerContainer, newHeight: CGFloat) {
        guard catalogueContainer.superview != nil else {
            DocsLogger.info("catalogueContainer no superview")
            return
        }
        catalogueContainer.isHidden = newHeight == 0
        updateLayout()
        delegate?.topContainerDidUpdateSubviews()
        setAlpha(to: 1.0)
    }
}
