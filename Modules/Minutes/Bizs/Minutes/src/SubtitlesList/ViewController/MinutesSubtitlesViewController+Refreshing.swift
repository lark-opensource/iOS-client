//
//  MinutesSubtitlesViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import ESPullToRefresh
import UniverseDesignToast
import MinutesNetwork

extension MinutesSubtitlesViewController {
    func configHeaderRefresh() {
        if let tableView = tableView {
            if tableView.header != nil { return }
            
            viewModel.endPullRefreshCallBack = {[weak self] in
                self?.stopRefresh()
            }
            tableView.es.addMinutesPullToRefresh(animator: header) { [weak self] in
                self?.savePlayInfo()
                self?.topLoadRefresh()
            }
        }
    }

    func removeRefreshHeader() {
        if let tableView = tableView {
            if tableView.header == nil { return }
            
            tableView.es.removeRefreshHeader()
        }
    }

    func topLoadRefresh() {
        viewModel.pullToRefreshAllData { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.delegate?.translatePullRefreshSuccess()
            case .failure(let error):
                break
            }
        }
    }

    func stopRefresh() {
        if let tableView = tableView {
            tableView.es.stopPullToRefresh()
        }
    }
}
