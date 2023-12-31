//
//  MailFeedDraftListViewController+Refresh.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/21.
//

import Foundation
import RxSwift
import LarkUIKit
import Lottie
import ESPullToRefresh
import UniverseDesignLoading
import UniverseDesignIcon

extension MailFeedDraftListViewController: RefreshHeaderViewDelegate {
    func refreshAnimationBegin(view: ESPullToRefresh.ESRefreshComponent) {
        
    }
    
    func refreshAnimationEnd(view: ESPullToRefresh.ESRefreshComponent) {
        
    }
    
    func progressDidChange(view: ESPullToRefresh.ESRefreshComponent, progress: CGFloat) {
    }
    
    func stateDidChange(view: ESPullToRefresh.ESRefreshComponent, state: ESPullToRefresh.ESRefreshViewState) {
    }
    
    func configTabelViewRefresh() {
        configFooterRefresh()
    }

    func configFooterRefresh() {
        footer.titleText = ""
        footer.executeIncremental = 60 + view.safeAreaInsets.bottom
        tableView.es.addInfiniteScrolling(animator: footer) { [weak self] in
            self?.loadMoreIfNeeded()
        }
    }
    
    func loadMoreIfNeeded() {
        if !viewModel.hasMore {
            if !self.viewModel.dataSource.isEmpty {
                self.tableView.es.noticeNoMoreData()
            } else {
                self.tableView.es.stopLoadingMore()
            }
        } else {
            self.viewModel.loadMore()
        }
    }
}
