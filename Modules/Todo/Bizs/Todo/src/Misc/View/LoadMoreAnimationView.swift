//
//  LoadMoreAnimationView.swift
//  Todo
//
//  Created by 张威 on 2020/12/7.
//

import ESPullToRefresh
import Lottie
import LarkExtensions
import LarkActivityIndicatorView
import UniverseDesignFont

class LoadMoreAnimationView: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    var view: UIView { self }
    var insets: UIEdgeInsets = .zero
    var trigger: CGFloat = 33
    var executeIncremental: CGFloat = 44
    var state: ESRefreshViewState = .pullToRefresh
    var duration: TimeInterval = 0.3

    private var animationView: ActivityIndicatorView!
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UDFont.systemFont(ofSize: 12.0)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        animationView = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)
        animationView.frame = CGRect(x: 146, y: 100, width: 48, height: 16)
        animationView.backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        addSubview(animationView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.sizeToFit()
        titleLabel.frame.center = bounds.center
        animationView.frame.center = bounds.center
    }

    func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.startAnimating()
        showLoading(animation: true)
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        animationView.stopAnimating()
        hideLoading(animation: true)
    }

    func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        // do nothing
    }

    func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else { return }
        self.state = state
        if state == .noMoreData {
            showNoMore(animation: true)
        } else {
            titleLabel.text = nil
        }
        setNeedsLayout()
    }

    private func showNoMore(animation: Bool) {
        // 暂时不支持 no more 文案
        titleLabel.text = nil
        UIView.animate(
            withDuration: animation ? 0.2 : 0,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.animationView.alpha = 0
                self.titleLabel.alpha = 1.0
            }
        )
    }

    private func showLoading(animation: Bool) {
        animationView.isHidden = false
        UIView.animate(
            withDuration: animation ? 0.2 : 0,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.animationView.alpha = 1.0
            }
        )
    }

    private func hideLoading(animation: Bool) {
        UIView.animate(
            withDuration: animation ? 0.2 : 0,
            delay: 0,
            options: .curveEaseInOut,
            animations: { self.animationView.alpha = 0.0 },
            completion: { _ in self.animationView.isHidden = true }
        )
    }
}
