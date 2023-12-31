//
//  QuickTabBar.swift
//  AnimatedTabBar
//
//  Created by 夏汝震 on 2021/6/4.
//

import Foundation
import UIKit

final class QuickTabBar: UIView {

    private let contentView: QuickTabBarContentViewInterface
    private weak var scrollView: UIScrollView?
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        return tapGesture
    }()
    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        return panGesture
    }()
    internal weak var delegate: QuickTabBarDelegate?

    private var showAnimationLock: Bool = false
    private var dismissAnimationLock: Bool = false

    init(frame: CGRect, contentView: QuickTabBarContentViewInterface, delegate: QuickTabBarDelegate) {
        self.contentView = contentView
        self.delegate = delegate
        super.init(frame: frame)
        // 开始时不展示内容视图
        self.addSubview(self.contentView)
        self.tapGesture.delegate = self
        self.addGestureRecognizer(self.tapGesture)
        self.panGesture.delegate = self
        self.addGestureRecognizer(self.panGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has falset been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateContentViewSize()
        updateContentViewY(self.frame.size.height - self.contentView.frame.size.height)
    }

    func show(isSlide: Bool = false) {
        guard !showAnimationLock else { return }
        showAnimationLock = true
        UIView.animate(withDuration: 0.15) {
            let contentViewY = self.frame.size.height - self.contentView.frame.size.height
            self.updateContentViewY(contentViewY)
            self.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(QuickTabBarConfig.Style.alphaPercent)
        } completion: { _ in
            self.delegate?.quickTabBarDidShow(self, isSlide: isSlide)
            self.showAnimationLock = false
        }
    }

    func dismiss(isSlide: Bool) {
        guard !dismissAnimationLock else { return }
        dismissAnimationLock = true
        UIView.animate(withDuration: 0.15) {
            self.updateContentViewY(self.frame.size.height)
            self.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0)
        } completion: { _ in
            self.delegate?.quickTabBarDidDismiss(self, isSlider: isSlide)
            self.dismissAnimationLock = false
            self.removeFromSuperview()
        }
    }

    @objc
    func handleTapGesture(tapGesture: UITapGestureRecognizer) {
        dismiss()
    }

    @objc
    func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: contentView)
        let point = panGesture.location(in: scrollView)
        let isOperScrollView = scrollView?.layer.contains(point) ?? false
        if isOperScrollView {
            // 当手指在scrollView滑动时
            guard let scrollView = self.scrollView else { return }
            if scrollView.contentOffset.y <= 0 {
                // 当scrollView在最顶部时
                if translation.y > 0 {
                    // 向下拖拽
                    changeScrollEnabled(false)
                    scrollView.contentOffset = .zero
                    let contentViewY = self.contentView.frame.origin.y + translation.y
                    updateContentViewY(contentViewY)
                }
            }
        } else {
            if translation.y > 0 {
                // 向下拖拽
                let contentViewY = self.contentView.frame.origin.y + translation.y
                updateContentViewY(contentViewY)
            } else if translation.y < 0 {
                // 向上拖拽
                let contentMinY = self.frame.size.height - self.contentView.frame.size.height
                let contentY = self.contentView.frame.origin.y
                if contentY > contentMinY {
                    let contentViewY = max(contentY + translation.y, contentMinY)
                    updateContentViewY(contentViewY)
                }
            }
        }

        if panGesture.state == .ended {
            changeScrollEnabled(true)
            // 手指离开屏幕时，进行展示/收起contentView
            showOrDismissWhenPanEnd()
        }

        // 复位
        panGesture.setTranslation(.zero, in: contentView)
    }

    private func updateContentViewSize() {
        var contentFrame = self.contentView.frame
        contentFrame.size.width = self.frame.size.width
        guard self.delegate != nil else { return }
        let contentHeight = contentView.maxHeight
        let suppliedMaxHeight = self.frame.size.height - safeAreaHeight()
        contentFrame.size.height = min(contentHeight, suppliedMaxHeight)
        self.contentView.frame = contentFrame
    }

    private func safeAreaMinY() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets.top
        } else {
            return self.layoutMargins.top
        }
    }

    private func safeAreaHeight() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets.top + self.safeAreaInsets.bottom
        } else {
            return self.layoutMargins.top + self.layoutMargins.bottom
        }
    }

    private func updateContentViewY(_ contentViewY: CGFloat) {
        var contentFrame = self.contentView.frame
        // contentView不能高于容器
        let minY = safeAreaMinY()
        contentFrame.origin.y = max(contentViewY, minY)
        self.contentView.frame = contentFrame

        let criticalY = self.frame.size.height - self.contentView.frame.size.height
        let progress = 1 - (self.contentView.frame.origin.y - criticalY) / self.contentView.frame.size.height
        updateToProgress(progress)
    }

    private func updateToProgress(_ progress: CGFloat) {
        let alpha = QuickTabBarConfig.Style.alphaPercent * progress
        self.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(alpha)
        contentView.updateToProgress(progress)
    }

    private func changeScrollEnabled(_ enabled: Bool) {
        self.scrollView?.panGestureRecognizer.isEnabled = enabled
    }

    private func showOrDismissWhenPanEnd() {
        let height = frame.size.height
        let height1 = contentView.frame.size.height * QuickTabBarConfig.Style.autoAnimationPercent
        let criticalY = height - height1
        if self.contentView.frame.origin.y > criticalY {
            dismiss(isSlide: true)
        } else {
            show(isSlide: true)
        }
    }
}

extension QuickTabBar: UIGestureRecognizerDelegate {
    // 获取内部的scroll
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        self.scrollView = nil
        if gestureRecognizer == self.panGesture {
            var touchView = touch.view
            while touchView != nil {
                if let touchView1 = touchView as? UIScrollView {
                    self.scrollView = touchView1
                    return true
                }
                if let next = touchView?.next, let nextView = next as? UIView {
                    touchView = nextView
                } else {
                    touchView = nil
                }
            }
        }
        return true
    }

    // 控制手势事件传递
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.tapGesture {
            let point = gestureRecognizer.location(in: contentView)
            if self.contentView.layer.contains(point) && gestureRecognizer.view == self {
                // 防止点到scroll区域
                return false
            }
        } else if gestureRecognizer == self.panGesture {
            return true
        }
        return true
    }

    // 是否允许两个手势同时存在
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let scrollView = self.scrollView else { return false }
        let result = (gestureRecognizer == self.panGesture) && (otherGestureRecognizer == scrollView.panGestureRecognizer)
        return result
    }
}

extension QuickTabBar: QuickTabBarInterface {
    func show(contentView: UIView, delegate: QuickTabBarDelegate) {
        layoutIfNeeded()
        updateContentViewY(frame.size.height)
        show()
    }

    func dismiss() {
        dismiss(isSlide: false)
    }

    func layout() {
        // 重新对contentView进行布局。常见case：当contentView的数据发生变化时，对height和y值进行刷新
        layoutSubviews()
    }
}
