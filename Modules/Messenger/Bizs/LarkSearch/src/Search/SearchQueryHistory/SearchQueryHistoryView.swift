//
//  SearchQueryHistoryView.swift
//  LarkSearch
//
//  Created by SuPeng on 5/6/19.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import LarkAlertController
import EENavigator
import LarkSDKInterface
import LarkAppConfig
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkFeatureGating

protocol SearchQueryHistoryViewDelegate: AnyObject {
    func topBar(_ topBar: SearchQueryHistoryView, didSelect type: SearchDesignatedType)
    func topBar(_ topBar: SearchQueryHistoryView, didSelect historyInfo: SearchHistoryInfo)
    func topBarDidClickMore(_ topBar: SearchQueryHistoryView)
    func presentAlert(alert: UIViewController)
}

final class SearchQueryHistoryView: UIView {
    weak var delegate: SearchQueryHistoryViewDelegate?

    private let scrollView = UIScrollView()
    private let searchConfig: AppConfig.SearchConfig
    let historyStore: SearchQueryHistoryStore
    private let topBar: SearchQueryHistoryTopBar
    private let bottomView = SearchQueryBottomView()
    private let containerView = UIView()

    private let disposeBag = DisposeBag()

    init(searchConfig: AppConfig.SearchConfig,
         searchAPI: SearchAPI,
         store: SearchQueryHistoryStore? = nil,
         oncallEnable: Bool,
         wikiEnable: Bool,
         chatEnable: Bool,
         externalEnable: Bool,
         calendarEnable: Bool,
         threadEnale: Bool,
         topicEnable: Bool,
         appEnable: Bool,
         topBarEnable: Bool) {
        self.searchConfig = searchConfig
        self.historyStore = store ?? SearchQueryHistoryStore(searchAPI: searchAPI)

        var showHelpDesk = oncallEnable
        let showApp = appEnable
        Feature.on(.searchFilter).apply(on: {}, off: {
            showHelpDesk = false
        })

        self.topBar = SearchQueryHistoryTopBar(showHelpDesk: showHelpDesk,
                                               showApp: showApp,
                                               showWiki: wikiEnable,
                                               showChat: chatEnable,
                                               showCalendar: calendarEnable,
                                               showThread: threadEnale,
                                               showTopic: topicEnable,
                                               showMoreButton: !searchConfig.externalSearches.isEmpty && externalEnable)
        self.topBar.isHidden = !topBarEnable
        super.init(frame: .zero)

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        scrollView.backgroundColor = UIColor.ud.bgBodyOverlay
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.width.equalTo(snp.width)
            make.height.equalTo(snp.height)
            make.edges.equalToSuperview()
        }

        topBar.delegate = self
        containerView.addSubview(topBar)
        topBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }

        bottomView.delegate = self
        containerView.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topBar.snp.bottom).offset(10)
        }

        historyStore.infosVariable
            .subscribe(onNext: { [weak self] (infos) in
                guard let self = self else { return }
                if infos.isEmpty {
                    self.bottomView.isHidden = true
                    self.backgroundColor = UIColor.ud.bgBody
                } else {
                    self.bottomView.isHidden = false
                    self.bottomView.set(historyInfos: Array(infos.prefix(10)))
                    self.backgroundColor = UIColor.ud.bgBase
                }
            })
            .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension SearchQueryHistoryView: SearchQueryHistoryTopBarDelegate {
    func topBar(_ topBar: SearchQueryHistoryTopBar, didSelect type: SearchDesignatedType) {
        delegate?.topBar(self, didSelect: type)
    }

    func topBarDidSelectMore(_ topBar: SearchQueryHistoryTopBar) {
        delegate?.topBarDidClickMore(self)
    }
}

extension SearchQueryHistoryView: SearchQueryBottomViewDelegate {
    func bottomViewDidClickClearHistory(_ bottomView: SearchQueryBottomView) {
        let alertController = LarkAlertController()
        alertController.setContent(text: BundleI18n.LarkSearch.Lark_Search_ClearAllHistory)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkSearch.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
            self?.historyStore.deleteAllInfos(on: self?.window)
        })
        delegate?.presentAlert(alert: alertController)
    }

    func bottomView(_ bottomView: SearchQueryBottomView, didSelect historyInfo: SearchHistoryInfo) {
        delegate?.topBar(self, didSelect: historyInfo)
    }
}
