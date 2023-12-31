//
//  RefreshAnimator.swift
//  ByteView
//
//  Created by huangshun on 2020/1/17.
//

import Foundation
import Lottie
import ESPullToRefresh

open class RefreshAnimator: UIView {

    public var state: ESRefreshViewState = .pullToRefresh
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    public var trigger: CGFloat = 48
    public var executeIncremental: CGFloat = 48

    private let animatorSize = CGSize(width: 24, height: 24)
    private let circleSize = CGSize(width: 17, height: 17)
    private let animatorButtonOffset: CGFloat = 6

    private lazy var animationView: LOTAnimationView = {
        let animationView = LOTAnimationView(name: "videochat_loading_blue", bundle: .localResources)
        animationView.backgroundColor = UIColor.clear
        animationView.loopAnimation = true
        animationView.autoReverseAnimation = false
        animationView.contentMode = .scaleAspectFit
        animationView.isHidden = true
        animationView.frame.size = animatorSize
        return animationView
    }()

    private lazy var circleView: CircleProgressView = {
        let view = CircleProgressView()
        view.backgroundColor = UIColor.clear
        view.frame.size = circleSize
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(animationView)
        addSubview(circleView)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        animationView.center = CGPoint(
            x: frame.width / 2.0,
            y: frame.height / 2.0
        )
        circleView.center = CGPoint(
            x: frame.width / 2.0,
            y: frame.height / 2.0
        )
    }
}

extension RefreshAnimator: ESRefreshProtocol {
    public func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.play()
        animationView.isHidden = false
        circleView.isHidden = true
        circleView.update(progress: 0)
    }

    public func refreshAnimationEnd(view: ESRefreshComponent) {
        animationView.stop()
        animationView.isHidden = true
    }

    public func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        // 为了实现动画view在可见区域后才开始显示动画，需要在这里对progress进行重新映射
        // animator 完全显示后的偏移量
        let actualOffset: CGFloat = progress * executeIncremental - animatorSize.height - animatorButtonOffset
        if actualOffset <= 0 {
            circleView.update(progress: 0)
            return
        }
        let actualProgress: CGFloat = actualOffset / (executeIncremental - animatorSize.height - animatorButtonOffset)
        circleView.update(progress: actualProgress)
    }

    public func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else {
            return
        }
        self.state = state
        if state == .pullToRefresh {
            circleView.isHidden = false
        }
        self.setNeedsLayout()
    }
}

extension RefreshAnimator: ESRefreshAnimatorProtocol {
    public var view: UIView { return self }
}
