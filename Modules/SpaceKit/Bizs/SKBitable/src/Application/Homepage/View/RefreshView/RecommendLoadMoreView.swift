//
//  RecommendLoadMoreView.swift
//  SKBitable
//
//  Created by justin on 2023/9/4.
//

import Foundation
import ESPullToRefresh
import SnapKit
import SKResource
import UniverseDesignColor
import LarkLocalizations

class RecommendLoadMoreView: ESRefreshFooterView {
    
    /// trigger load more data when distance is less than bottomTrigerHeight value.
    static let bottomTrigerHeight = CGFloat(200.0)
    
    lazy var failTipsLabel: UILabel = {
        let tipsLabel = UILabel(frame: .zero)
        tipsLabel.font = .systemFont(ofSize: 14)
        tipsLabel.textColor = UDColor.textCaption
        
        var retryDesc = BundleI18n.SKResource.Bitable_Homepage_LoadFailedRetry_Button
        var tipsStr = BundleI18n.SKResource.Bitable_Homepage_LoadFailedRetry_Desc(retryDesc)
        
        if tipsStr.isEmpty {
            retryDesc = BundleI18n.SKResource.Bitable_Homepage_LoadFailedRetry_Button(lang: Lang.es_ES)
            tipsStr = BundleI18n.SKResource.Bitable_Homepage_LoadFailedRetry_Desc(retryDesc, lang: Lang.es_ES)
        }
        tipsLabel.text = tipsStr
        tipsLabel.textAlignment = .center
        return tipsLabel
    }()
    
    var failLoadMore = false {
        didSet {
            if failLoadMore {
                self.addFailViewIfNeed()
            }
        }
    }
    
    func addFailViewIfNeed() {
        if failTipsLabel.superview == nil {
            addSubview(failTipsLabel)
            failTipsLabel.isUserInteractionEnabled = true
            failTipsLabel.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.height.equalTo(CGFloat(30.0))
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tryLoadMoreForFail))
            failTipsLabel.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc
    func tryLoadMoreForFail() {
        self.failLoadMore = false
        self.startRefreshing()
    }
    
    override func offsetChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey : Any]?) {
        guard let scrollView = scrollView else {
            return
        }
        
        guard isRefreshing == false && isAutoRefreshing == false && noMoreData == false && isHidden == false && failLoadMore == false else {
            return
        }

        if scrollView.contentSize.height <= 0.0 || scrollView.contentOffset.y + scrollView.contentInset.top <= 0.0 {
            self.alpha = 0.0
            return
        } else {
            self.alpha = 1.0
        }
        
        if scrollView.contentSize.height + scrollView.contentInset.top > scrollView.bounds.size.height {
            // 内容超过一个屏幕 计算公式，判断是不是在拖在到了底部
            if scrollView.contentSize.height - scrollView.contentOffset.y + scrollView.contentInset.bottom  <= scrollView.bounds.size.height + Self.bottomTrigerHeight {
                self.animator.refresh(view: self, stateDidChange: .refreshing)
                self.startRefreshing()
            }
        } else {
            //内容没有超过一个屏幕，这时拖拽高度大于1/2footer的高度就表示请求上拉
            if scrollView.contentOffset.y + scrollView.contentInset.top >= animator.trigger / 2.0 {
                self.animator.refresh(view: self, stateDidChange: .refreshing)
                self.startRefreshing()
            }
        }
    }
    
    
    override func start() {
        guard scrollView != nil else {
            return
        }
        self.failTipsLabel.isHidden = true
        self.animator.refreshAnimationBegin(view: self)
        self.handler?()
    }
    
    override func stop() {
        guard scrollView != nil else {
            return
        }
        
        self.failTipsLabel.isHidden = !self.failLoadMore
        self.animator.refreshAnimationEnd(view: self)
        self._isRefreshing = false
        self._isAutoRefreshing = false
        // Back state
//        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
//        }, completion: { (finished) in
//            if self.failLoadMore == false {
//                self.animator.refresh(view: self, stateDidChange: .pullToRefresh)
//            }
//            self._isRefreshing = false
//            self._isAutoRefreshing = false
//        })
    }
    
    func failStopLoadingMore() {
        self.failLoadMore = true
        if let animatorView = self.animator as? UIView {
            animatorView.isHidden = true
        }
        self.stopRefreshing()
    }
}

extension ES where Base: UIScrollView {

    @discardableResult
    func addRecommendLoadMore(animator: ESRefreshProtocol & ESRefreshAnimatorProtocol,handler: @escaping ESRefreshHandler) -> RecommendLoadMoreView {
        removeRefreshFooter()
        let footer = RecommendLoadMoreView(frame: CGRect.zero, handler: handler, animator:animator)
        let footerH = footer.animator.executeIncremental
        footer.frame = CGRect.init(x: 0.0, y: self.base.contentSize.height + self.base.contentInset.bottom, width: self.base.bounds.size.width, height: footerH)
        self.base.footer = footer
        self.base.addSubview(footer)
        return footer
    }
}
