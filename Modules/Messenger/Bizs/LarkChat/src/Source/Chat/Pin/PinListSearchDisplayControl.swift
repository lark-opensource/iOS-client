//
//  PinListSearchDisplayControl.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/27.
//

import UIKit
import Foundation

class PinListSearchDisplayControl: NSObject, UIScrollViewDelegate {
    private var lastDistance: CGFloat = 0
    private var lastDragOffset: CGFloat?
    let originHeight = PinListViewController.searchViewHeight
    private var offset: CGFloat = 0
    var searchView: UIView?
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastDragOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let lastDragOffset = lastDragOffset {
            self.lastDragOffset = scrollView.contentOffset.y
            let distance = lastDragOffset - scrollView.contentOffset.y
            if scrollView.contentOffset.y + scrollView.contentInset.top <= 0 {
                updateSearchView(distance: distance, forceShow: true)
            } else {
                updateSearchView(distance: distance, forceShow: false)
            }
        } else {
            //点击电池栏回到顶部时lastDragOffset为nil,会走到该分支
            if scrollView.contentOffset.y <= 0 {
                updateSearchView(distance: 0, forceShow: true)
            }
        }
        (scrollView as? PinListTableView)?.scrollViewDidScroll(scrollView)
    }

    func updateSearchView(distance: CGFloat, forceShow: Bool) {
        guard let searchView = self.searchView else {
            return
        }
        if distance * lastDistance < 0 {
            lastDistance = distance
            return
        }
        if forceShow {
            searchView.alpha = 1
            lastDistance = 0
            offset = 0
            searchView.snp.updateConstraints { (make) in
                make.top.equalToSuperview()
            }
            return
        }
        lastDistance = distance
        let rate = abs(distance)
            .truncatingRemainder(dividingBy: PinListViewController.searchViewHeight) / PinListViewController.searchViewHeight
        offset += distance
        if offset > 0 {
            offset = 0
        } else {
            offset = max(-originHeight, offset)
        }
        if distance < 0 {
            searchView.alpha = max(0, searchView.alpha - rate)
        } else if distance > 0 {
            searchView.alpha = min(1, searchView.alpha + rate)
        }
        searchView.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(offset)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            lastDragOffset = nil
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastDragOffset = nil
    }
}
