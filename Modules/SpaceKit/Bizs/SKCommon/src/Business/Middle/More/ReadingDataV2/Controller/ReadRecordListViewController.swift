//
//  ReadRecordListViewController.swift
//  SKCommon
//
//  Created by CJ on 2021/9/25.
//

import SKFoundation
import SKUIKit
import SKResource
import RxSwift
import RxCocoa
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignEmpty


public final class ReadRecordListViewController: BaseViewController, UITableViewDataSource {
    
    enum Event {
        case errorReload
        case viewDidAppear
    }
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    var viewModel: ReadRecordViewModel
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UDColor.bgBody
        tableView.tableHeaderView = ReadRecordListTitleHeaderView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: self.view.frame.width, height: .leastNormalMagnitude))
        tableView.register(ReadRecordCell.self, forCellReuseIdentifier: ReadRecordCell.reuseIdentifier)
        return tableView
    }()

    private lazy var readRecordHiddenInfoView: ReadRecordHiddenInfoView = {
        let view = ReadRecordHiddenInfoView()
        return view
    }()

    private var disposeBag = DisposeBag()
    
    var recordInfo: ReadRecordInfo?
    
    // MARK: - empty
    
    fileprivate lazy var loadErrorConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_title),
                             description: .init(descriptionText: " "),
                             type: .loadingFailure,
                             labelHandler: nil,
                             primaryButtonConfig: (BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_desc2, { [weak self] _ in
                              // 刷新
                              self?.viewModel.request()
                            }),
                             secondaryButtonConfig: nil)
    }()
    
    fileprivate lazy var permissionConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_Visits_NoPermission_title),
                             description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Stats_Visits_PrivacyOff_desc),
                             type: .noAccess,
                             labelHandler: nil,
                             primaryButtonConfig: (BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_tab, { [weak self] _ in
                                      guard let self = self else { return }
                                      self.pushToReadPrivacySettingViewController()
                             }),
                             secondaryButtonConfig: nil)
    }()
    
    fileprivate lazy var notOwnerConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_Visits_NoPermission_title),
                             description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_Docs_ViewHistory_PermChanged_Description_mob),
                             type: .noAccess,
                             labelHandler: nil,
                             primaryButtonConfig: nil,
                             secondaryButtonConfig: nil)
    }()
    
    fileprivate lazy var adminConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_Visits_NoPermissionToUse_title),
                             description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Stats_Visits_NoPermissionToUse_desc),
                             type: .noAccess,
                             labelHandler: nil,
                             primaryButtonConfig: nil,
                             secondaryButtonConfig: nil)
    }()
    
    fileprivate lazy var emptyConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_Visits_empty),
                             description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Stats_Visits_StartFromDate),
                             type: .noContent,
                             labelHandler: nil,
                             primaryButtonConfig: nil,
                             secondaryButtonConfig: nil)
    }()
    
    fileprivate lazy var emptyView = UDEmptyView(config: emptyConfig).construct { it in
        it.backgroundColor = UDColor.bgBody
        it.useCenterConstraints = true
        it.isHidden = true
    }
    
    var docsInfo: DocsInfo
    
    var eventSubject = PublishRelay<Event>()
    
    public init(docsInfo: DocsInfo) {
        self.docsInfo = docsInfo
        viewModel = ReadRecordViewModel(token: docsInfo.objToken, type: docsInfo.type.rawValue)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eventSubject.accept(.viewDidAppear)
    }
    
    public override func backBarButtonItemAction() {
        super.backBarButtonItemAction()
        DocsDetailInfoReport.recordClick(action: 0).report(docsInfo: self.docsInfo)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    private func setupView() {
        title = BundleI18n.SKResource.LarkCCM_Docs_ViewHistory_Menu_Mob
        navigationBar.layoutAttributes.showsBottomSeparator = true
        view.addSubview(tableView)
        view.addSubview(readRecordHiddenInfoView)
        view.addSubview(emptyView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(readRecordHiddenInfoView.snp.top)
        }

        emptyView.snp.makeConstraints { make in
            make.top.equalToSuperview()
           // make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        readRecordHiddenInfoView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        tableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let self = self else { return }
            if self.viewModel.readRecordInfo.nextPageToken.isEmpty {
                self.tableView.es.noticeNoMoreData()
            } else {
                self.viewModel.loadMore()
                DocsDetailInfoReport.recordClick(action: 1).report(docsInfo: self.docsInfo)
            }
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.readRecordInfo.readUsers.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadRecordCell.reuseIdentifier, for: indexPath)
        let readUsers = viewModel.readRecordInfo.readUsers
        if let cell = cell as? ReadRecordCell,
           indexPath.row < readUsers.count {
            let userInfoModel = readUsers[indexPath.row]
            cell.setUserInfoModel(userInfoModel)
            let isLast = (indexPath.row == viewModel.readRecordInfo.readUsers.count - 1)
            cell.updateSeperator(isShow: !isLast)
            cell.tapProfileHandler = { [weak self] model in
                self?.handleProfileTapGesture(model)
            }
        }
        return cell
    }

    func handleProfileTapGesture(_ model: ReadRecordUserInfoModel) {
        if model.canShowProfile,
           !model.userID.isEmpty {
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard let self = self else { return }
                HostAppBridge.shared.call(ShowUserProfileService(userId: model.userID, fileName: model.name, fromVC: self))
            }
        }
    }
    
    private func pushToReadPrivacySettingViewController() {
        DocsDetailInfoReport.recordClick(action: 2).report(docsInfo: self.docsInfo)
        if UserScopeNoChangeFG.PLF.avatarSwitchEnable {
            let vc = PrivacySettingViewController(from: .recordListView, docsInfo: docsInfo)
            vc.modalPresentationStyle = .overFullScreen
            vc.supportOrientations = self.supportedInterfaceOrientations
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = ReadPrivacySettingViewController(from: .recordListView, docsInfo: docsInfo)
            vc.modalPresentationStyle = .overFullScreen
            vc.supportOrientations = self.supportedInterfaceOrientations
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func updateFooterView(canLoadMore: Bool) {
        if canLoadMore {
            tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: view.frame.width, height: .leastNormalMagnitude))
        } else {
            tableView.tableFooterView = DocDetailInfoFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 70))
        }
    }
    
    fileprivate func endLoadingMore() {
        tableView.es.stopLoadingMore()
    }
}


