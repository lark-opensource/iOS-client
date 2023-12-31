//
//  RefreshFooterView.swift
//  Pods
//
//  Created by huahuahu on 2018/6/20.
//
//  Included OSS: GodEye
//  Copyright (c) 2017 陈奕龙(子循)
//  spdx license identifier: MIT

import UIKit
import Lottie
import ESPullToRefresh
import SKResource

public final class DocsThreeDotRefreshAnimator: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {

    private var noMoreDataDescription: String = BundleI18n.SKResource.Doc_Normal_NoMoreData

    public var view: UIView { return self }
    private var duration: TimeInterval = 0.3
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    public var trigger: CGFloat = 42.0
    public var executeIncremental: CGFloat = 66.0
    public var state: ESRefreshViewState = .pullToRefresh

    fileprivate let titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.N500
        label.textAlignment = .center
        return label
    }()

    private let animationView: LOTAnimationView = {
        let animation = AnimationViews.loadingAnimation
        animation.backgroundColor = UIColor.clear
        animation.autoReverseAnimation = true
        animation.loopAnimation = true
        animation.contentMode = .center
        animation.isHidden = true
        animation.frame = CGRect(x: 146, y: 100, width: 83, height: 66)
        return animation
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = nil
        addSubview(titleLabel)
        addSubview(animationView)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.play()
        titleLabel.text = nil
        animationView.isHidden = false
    }

    public func refreshAnimationEnd(view: ESRefreshComponent) {
        animationView.stop()
        titleLabel.text = nil
        animationView.isHidden = true
    }

    public func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        // do nothing
    }

    public func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else {
            return
        }
        self.state = state

        switch state {
        case .refreshing, .autoRefreshing :
            titleLabel.text = nil
        case .noMoreData:
            titleLabel.text = noMoreDataDescription
        case .pullToRefresh:
            titleLabel.text = nil
        default:
            break
        }
        self.setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let s = self.bounds.size
        let w = s.width
        let h = s.height

        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: w / 2.0, y: h / 2.0 - 5.0)
        animationView.center = CGPoint(x: w / 2.0, y: h / 2.0 )
    }
}
