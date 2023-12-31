//
//  MinutesRefreshFooterAnimator.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/2/25.
//

import Foundation
import Lottie
import ESPullToRefresh

public final class MinutesRefreshFooterAnimator: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {

    public var view: UIView { return self }
    private var duration: TimeInterval = 0.3
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    public var trigger: CGFloat = 42.0
    public var executeIncremental: CGFloat = 66.0
    public var state: ESRefreshViewState = .pullToRefresh

    private let animationView: LOTAnimationView = {

        let jsonPath = BundleConfig.MinutesFoundationBundle.path(
            forResource: "loading",
            ofType: "json",
            inDirectory: "lottie")
        let animation = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()

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
        addSubview(animationView)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.play()
        animationView.isHidden = false
    }

    public func refreshAnimationEnd(view: ESRefreshComponent) {
        animationView.stop()
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
        self.setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let s = self.bounds.size
        let w = s.width
        let h = s.height
        animationView.center = CGPoint(x: w / 2.0, y: h / 2.0 )
    }
}
