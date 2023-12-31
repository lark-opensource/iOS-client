//
//  OnCallViewControllerrrr.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/27.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import EENavigator
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import UniverseDesignEmpty
import LarkSetting

final class OnCallViewController: BaseUIViewController, UITableViewDelegate, UIScrollViewDelegate, UITableViewDataSource {
    static let logger = Logger.log(OnCallViewController.self, category: "Module.OnCallViewController")

    private var viewModel: OnCallViewModel
    private let router: OnCallViewControllerRouter

    private var tableView: UITableView = .init(frame: .zero)
    private let reuseIdentifier = "\(UITableViewCell.self)"
    private let disposeBag = DisposeBag()

    private var onCallTagListView: OnCallTagListView!   // 已经废弃的功能，后端不会返回数据，不会被显示
    private var searchView: SearchUITextField?
    private var emptyDataView: UDEmptyView!
    private var headerView: UIView = .init()
    // 服务台页面的常驻提示下线banner

    private var isFirstLoading: Bool = true

    private var oncallDataSource: [Oncall] = []
    private var tags: [OnCallTag] = []

    lazy private var fixSearchEmptyUIEnable: Bool = {
        !viewModel.fgService.staticFeatureGatingValue(with: "openplatform.helpdesk.fix.search.empty.disable")
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: OnCallViewModel, router: OnCallViewControllerRouter, showSearch: Bool) {
        self.router = router
        self.viewModel = viewModel
        if showSearch {
            self.searchView = SearchUITextField()
        }
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_HelpDesk_EmptyHelpDesk)
        emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noGroup))
        emptyDataView.isUserInteractionEnabled = false

        self.view.addSubview(emptyDataView)
        self.title = BundleI18n.LarkContact.Lark_HelpDesk_ContactsHelpDesk
        self.initializeTableView()
        self.bindViewModel()
        self.viewModel.loadOncalls()
        self.viewModel.loadOnCallTag()

        self.view.addSubview(emptyDataView)
        if fixSearchEmptyUIEnable {
        emptyDataView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.tableView)
        }
        emptyDataView.backgroundColor = UIColor.ud.bgBody
        } else {
        emptyDataView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        }
        emptyDataView.isHidden = true
        Tracer.trackEnterContactBots()
        OncallContactsApprecibleTrack.oncallContactsPageFirstRenderCostTrack()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
        super.viewWillDisappear(animated)
    }

    private func initializeTableView() {
        self.setHeaderView()
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.separatorColor = UIColor.clear
        self.tableView.rowHeight = 64
        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)
        if fixSearchEmptyUIEnable {
        self.tableView.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.headerView.snp_bottom)
            make.left.right.bottom.equalToSuperview()
        }
        } else {
        self.tableView.backgroundColor = UIColor.ud.bgBase
        self.tableView.estimatedSectionHeaderHeight = 100
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        }
    }

    private func bindViewModel() {
        // Data Binding
        self.viewModel.onCallObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (oncalls) in
                self?.oncallDataSource = oncalls
                self?.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        // 已经废弃的功能，后端不会返回数据，不会被显示
        self.viewModel.onCallTagObservable
            .observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] (tags) in
                guard let `self` = self else { return }
                self.tags = tags
                if tags.isEmpty {
                    self.showOnCallTagListIfNeeded(false)
                    return
                }
                self.onCallTagListView.setDataSource(dataSource: tags, superWidth: self.view.bounds.width - 16)
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        // Status Binding
        self.viewModel
            .statusObservable
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] (status) in
                guard let `self` = self else { return }
                switch status {
                case .empty:
                    self.emptyDataView.isHidden = false
                case .loading where self.viewModel.isEmpty():
                    if self.isFirstLoading {
                        self.loadingPlaceholderView.isHidden = false
                        self.isFirstLoading = false
                    }
                    self.emptyDataView.isHidden = true
                case .loadedMore:
                    self.tableView.addBottomLoadMoreView { [weak self] in
                        self?.viewModel.loadMore()
                    }
                    self.emptyDataView.isHidden = true
                case .finish:
                    self.tableView.endBottomLoadMore(hasMore: false)
                    self.emptyDataView.isHidden = true
                case .error:
                    if self.viewModel.isEmpty() {
                        self.retryLoadingView.isHidden = false
                        self.retryLoadingView.retryAction = { [unowned self] in
                            self.retryLoadingView.isHidden = true
                            self.viewModel.loadMore()
                        }
                    } else {
                        self.retryLoadingView.isHidden = true
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkOrServiceError, on: self.view)
                        self.tableView.endBottomLoadMore()
                    }
                default: break
                }
                if status != .loading {
                    self.loadingPlaceholderView.isHidden = true
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func setHeaderView() {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody

        let onCallTagListView = OnCallTagListView()
        onCallTagListView.cellDelegate = self

        searchView?.clearButtonMode = .always
        searchView?.isUserInteractionEnabled = true

        if let searchField = searchView {
            headerView.addSubview(searchField)
        }
        headerView.addSubview(onCallTagListView)
        self.headerView = headerView
        self.onCallTagListView = onCallTagListView

        if fixSearchEmptyUIEnable {
        self.view.addSubview(self.headerView)
        self.headerView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        guard searchView != nil else {
            self.headerView.snp.makeConstraints { make in
                make.height.equalTo(0)
            }
            return
        }
        }

        showOnCallTagListIfNeeded(true)

        self.searchView?
            .rx.text.asDriver()
            .skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .drive(onNext: { [weak self] (text) in
                guard let `self` = self else { return }
                self.viewModel.search(by: text ?? "")
                self.hiddenOnCallTagListView(searchViewText: text ?? "")
            }).disposed(by: self.disposeBag)
    }

    private func showOnCallTagListIfNeeded(_ show: Bool) {
        if show {
            onCallTagListView.isHidden = false
            searchView?.snp.remakeConstraints { (make) in
                make.height.equalTo(36)
                make.left.trailing.equalToSuperview().inset(12)
                make.top.equalToSuperview().offset(8)
            }
            onCallTagListView.snp.remakeConstraints { (make) in
                if let searchField = searchView {
                    make.top.equalTo(searchField.snp.bottom).offset(8)
                } else {
                    make.top.equalToSuperview().offset(8)
                }
                make.bottom.lessThanOrEqualToSuperview().inset(8)
                make.trailing.leading.equalToSuperview().inset(12)
            }
        } else {
            onCallTagListView.removeAllSelect()
            onCallTagListView.isHidden = true
            onCallTagListView.snp.removeConstraints()
            searchView?.snp.remakeConstraints { (make) in
                make.height.equalTo(36)
                make.left.trailing.equalToSuperview().inset(12)
                make.bottom.equalToSuperview().inset(8)
                make.top.equalToSuperview().offset(8)
            }
        }
    }

    private func hiddenOnCallTagListView(searchViewText: String) {
        if !searchViewText.isEmpty && !self.onCallTagListView.isHidden {
            showOnCallTagListIfNeeded(false)
        } else if searchViewText.isEmpty, self.onCallTagListView.isHidden, !tags.isEmpty {
            showOnCallTagListIfNeeded(true)
        } else if tags.isEmpty {
            showOnCallTagListIfNeeded(false)
        }

        self.onCallTagListView.selectAllCell()
    }

    private func didSelect(oncall: Oncall) {
        let chatFetchOb: Observable<[String: LarkModel.Chat]>

        var hud: UDToast?
        if let view = navigationController?.view {
            hud = UDToast.showLoading(with: BundleI18n.LarkContact.Lark_Legacy_BaseUiLoading, on: view, disableUserInteraction: true)
        }
        let chatApi = self.viewModel.chatAPI
        if !oncall.chatId.isEmpty { //已有相应会话
            chatFetchOb = chatApi.fetchChats(by: [oncall.chatId], forceRemote: false)
        } else {
            chatFetchOb = self.viewModel.oncallAPI
                .putOncallChat(userId: self.viewModel.userId, oncallId: oncall.id, additionalData: nil)
                .flatMap({ (chatId) -> Observable<[String: LarkModel.Chat]> in
                    OnCallViewController.logger.debug("putOncallChat oncallId:\(oncall.id) 成功")
                    return chatApi.fetchChats(by: [chatId], forceRemote: false)
                })
        }
        chatFetchOb
            .map({ (chatsMap) -> LarkModel.Chat? in
                let chat = chatsMap.first?.value
                OnCallViewController.logger.debug("fetchChat oncallId:\(oncall.id) chatId:\(chat?.id ?? "") 成功")
                return chat
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatModel) in
                guard let `self` = self else { return }
                if let chatModel = chatModel {
                    hud?.remove()
                    self.router.onCallViewController(self, chatModel: chatModel)
                } else if let window = self.view.window {
                    hud?.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkOrServiceError, on: window)
                }
            }, onError: { [weak self] (error) in
                if let window = self?.view.window {
                    hud?.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkOrServiceError, on: window, error: error)
                }

                OnCallViewController.logger.debug("fetchChat oncallId:\(oncall.id) 失败: \(error.localizedDescription)")
            })
            .disposed(by: self.disposeBag)
    }
    // MARK: - UIScrollViewDelegate
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return oncallDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ContactTableViewCell {
            cell.setProps(ContactTableViewCellProps(oncall: oncallDataSource[indexPath.row]))
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let oncall = oncallDataSource[indexPath.row]
        Tracer.trackContactOnCall(id: oncall.id)
        self.didSelect(oncall: oncall)
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if fixSearchEmptyUIEnable {
        let emptyView = UIView()
        emptyView.snp.makeConstraints { (maker) in
            maker.height.equalTo(1)
        }
        return emptyView
        } else {
        if self.searchView == nil {
            let emptyView = UIView()
            emptyView.snp.makeConstraints { (maker) in
                maker.height.equalTo(1)
            }
            return emptyView
        }
        return self.headerView
        }
    }
}

extension OnCallViewController: OnCallTagDelegate {
    func select(tagId: String) {
        self.viewModel.filter(by: tagId)
    }
}
