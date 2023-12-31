//
//  FeedTeamViewController+SetOffset.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import UIKit
import Foundation
import RxSwift
import EENavigator
import LarkSplitViewController
import LarkUIKit
import RustPB
import LarkMessengerInterface
import AnimatedTabBar

extension FeedTeamViewController {
    func setContentOffset(_ offset: CGPoint, animated: Bool = false) {
        if animated == true {
            // setContent时，挂起队列
            viewModel.frozenDataQueue(.setOffset)
            DispatchQueue.main.asyncAfter(deadline: .now() + TeamOffSetCons.delaySecond) {
                // 防止【scrollViewDidEndScrollingAnimation】没有回调，导致没有释放队列
                self.viewModel.resumeDataQueue(.setOffset)
            }
        }
        tableView.setContentOffset(offset, animated: animated)
    }

    func observSelectFeedTab() {
        viewModel.dependency.selectFeedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                guard let self = self else { return }
                self.handleInfo(info: info)
            }).disposed(by: disposeBag)
    }

    func handleInfo(info: FeedSelection?) {
        guard let info = info else { return }
        guard info.filterTabType == .team else { return }
        DispatchQueue.main.async {
            self.delegate?.pullupMainScrollView()
            guard let indexpath = self.viewModel.findSelectedIndexPath(), self.viewModel.teamUIModel.getChat(indexPath: indexpath) != nil else {
                self.scrollToBottom()
                return
            }
            self.scrollTo(indexpath)
        }
    }

    func scrollTo(_ indexPath: IndexPath) {
        let sections = tableView.numberOfSections
        guard indexPath.section < sections, indexPath.row < tableView.numberOfRows(inSection: sections - 1)  else {
            scrollToBottom()
            return
        }
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    func scrollToBottom() {
        let bottom = self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableView.contentInset.bottom
        if bottom > 0 {
            self.tableView.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
        }
    }

    enum TeamOffSetCons {
        static let delaySecond: CGFloat = 0.25
    }
}
