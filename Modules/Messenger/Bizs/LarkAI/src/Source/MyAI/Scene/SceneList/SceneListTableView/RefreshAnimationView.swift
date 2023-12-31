//
//  RefreshAnimationView.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import ESPullToRefresh // 上拉加载、下拉刷新
import LarkActivityIndicatorView // ActivityIndicatorView

/// 上拉加载、下拉刷新
final class RefreshAnimationView: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    var view: UIView { self }
    var insets: UIEdgeInsets = .zero
    var trigger: CGFloat = 44 // 上拉加载看源码不是按照这个值来的
    var executeIncremental: CGFloat = 44
    var state: ESRefreshViewState = .pullToRefresh

    private let animationView = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(animationView)
        animationView.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.center.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.isHidden = false
        animationView.startAnimating()
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        animationView.isHidden = true
        animationView.stopAnimating()
    }

    func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {}

    func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else { return }
        self.state = state
    }
}
