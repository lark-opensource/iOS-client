//
//  LKAssetBrowserLoadMoreHelper.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/9/13.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

final class LKAssetBrowserLoadMoreHelper {
    var isShowLoading: Bool = false
    var isLoadingOld: Bool = false
    var isLoadingNew: Bool = false

    var hasMoreOld: Bool = true
    var hasMoreNew: Bool = true

    enum MoreType {
        case old
        case new
    }

    private let indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        return indicator
    }()

    private let indicatorLabel: UILabel = {
        let label = UILabel.lu.labelWith(fontSize: 12, textColor: UIColor.white)
        label.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_AssetBrowserLoadMore
        return label
    }()

    private let handler: LKAssetBrowserActionHandler
    private unowned let browser: LKAssetBrowserViewController

    init(handler: LKAssetBrowserActionHandler, browser: LKAssetBrowserViewController) {
        self.handler = handler
        self.browser = browser
    }

    func showLoadMoreView(type: MoreType, to superView: UIView) {
        switch type {
        case .old:
            if !self.hasMoreOld { return }
        case .new:
            if !self.hasMoreNew { return }
        }

        if self.isShowLoading {
            return
        }
        self.isShowLoading = true

        superView.insertSubview(indicatorView, at: 0)
        self.indicatorView.startAnimating()
        switch type {
        case .old:
            self.indicatorView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(30)
            }
        case .new:
            self.indicatorView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-30)
            }
        }
        superView.insertSubview(indicatorLabel, at: 0)
        self.indicatorLabel.snp.makeConstraints { (make) in
            make.top.equalTo(indicatorView.snp.bottom).offset(5)
            make.centerX.equalTo(indicatorView)
        }
    }

    func dismissLoadMoreView() {
        if !self.isShowLoading {
            return
        }
        self.indicatorView.stopAnimating()
        self.indicatorView.removeFromSuperview()
        self.indicatorLabel.removeFromSuperview()
        self.isShowLoading = false
    }

    func loadMore(_ type: MoreType) {
        switch type {
        case .old:
            if !self.hasMoreOld || self.isLoadingOld {
                return
            }
            self.isLoadingOld = true
            self.handler.handleLoadMoreOld { [weak self] (assets, hasMore) in
                guard let `self` = self else {
                    return
                }

                self.hasMoreOld = hasMore
                self.bufferDataTaskIfNeeded(assets, type: type)
                self.isLoadingOld = false
            }
        case .new:
            if !self.hasMoreNew || self.isLoadingNew {
                return
            }
            self.isLoadingNew = true
            self.handler.handleLoadMoreNew { [weak self] (assets, hasMore) in
                guard let `self` = self else {
                    return
                }

                self.hasMoreNew = hasMore
                self.bufferDataTaskIfNeeded(assets, type: type)
                self.isLoadingNew = false
            }
        }
    }

    private func bufferDataTaskIfNeeded(_ assets: [LKDisplayAsset], type: MoreType) {
        if self.isDataTaskBuffered {
            self.taskQueue.append { [weak self] in
                self?.browser.insertAssets(assets, type: type)
            }
        } else {
            self.browser.insertAssets(assets, type: type)
        }
    }

    private var taskQueue: [() -> Void] = []
    var isDataTaskBuffered: Bool = false {
        didSet {
            if !self.isDataTaskBuffered {
                if self.taskQueue.isEmpty {
                    return
                }

                taskQueue.forEach { $0() }
                taskQueue.removeAll()
            }
        }
    }
}
