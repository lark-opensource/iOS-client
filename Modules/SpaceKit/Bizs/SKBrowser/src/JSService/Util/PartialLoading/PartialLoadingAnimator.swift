//
//  ParticalLoadingAnimator.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/28.
//
// 处理分屏渲染的view展示

import Foundation
import Lottie
import SnapKit
import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface
import SKInfra

class PartialLoadingAnimator {
    weak var hostView: UIView?
    private var updatedInnerHeight: CGFloat?

    init(hostView: UIView?) {
        self.hostView = hostView
    }

    private lazy var partialLoadingAnimateView: DocsLoadingViewProtocol = {
        let view = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
        view.displayContent.backgroundColor = .clear
        return view
    }()

    lazy var partialLoadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        view.alpha = 0.7
        view.accessibilityIdentifier = "partialloadingview"
        return view
    }()
    private var partialLoadingViewConstraints = [SnapKit.Constraint]()
    private var partialLoadingViewHeightConstraint: SnapKit.Constraint?

    func showPartialLoadingViewIfNeeded() {
        guard let canvas = hostView else { return }
        spaceAssert(Thread.isMainThread)
        if partialLoadingView.superview == nil {
            partialLoadingView.addSubview(partialLoadingAnimateView.displayContent)
            canvas.addSubview(partialLoadingView)
            partialLoadingView.snp.makeConstraints { (make) in
                if updatedInnerHeight != nil {
                    partialLoadingViewHeightConstraint = make.height.equalTo(updatedInnerHeight!).labeled("高度根据键盘").constraint
                } else {
                    partialLoadingViewHeightConstraint = make.bottom.equalToSuperview().labeled("底部对齐").constraint
                }
                partialLoadingViewConstraints.append(make.leading.trailing.equalToSuperview().labeled("width").constraint)
                partialLoadingViewConstraints.append(make.top.equalToSuperview().labeled("loadingTop").constraint)
            }
            partialLoadingAnimateView.displayContent.snp.makeConstraints { (make) in
                partialLoadingViewConstraints.append(make.width.equalTo(200).labeled("loadingAnimateViewWidth").constraint)
                partialLoadingViewConstraints.append(make.height.equalTo(200).labeled("loadingAnimateViewHeight").constraint)
                partialLoadingViewConstraints.append(make.center.equalToSuperview().labeled("loadingAnimateViewCenter").constraint)
            }
        }
        partialLoadingView.isHidden = false
        partialLoadingViewConstraints.forEach({ $0.activate() })
        partialLoadingViewHeightConstraint?.deactivate()
        // 这句话要放在 active 之后
        partialLoadingView.snp.makeConstraints { (make) in
            if updatedInnerHeight != nil {
                partialLoadingViewHeightConstraint = make.height.equalTo(updatedInnerHeight!).labeled("高度根据键盘").constraint
            } else {
                partialLoadingViewHeightConstraint = make.bottom.equalToSuperview().labeled("底部对齐").constraint
            }
        }
        partialLoadingViewHeightConstraint?.activate()
        partialLoadingAnimateView.startAnimation()
        canvas.bringSubviewToFront(partialLoadingView)
    }

    func updatePartialLoadingViewHeightIfNeeded(_ targetHeight: CGFloat) {
        updatedInnerHeight = targetHeight + 88
        if partialLoadingView.isHidden == false, partialLoadingView.superview != nil {
            partialLoadingViewHeightConstraint?.deactivate()
            partialLoadingView.snp.makeConstraints { (make) in
                partialLoadingViewHeightConstraint = make.height.equalTo(updatedInnerHeight!).labeled("高度根据键盘").constraint
            }
        }
    }

    func hidePartialLoading() {
        guard partialLoadingView.isHidden == false else { return }
        partialLoadingViewConstraints.forEach({ $0.deactivate() })
        partialLoadingViewHeightConstraint?.deactivate()
        if partialLoadingView.superview != nil {
            partialLoadingAnimateView.stopAnimation()
        }
        partialLoadingView.isHidden = true
    }

    func resetPartialLoading() {
        spaceAssert(Thread.isMainThread)
        hidePartialLoading()
        partialLoadingViewHeightConstraint = nil
        partialLoadingViewConstraints.removeAll()
        partialLoadingView.removeFromSuperview()
        updatedInnerHeight = nil
    }
}
