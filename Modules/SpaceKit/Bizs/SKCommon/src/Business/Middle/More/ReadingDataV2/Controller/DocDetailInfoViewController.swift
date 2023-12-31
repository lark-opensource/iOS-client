//
//  DocDetailInfoViewController.swift
//  SKCommon
//
//  Created by CJ on 2021/9/26.
//
// swiftlint:disable file_length

import Foundation
import SKResource
import EENavigator
import RxSwift
import RxCocoa
import SKUIKit
import SnapKit
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import UIKit
import LarkUIKit
import SKFoundation
import SpaceInterface

public protocol ReadingDetailControllerType: UIViewController {
    func refresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, success: Bool)
}


public final class DocDetailInfoViewController: SKWidgetViewController, UITableViewDelegate, UITableViewDataSource {
    
    enum Event {
        case refresh
        case retry
    }
    
    private var types: [DocDetainInfoSectionType] = []

    private var isPopover: Bool {
        return modalPresentationStyle == .popover
    }
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    var headerView = DocDetailInfoHeaderView()
    
    private var loadingView = UDLoading.loadingImageView()
    
    private var detailInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = .top
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var dismissView: UIControl = {
        let view = UIControl()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy private var loadingMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    public var needRefresh: ((DocsReadingInfoViewModel.ReloadType) -> Void)?
    public var openDocumentActivity: ((String, DocsType) -> Void)?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.register(DocDetailCreationInfoCell.self, forCellReuseIdentifier: DocDetailCreationInfoCell.reuseIdentifier)
        tableView.register(DocDetailBasicInfoCell.self, forCellReuseIdentifier: DocDetailBasicInfoCell.reuseIdentifier)
        tableView.register(DocDetailReadInfoCell.self, forCellReuseIdentifier: DocDetailReadInfoCell.reuseIdentifier)
        tableView.register(DocDetailInfoNormalCell.self, forCellReuseIdentifier: DocDetailInfoNormalCell.reuseIdentifier)
        return tableView
    }()
    