extension ReadRecordListViewController {
    
    func bind() {
        self.viewModel.state.loading
            .skip(1)
            .bind(to: rx.showLoading)
            .disposed(by: disposeBag)
        
        self.viewModel.state.error
            .skip(1)
            .bind(to: rx.showError)
            .disposed(by: disposeBag)
        
        self.viewModel.state.empty
            .skip(1)
            .bind(to: rx.showEmptyView)
            .disposed(by: disposeBag)
        
        self.viewModel.state.toast
            .bind(to: rx.showToast)
            .disposed(by: disposeBag)
        
        self.viewModel.state.data
            .skip(1)
            .subscribe(onNext: { [weak self] (recordInfo, list) in
            guard let self = self else { return }
            self.readRecordHiddenInfoView.setReadRecordUserCount(recordInfo.uv, recordInfo.hiddenUv)
            if list.count >= ReadRecordViewModel.pageSize {
                self.tableView.es.stopLoadingMore()
            } else {
                self.tableView.es.noticeNoMoreData()
                self.updateFooterView(canLoadMore: false)
            }
            if self.recordInfo == nil {
                DocsDetailInfoReport.recordView(status: .normal).report(docsInfo: self.docsInfo)
            }
            self.recordInfo = recordInfo
            if recordInfo.readUsers.count == 0 {
                self.tableView.isHidden = true
                self.readRecordHiddenInfoView.isHidden = true
            } else {
                self.tableView.isHidden = false
                self.readRecordHiddenInfoView.isHidden = false
            }
            self.tableView.reloadData()
        }).disposed(by: disposeBag)

        self.viewModel.acceptInput(event: eventSubject)
        self.viewModel.request()
    }
}

// MARK: - Binder

extension Reactive where Base: ReadRecordListViewController {
    var showEmptyView: Binder<Bool> {
        return Binder(base) { (target, show) in
            if show {
                DocsDetailInfoReport.recordView(status: .normal).report(docsInfo: target.docsInfo)
                target.emptyView.update(config: target.emptyConfig)
                target.emptyView.isHidden = false
            } else {
                target.emptyView.isHidden = true
            }
        }
    }
    
    var showLoading: Binder<Bool> {
        return Binder(base) { (target, show) in
            target.emptyView.isHidden = true
            if show {
                target.showLoading(backgroundAlpha: 1)
            } else {
                target.hideLoading()
            }
        }
    }
    
    var showError: Binder<ReadRecordViewModel.ReadRecordError> {
        return Binder(base) { (target, error) in
            target.emptyView.isHidden = false
            switch error {
            case .loadError(let hasDataNow):
                if hasDataNow {
                    target.emptyView.isHidden = true
                    target.endLoadingMore()
                } else {
                    target.emptyView.update(config: target.loadErrorConfig)
                }
            case .permission:
                DocsDetailInfoReport.recordView(status: .noOwner).report(docsInfo: target.docsInfo)
                target.emptyView.update(config: target.permissionConfig)
            case .adminTunOff:
                DocsDetailInfoReport.recordView(status: .noAdmin).report(docsInfo: target.docsInfo)
                target.emptyView.update(config: target.adminConfig)
            case .notOwner:
                DocsDetailInfoReport.recordView(status: .noOwner).report(docsInfo: target.docsInfo)
                target.emptyView.update(config: target.notOwnerConfig)
            case .none:
                break
            }
        }
    }
    
    var showToast: Binder<ReadRecordViewModel.ToastStatus?> {
        return Binder(base) { (target, status) in
            guard let st = status else { return }
            switch st {
            case .success(let msg):
                UDToast.showSuccess(with: msg, on: target.view.window ?? target.view)
            case .error(let msg):
                UDToast.showFailure(with: msg, on: target.view.window ?? target.view)
            }
        }
    }
}
