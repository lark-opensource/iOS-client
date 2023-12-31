//
//  WikiHomePageRefreshAnimator.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/4.
//  

import UIKit
import Lottie
import ESPullToRefresh
import SKUIKit
import UniverseDesignLoading

public final class WikiHomePageRefreshAnimator: UIView {

    public var state: ESRefreshViewState = .pullToRefresh
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    public var trigger: CGFloat = 60
    public var executeIncremental: CGFloat = 60

    private let animatorSize = CGSize(width: 18, height: 18)
    private let animatorButtonOffset: CGFloat = 5

    private var spinConfig: UDSpinConfig {
        let indicatorConfig: UDSpinIndicatorConfig = UDSpinIndicatorConfig(size: 18, color: circleView.circleColor)
        return UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: nil)
    }

    private lazy var animationView: UDSpin = {
        let spin = UDLoading.spin(config: spinConfig)
        spin.isHidden = true
        spin.frame.size = CGSize(width: 20, height: 20)
        return spin
    }()

    private lazy var circleView: WikiCircleProgressView = {
        let view = WikiCircleProgressView()
        view.backgroundColor = UIColor.clear
        view.frame.size = animatorSize
        return view
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(animationView)
        addSubview(circleView)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        animationView.center = CGPoint(x: frame.width / 2.0,
                                       y: frame.height - animationView.frame.height / 2 - animatorButtonOffset )
        circleView.center = CGPoint(x: frame.width / 2.0,
                                    y: frame.height - animationView.frame.height / 2 - animatorButtonOffset )
    }

    public func update(circleColor: UIColor) {
        circleView.circleColor = circleColor
    }
}

extension WikiHomePageRefreshAnimator: ESRefreshProtocol {
    public func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.update(config: spinConfig)
        animationView.isHidden = false
        circleView.isHidden = true
        circleView.update(progress: 0)
    }

    public func refreshAnimationEnd(view: ESRefreshComponent) {
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
        switch state {
        case .pullToRefresh:
            circleView.isHidden = false
        case .releaseToRefresh:
            break
        case .refreshing:
            break
        case .autoRefreshing:
            break
        case .noMoreData:
            break
        }
        self.setNeedsLayout()
    }
}

extension WikiHomePageRefreshAnimator: ESRefreshAnimatorProtocol {
    public var view: UIView {
        return self
    }
}
