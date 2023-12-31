//
//  SearchShareDocumentsVMProtocol.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/6/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewNetwork

protocol SearchShareDocumentsVMProtocol {
    var accountInfo: AccountInfo { get }

    var scenario: ShareContentScenario { get }

    /// 埋点使用；
    /// true：用户输入内容搜索；false：默认空字符串搜索
    var isSearch: Bool { get }

    var searchText: AnyObserver<String?> { get }

    var didSelectedModel: PublishSubject<SearchDocumentResultCellModel> { get set }

    var loadNext: AnyObserver<Void> { get }

    var resultData: Observable<[SearchDocumentResultCellModel]> { get }

    var resultStatus: Observable<SearchContainerView.Status> { get }

    var meetingRelatedDocument: Observable<[SearchDocumentResultCellModel]> { get }

    var dismissPublishSubject: PublishSubject<Void> { get set }

    var showLoadingObservable: Observable<Bool> { get set }
}

protocol SearchShareDocumentsViewControllerProtocol: UIViewController {
    var searchBar: SearchBarView { get }
    var searchView: SearchContainerView { get }
    var searchViewCellIdentifier: String { get }
    var searchResultMaskView: UIView { get }
    var scenario: ShareContentScenario { get }
    var disposeBag: DisposeBag { get }
}

extension SearchShareDocumentsVMProtocol {
    func bindToViewController(_ vc: SearchShareDocumentsViewControllerProtocol) {
        vc.searchBar.resultTextObservable
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak vc] text in
                guard let vc = vc else { return }
                self.searchText.onNext(text)
                if text.isEmpty && vc.searchBar.textField.isFirstResponder {
                    if vc.scenario == .inMeet {
                        InMeetSettingsMagicShareTracks.trackTapSearchBar()
                    }
                    vc.searchResultMaskView.isHidden = false
                } else {
                    vc.searchResultMaskView.isHidden = true
                }
            })
            .disposed(by: vc.disposeBag)
        vc.searchBar.textField.rx.text
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak vc] (text: String?) in
                vc?.searchView.tableView.setContentOffset(.zero, animated: false)
                vc?.searchView.hasEmptyText = text?.isEmpty ?? true
            })
            .disposed(by: vc.disposeBag)
        vc.searchView.tableView.rx.modelSelected(SearchDocumentResultCellModel.self)
            .do(onNext: { InMeetFollowViewModel.logger.debug("selected doc info: \($0.debugInfo)") })
            .bind(to: self.didSelectedModel)
            .disposed(by: vc.disposeBag)
        vc.searchView.tableView.rx.itemSelected
            .subscribe(onNext: { [weak vc] indexPath in
                vc?.searchView.tableView.deselectRow(at: indexPath, animated: true)
            }).disposed(by: vc.disposeBag)
        vc.searchView.loadMoreObservable
            .bind(to: self.loadNext)
            .disposed(by: vc.disposeBag)

        let account = self.accountInfo
        self.resultData
            .observeOn(MainScheduler.instance)
            .bind(to: vc.searchView.tableView.rx.items(cellIdentifier: vc.searchViewCellIdentifier)) { (_, docs, cell) in
                let itemCell = cell as? SearchDocumentResultCell
                itemCell?.update(docs, account: account)
            }.disposed(by: vc.disposeBag)
        self.resultStatus
            .observeOn(MainScheduler.instance)
            .bind(to: vc.searchView.statusObserver)
            .disposed(by: vc.disposeBag)

        self.dismissPublishSubject.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak vc] _ in
                vc?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: vc.disposeBag)

        // 进入页面手动触发一次
        self.searchText.onNext("")
    }
}

extension SearchDocumentResultCellModel {
    var debugInfo: String {
        """
        status: \(self.status),
        url.hash: \(self.url.vc.removeParams().hash),
        isSharing: \(self.isSharing)
        """
    }
}
