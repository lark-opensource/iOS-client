//
//  MailAttachmentsManagerViewController+Refresh.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import RxSwift
import LarkUIKit
import Lottie
import ESPullToRefresh
import UniverseDesignLoading
import UniverseDesignIcon

extension MailAttachmentsManagerViewController: RefreshHeaderViewDelegate {
    func refreshAnimationBegin(view: ESPullToRefresh.ESRefreshComponent) {
        
    }
    
    func refreshAnimationEnd(view: ESPullToRefresh.ESRefreshComponent) {
        
    }
    
    func progressDidChange(view: ESPullToRefresh.ESRefreshComponent, progress: CGFloat) {
    }
    
    func stateDidChange(view: ESPullToRefresh.ESRefreshComponent, state: ESPullToRefresh.ESRefreshViewState) {
    }
    
    func configTabelViewRefresh() {
        configHeaderRefresh()
        configFooterRefresh()
    }
    
    func configHeaderRefresh() {
        header.delegate = self
        tableView.es.addPullToRefresh(animator: header) { [weak self] in
            self?.viewModel.pullRefresh()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (timeIntvl.normal)) { [weak self] in
            self?.header.refreshPostion()
        }
    }

    func configFooterRefresh() {
        footer.titleText = ""
        tableView.es.addInfiniteScrolling(animator: footer) { [weak self] in
            self?.loadMoreIfNeeded()
        }
    }
    
    func loadMoreIfNeeded() {
        if !viewModel.hasMore {
            if self.viewModel.dataSource.count > 0 {
                self.tableView.es.noticeNoMoreData()

            } else {
                self.tableView.es.stopLoadingMore()
            }
        } else {
            self.viewModel.loadMore()
        }
    }
}