    fileprivate lazy var loadErrorConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_title),
                             description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_desc1),
                             type: .loadingFailure,
                             labelHandler: nil,
                             primaryButtonConfig: (BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_desc2, { [weak self] _ in
                              // 刷新
                               self?.eventRelay.accept(.retry)
                            }),
                             secondaryButtonConfig: nil)
    }()
    
    lazy var emptyView = UDEmptyView(config: loadErrorConfig).construct { it in
        it.backgroundColor = UDColor.bgBody
        it.useCenterConstraints = true
        it.isHidden = true
    }

    private var docsInfo: DocsInfo
    
    private var model: DocsReadingInfoModel?
    
    private var viewModel: DocsReadingInfoViewModel
    
    var triggerRelay = BehaviorRelay<DocsReadingData?>(value: nil)
    
    var eventRelay = PublishRelay<DocDetailInfoViewController.Event>()
    
    var disposeBag = DisposeBag()
    
    var hostSize: CGSize = .zero
    
    var hasAppeared = false
    
    public init(docsInfo: DocsInfo, hostView: UIView, permission: UserPermissionAbility?, permissionService: UserPermissionService?) {
        self.docsInfo = docsInfo
        self.hostSize = hostView.bounds.size
        self.viewModel = DocsReadingInfoViewModel(docsInfo: docsInfo, permission: permission, permissionService: permissionService)
        let bottom = hostView.window?.safeAreaInsets.bottom ?? 0
        let height = self.viewModel.contentHeight + bottom
        super.init(contentHeight: self.viewModel.contentHeight + bottom)
        bindViewModel()
        if SKDisplay.pad, hostView.isMyWindowRegularSize() {
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .overFullScreen
        }
        setupView()
        layoutInfoView()
        loadingView(isShow: true)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let height = min(contentHeight, view.frame.height)
        if height != contentHeight {
            resetHeightIgnoreBottomSafeArea(height)
        }
        setupHeader()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DocsDetailInfoReport.detailView.report(docsInfo: docsInfo)
        hasAppeared = true
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let bgColor = UIColor.clear
        contentView.backgroundColor = bgColor
        backgroundView.backgroundColor = bgColor
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if modalPresentationStyle == .formSheet {
            // 重置iPad的约束
            backgroundView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            view.frame = CGRect(origin: view.frame.origin,
                                     size: CGSize(width: view.frame.size.width, height: self.contentHeight))
            // 要指定宽度，否则不生效
            preferredContentSize = CGSize(width: 540,
                                                       height: self.contentHeight)
            navigationController?.preferredContentSize = preferredContentSize
        }
        layoutInfoView()
    }
    
    func updateContentHeight() {
        let bottom = self.view.window?.safeAreaInsets.bottom ?? 0
        let height: CGFloat = self.viewModel.contentHeight + bottom
        let detailInfoHeight = min(height, view.frame.height)
        if detailInfoHeight != contentHeight {
            resetHeightIgnoreBottomSafeArea(detailInfoHeight)
            if modalPresentationStyle == .formSheet {
                preferredContentSize = CGSize(width: 540,
                                                   height: detailInfoHeight)
                navigationController?.preferredContentSize = preferredContentSize
                view.layoutIfNeeded()
            }
        }
    }
    
    func bindViewModel() {
        let output = viewModel.transform(input: .init(trigger: triggerRelay, event: eventRelay))
        
        output.data
              .observeOn(MainScheduler.instance)
              .subscribe(onNext: { [weak self] (data) in
                  guard let self = self else { return }
                  self.types = data
                  self.updateContentHeight()
                  self.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        output.reload
              .subscribe(onNext: { [weak self] (type) in
               guard let self = self else { return }
               self.needRefresh?(type)
        }).disposed(by: disposeBag)
        
        output.status.bind(to: rx.status).disposed(by: disposeBag)
    }
    
    @objc
    private func didClickMaskView() {
        animatedView(isShow: false, animate: true, compltetion: nil)
    }

    private func setupView() {
        dismissView.addTarget(self, action: #selector(didClickMaskView), for: .touchUpInside)
        view.backgroundColor = .clear
        tableView.contentInsetAdjustmentBehavior = .never
        contentView.backgroundColor = UDColor.bgBody
        headerView.backgroundColor = UDColor.bgBody
        contentView.addSubview(dismissView)
        dismissView.addTarget(self, action: #selector(didClickMaskView), for: .touchUpInside)
        dismissView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(detailInfoView)
        detailInfoView.addSubview(headerView)
        detailInfoView.addSubview(tableView)
        detailInfoView.addSubview(emptyView)
        
        detailInfoView.addSubview(loadingMaskView)
        detailInfoView.addSubview(loadingView)
        
        loadingMaskView.isHidden = true
        loadingView.isHidden = true
        
        headerView.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.top.leading.trailing.equalToSuperview()
        }
    
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom)
        }
        
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        loadingMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func layoutInfoView() {
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            detailInfoView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().inset(11)
                make.width.equalToSuperview().multipliedBy(0.7)
                make.bottom.equalToSuperview()
            }
        } else {
            detailInfoView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    @objc
    private func didChangeStatusBarOrientation(_ notice: Notification) {
        updateContentHeight()
        layoutInfoView()
        detailInfoView.layoutIfNeeded()
        tableView.reloadData()
    }
    
    private func setupHeader() {
        headerView.buttonAction = { [weak self] event in
            guard let self = self else { return }
            if event == .close {
                // 针对 iPad 优化一下 dismiss 效果
                if self.isMyWindowRegularSizeInPad {
                    self.dismiss(animated: true)
                } else {
                    self.animatedView(isShow: false, animate: true, compltetion: nil)
                }
            } else {
                self.eventRelay.accept(.refresh)
            }
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if hasAppeared && (supportedInterfaceOrientations == .portrait || SKDisplay.pad) {
            self.dismiss(animated: true)
        }
    }
    
    
    private func pushToReadRecordListViewController() {
        let vc = ReadRecordListViewController(docsInfo: docsInfo)
        vc.modalPresentationStyle = .overFullScreen
        vc.supportOrientations = self.supportedInterfaceOrientations
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func pushToReadPrivacySettingViewController() {
        if UserScopeNoChangeFG.PLF.avatarSwitchEnable {
            let vc = PrivacySettingViewController(from: .infoView, docsInfo: docsInfo)
            vc.modalPresentationStyle = .overFullScreen
            vc.supportOrientations = self.supportedInterfaceOrientations
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = ReadPrivacySettingViewController(from: .infoView, docsInfo: docsInfo)
            vc.modalPresentationStyle = .overFullScreen
            vc.supportOrientations = self.supportedInterfaceOrientations
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func openDocumentActivityViewController() {
        var token = docsInfo.objToken
        var type = docsInfo.type
        if let wikiInfo = docsInfo.wikiInfo {
            token = wikiInfo.objToken
            type = .wiki
        }

        // 针对 iPad 优化一下 dismiss 效果
        if isMyWindowRegularSizeInPad {
            dismiss(animated: true) {
                self.openDocumentActivity?(token, type)
            }
        } else {
            animatedView(isShow: false, animate: true) {
                self.openDocumentActivity?(token, type)
            }
        }
    }

    @objc
    private func cancel() {
        dismiss(animated: true)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.deselectRow(at: indexPath, animated: false)
        let type = types[indexPath.row]
        switch type {
        case let .createInfo(info):
            let cell = tableView.dequeueReusableCell(withIdentifier: DocDetailCreationInfoCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocDetailCreationInfoCell {
                cell.onAvatarClick = { [weak self] in
                    guard let self = self else { return }
                    let uid = self.viewModel.docOwnerUserId ?? ""
                    LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                        guard let self = self else { return }
                        HostAppBridge.shared.call(ShowUserProfileService(userId: uid, fileName: "", fromVC: self))
                    }
                }
                cell.setAvatarUrl(self.viewModel.docOwnerAvatarUrl)
                cell.update(info: info)
                return cell
            }
        case let .wordInfo(info), let .fileInfo(info):
            let cell = tableView.dequeueReusableCell(withIdentifier: DocDetailBasicInfoCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocDetailBasicInfoCell {
                cell.update(info: info)
                return cell
            }
        case .readInfo(let models):
            let cell = tableView.dequeueReusableCell(withIdentifier: DocDetailReadInfoCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocDetailReadInfoCell {
                cell.update(data: models, contentWidth: detailInfoView.bounds.width)
                debugPrint("detailInfoView.width: \(detailInfoView.bounds.width)")
                return cell
            }
        case .readRecordInfo(let icon):
            let cell = tableView.dequeueReusableCell(withIdentifier: DocDetailInfoNormalCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocDetailInfoNormalCell {
                cell.title = BundleI18n.SKResource.LarkCCM_Docs_ViewHistory_Menu_Mob
                cell.image = icon.ud.withTintColor(UDColor.iconN1)
                let isLast = indexPath.row == types.count - 1
                cell.updateSeperator(isShow: !isLast)
                return cell
            }
        case .privacySetting(let icon):
            let cell = tableView.dequeueReusableCell(withIdentifier: DocDetailInfoNormalCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocDetailInfoNormalCell {
                cell.title = BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_tab
                cell.image = icon.ud.withTintColor(UDColor.iconN1)
                let isLast = indexPath.row == types.count - 1
                cell.updateSeperator(isShow: !isLast)
                return cell
            }
        case .documentActivity(let icon):
            let cell = tableView.dequeueReusableCell(withIdentifier: DocDetailInfoNormalCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocDetailInfoNormalCell {
                cell.title = BundleI18n.SKResource.CreationMobile_Activity_Tab
                cell.image = icon.ud.withTintColor(UDColor.iconN1)
                let isLast = indexPath.row == types.count - 1
                cell.updateSeperator(isShow: !isLast)
                return cell
            }
        }
        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < types.count {
            return types[indexPath.row].height
        }
         return 0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < types.count {
            let type = types[indexPath.row]
            switch type {
            case .readRecordInfo:
                DocsDetailInfoReport.tabClick(action: 0).report(docsInfo: docsInfo)
                self.pushToReadRecordListViewController()
            case .privacySetting:
                DocsDetailInfoReport.tabClick(action: 1).report(docsInfo: docsInfo)
                self.pushToReadPrivacySettingViewController()
            case .documentActivity:
                // DocsDetailInfoReport 内部写死了 index 的判断，这里只能新增一个
                DocsDetailInfoReport.tabClick(action: 2).report(docsInfo: docsInfo)
                openDocumentActivityViewController()
            default:
                break
            }
        }
    }
}

extension DocDetailInfoViewController {
  
    func loadingView(isShow: Bool) {
        loadingView.isHidden = !isShow
        loadingMaskView.isHidden = !isShow
    }
}

// MARK: - ReadingDetailControllerType

extension DocDetailInfoViewController: ReadingDetailControllerType {
    public func refresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, success: Bool) {
        self.triggerRelay.accept(info)
    }
    
    public func refreshCache(_ data: [DocsReadingData]) {
        data.forEach {
            self.triggerRelay.accept($0)
        }
    }
}


extension Reactive where Base: DocDetailInfoViewController {
    var status: Binder<DocsReadingInfoViewModel.Status> {
        return Binder(base) { (target, status) in
            switch status {
            case .loading:
                target.loadingView(isShow: true)
                target.emptyView.isHidden = true
                target.headerView.reloadButton.isHidden = true
            case .none:
                target.loadingView(isShow: false)
                target.emptyView.isHidden = true
                target.headerView.reloadButton.isHidden = true
            case .fetchFail:
                target.loadingView(isShow: false)
                target.emptyView.isHidden = false
                target.headerView.reloadButton.isHidden = true
            case .needReload:
                target.headerView.reloadButton.isHidden = false
                target.loadingView(isShow: false)
                target.emptyView.isHidden = true
            }
        }
    }
    
}

extension DocDetailInfoViewController {
    
    /// 支持新版阅读详情的类型
    public static var supportDocTypes: [DocsType] {
        return [.doc, .docX, .sheet, .bitable, .mindnote, .file, .slides]
    }
    
    /// 支持从前端获取字数的类型
    public static var supportWordCountTypes: [DocsType] {
        return [.doc, .docX]
    }
    
    /// 支持从前端获取字符数的类型
    public static var supportCharCountTypes: [DocsType] {
        return [.doc, .docX]
    }
}
