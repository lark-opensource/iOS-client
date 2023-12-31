//
//  SearchPopupContainer.swift
//  LarkSearch
//
//  Created by wangjingcan on 2023/6/26.
//

import Foundation
import UIKit
import SnapKit

final class SearchPopupContainer: UIView {

    private static let AnimationHeight = UIDevice.btd_screenHeight()
    private static let AnimationDuration = 0.25
    private static let MaskAlphaPercent = 0.1
    private static let AutoDismissPercent = 0.75

    private var duration = SearchPopupContainer.AnimationDuration
    private let contentView: ISearchPopupContentView
    private var internalScrollView: UIScrollView?

    private var isDoingShowAnimation: Bool = false
    private var isDoingDismissAnimation: Bool = false

    private lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        return view
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        return tapGesture
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        return panGesture
    }()

    init(frame: CGRect, contentView: ISearchPopupContentView) {
        self.contentView = contentView
        super.init(frame: frame)
        self.addSubview(self.bgView)
        self.bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        self.tapGesture.delegate = self
        self.addGestureRecognizer(self.tapGesture)
        self.panGesture.delegate = self
        self.addGestureRecognizer(self.panGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateContentYAndMask(self.frame.size.height - self.contentView.frame.size.height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has falset been implemented")
    }

    private func internalShow(isPan: Bool = false) {
        guard !self.isDoingShowAnimation else { return }
        let duration = (CGFloat(self.contentView.frame.size.height) / SearchPopupContainer.AnimationHeight) * SearchPopupContainer.AnimationDuration
        self.duration = duration <= 0 ? SearchPopupContainer.AnimationDuration : duration
        self.isDoingShowAnimation = true
        UIView.animate(withDuration: self.duration, delay: 0, options: .curveEaseInOut) {
            let contentY = self.frame.size.height - self.contentView.frame.size.height
            self.bgView.alpha = 1
            self.updateContentYAndMask(contentY)
        } completion: { _ in
            self.isDoingShowAnimation = false
        }
    }

    private func internalDismiss(isPan: Bool = false, dismissCompletion: @escaping () -> Void = {}) {
        guard !self.isDoingDismissAnimation else { return }
        self.duration = self.duration <= 0 ? SearchPopupContainer.AnimationDuration : self.duration
        self.isDoingDismissAnimation = true
        UIView.animate(withDuration: self.duration) {
            self.bgView.alpha = 0
            self.updateContentYAndMask(self.frame.size.height)
        } completion: { _ in
            self.isDoingDismissAnimation = false
            self.removeFromSuperview()
            dismissCompletion()
        }
    }

    private func updateContentYAndMask(_ contentY: CGFloat) {
        var contentFrame = self.contentView.frame
        let minY = self.safeAreaMinY()
        contentFrame.origin.y = max(contentY, minY)
        self.contentView.frame = contentFrame
    }

    @objc
    private func handleTapGesture(tapGesture: UITapGestureRecognizer) {
        internalDismiss()
    }

    @objc
    private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: self.contentView)
        let location = panGesture.location(in: self.internalScrollView)
        let panOnScrollView = self.internalScrollView?.layer.contains(location) ?? false
        if panOnScrollView {
            guard let scrollView = self.internalScrollView else { return }
            if translation.y > 0 {
                let contentY = self.contentView.frame.origin.y + translation.y
                if scrollView.contentOffset.y <= 0 {
                    scrollView.panGestureRecognizer.isEnabled = false
                    scrollView.contentOffset = .zero
                    updateContentYAndMask(contentY)
                }
            }
        } else {
            if translation.y > 0 {
                let contentY = self.contentView.frame.origin.y + translation.y
                updateContentYAndMask(contentY)
            } else {
                let fixY = self.frame.size.height - self.contentView.frame.size.height
                if self.contentView.frame.origin.y > fixY {
                    let contentY = max(fixY, self.contentView.frame.origin.y + translation.y)
                    updateContentYAndMask(contentY)
                }
            }
        }

        if panGesture.state == .ended {
            self.internalScrollView?.panGestureRecognizer.isEnabled = true
            self.showOrDismissWhenPanOver()
        }

        panGesture.setTranslation(.zero, in: self.contentView)

    }

    private func showOrDismissWhenPanOver() {
        let autoDismissY = self.frame.size.height - self.contentView.frame.size.height * SearchPopupContainer.AutoDismissPercent
        if self.contentView.frame.origin.y > autoDismissY {
            internalDismiss(isPan: true)
        } else {
            internalShow(isPan: true)
        }
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
}

extension SearchPopupContainer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        self.internalScrollView = nil
        if gestureRecognizer == self.panGesture {
            var touchView = touch.view
            while touchView != nil {
                if let touchScrollView = touchView as? UIScrollView {
                    self.internalScrollView = touchScrollView
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

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.tapGesture {
            let point = gestureRecognizer.location(in: self.contentView)
            if self.contentView.layer.contains(point) && gestureRecognizer.view == self {
                return false
            }
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView = self.internalScrollView else { return false }
        let result = gestureRecognizer == self.panGesture && otherGestureRecognizer == scrollView.panGestureRecognizer
        return result
    }
}

extension SearchPopupContainer: ISearchPopupView {
    func show() {
        layoutIfNeeded()
        self.updateContentYAndMask(self.frame.size.height)
        self.bgView.alpha = 0
        internalShow()
    }

    func dismiss(completion: @escaping () -> Void) {
        internalDismiss(dismissCompletion: {
            completion()
        })
    }

}
