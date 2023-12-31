//
//  FeedMainViewController+LazyLoad.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/15.
//

import SnapKit

extension FeedMainViewController {
    func lazyLoad() {
        guard needLazyLoad else { return }
        needLazyLoad = false

        initBottomBar()
    }

    private var needLazyLoad: Bool {
        get {
            return _needLazyLoad
        }
        set {
            if _needLazyLoad == true, _needLazyLoad != newValue {
                _needLazyLoad = newValue
            }
        }
    }

    private func initBottomBar() {
        self.view.addSubview(bottomBarView)
        bottomBarView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        self.bindBottomBar()
    }
}
