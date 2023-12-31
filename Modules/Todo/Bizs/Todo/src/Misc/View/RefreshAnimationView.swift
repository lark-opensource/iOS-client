//
//  RefreshAnimationView.swift
//  Todo
//
//  Created by 张威 on 2020/12/7.
//

import ESPullToRefresh
import Lottie
import LarkExtensions
import LarkActivityIndicatorView

class RefreshAnimationView: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    var insets: UIEdgeInsets = .zero
    var view: UIView { self }
    var duration: TimeInterval = 0.3
    var trigger: CGFloat = 56.0
    var executeIncremental: CGFloat = 56.0
    var state: ESRefreshViewState = .pullToRefresh

    private let indicatorView = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.center.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshAnimationBegin(view: ESRefreshComponent) {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        indicatorView.isHidden = true
        indicatorView.stopAnimating()
    }

    func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) { }

    func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else { return }
        self.state = state
    }
}
