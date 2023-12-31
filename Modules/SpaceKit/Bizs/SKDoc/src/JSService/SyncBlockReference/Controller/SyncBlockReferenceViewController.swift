//
//  SyncBlockReferenceViewController.swift
//  SKDoc
//
//  Created by lijuyou on 2023/8/2.
//

import SKFoundation
import SKUIKit
import SKInfra
import SKCommon
import SKBrowser
import SKResource
import SpaceInterface
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit

protocol SyncBlockReferenceVCDelegate: AnyObject {
    func syncBlock(vc: SyncBlockReferenceViewController, onMoreClick syncBlockToken: String)
    func syncBlock(vc: SyncBlockReferenceViewController, onClose syncBlockToken: String)
    func syncBlock(vc: SyncBlockReferenceViewController, onItemClick item: SyncBlockReferenceItem)
}


class SyncBlockReferenceViewController: DraggableViewController, UIViewControllerTransitioningDelegate, UITableViewDelegate, UITableViewDataSource {
    struct Layout {
        static let titleViewHeight: CGFloat = 60
        static let RowHeight: CGFloat = 68
        static let FooterHeight: CGFloat = 60
    }
    
    private let loadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    
    lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: ""),
                                                  imageSize: 100,
                                                  type: .noFile,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        emptyView.useCenterConstraints = true
        return emptyView
    }()
    
    var dismissCover = UIView()
    
    lazy var listFooterView: SyncBlockReferenceListFooterView  = {
        let view = SyncBlockReferenceListFooterView(frame: .zero)
        return view
    }()
    
    var tableView = UITableView(frame: .zero, style: .grouped)
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
        return button
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 20, height: 20)), for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        button.addTarget(self, action: #selector(onTapMore), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        it.textColor = UIColor.ud.textTitle
    }
    
    private lazy var headerView = UIView().construct { it in
        it.backgroundColor = UDColor.bgBody
        it.layer.cornerRadius = 8
        it.layer.ud.setShadow(type: .s4Up)
        it.addGestureRecognizer(panGestureRecognizer)
        
        let topLine = UIView()
        topLine.backgroundColor = UDColor.lineBorderCard
        topLine.layer.cornerRadius = 2
        let bottomLine = UIView()
        bottomLine.backgroundColor = UDColor.lineDividerDefault
        
        topLine.docs.addStandardLift()
        it.addSubview(titleLabel)
        it.addSubview(topLine)
        it.addSubview(bottomLine)
        it.addSubview(closeButton)
        it.addSubview(moreButton)
        
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualTo(closeButton.snp.right).offset(16)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-16)
        }
        topLine.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        closeButton.snp.remakeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        moreButton.snp.remakeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(20)
            make.trailing.equalToSuperview().inset(12)
        }
    }
    
    /// 复制权限数据源
    weak var permissionDataSource: CCMCopyPermissionDataSource?
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [.thisView]
        return preventer
    }()
    
    var supportOrientations: UIInterfaceOrientationMask = .portrait
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    private(set) var viewModel: SyncBlockReferenceViewModel
    weak var delegate: SyncBlockReferenceVCDelegate?
    let needFooterView = false //不显示FooterView, 不知后面要不要加回来，先这样控制
    
    required init(docsInfo: DocsInfo, showParam: ShowSyncedBlockReferencesParam) {
        self.viewModel = SyncBlockReferenceViewModel(docsToken: docsInfo.originToken, docsType: docsInfo.originType, config: showParam)
        super.init(nibName: nil, bundle: nil)
        self.viewModel.hostController = self
        self.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
        self.transitioningDelegate = self
        bindViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInit()
        setupLayout()
        updateContentSize()
        
        self.titleLabel.text = self.viewModel.title
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            let orientation = LKDeviceOrientation.getInterfaceOrientation()
            self?.didChangeStatusBarOrientation(to: orientation)
        }
    }
    // MARK: - Private Methods
    private func setupInit() {
        dismissCover.construct({
            $0.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
            $0.layer.shadowOffset = CGSize(width: 5, height: -10)
            $0.layer.shadowOpacity = 2
            $0.layer.shadowRadius = 22
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDismiss)))
        })
        
        contentView = UIView().construct({
            $0.backgroundColor = UIColor.ud.bgBody
            $0.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
            $0.layer.shadowOffset = CGSize(width: 5, height: -10)
            $0.layer.shadowOpacity = 2
            $0.layer.shadowRadius = 22
            $0.layer.cornerRadius = 12
            contentView.layer.maskedCorners = .top
        })
        
        tableView.construct {
            $0.register(SyncBlockReferenceItemCell.self, forCellReuseIdentifier: SyncBlockReferenceItemCell.reuseIdentifier)
            $0.rowHeight = Layout.RowHeight
            $0.delegate = self
            $0.dataSource = self
            $0.backgroundColor = UIColor.ud.bgBody
            $0.separatorStyle = .none
            $0.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        }
        let container: UIView
        if ViewCapturePreventer.isFeatureEnable {
            container = viewCapturePreventer.contentView
            view.addSubview(container)
            container.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            container = view
        }
        
        container.addSubview(dismissCover)
        container.addSubview(contentView)
        contentView.addSubview(tableView)
        contentView.addSubview(headerView)
        contentView.addSubview(loadingView.displayContent)
        
    }
    
    private func setupLayout() {
        
        dismissCover.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(contentViewMaxY)
            make.bottom.equalToSuperview()
        }
        
        headerView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Layout.titleViewHeight)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        addInfinitedScrolling()
        
        loadingView.displayContent.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
        }
    }
    
    private func updateContentSize() {
        if SKDisplay.phone {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                contentView.snp.remakeConstraints { (make) in
                    make.centerX.bottom.equalToSuperview()
                    make.top.equalTo(contentViewMaxY)
                    make.width.equalToSuperview().multipliedBy(0.7)
                }
                contentViewMinY = 11
            } else {
                contentView.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(contentViewMaxY)
                    make.bottom.equalToSuperview()
                }
                contentViewMinY = 64
            }
            updateEmptyViewSize()
        }
    }
    
    func updateEmptyViewSize() {
        guard emptyView.superview != nil else {
            return
        }
        if UIApplication.shared.statusBarOrientation.isLandscape {
            emptyView.snp.remakeConstraints { (make) in
                make.centerX.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
                make.top.equalTo(headerView.snp.bottom)
            }
        } else {
            emptyView.snp.remakeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(headerView.snp.bottom)
            }
        }
    }
    
    private func bindViewModel() {
        viewModel.bindAction = {[weak self] action in
            guard let `self` = self else { return }
            switch action {
            case .loading:
                self.startLoading()
            case .reloadData:
                self.tableView.isHidden = false
                self.tableView.reloadData()
                self.stopLoading()
            case .loadEmpty:
                self.stopLoading()
                self.handleError(empty: true)
            case .loadError:
                self.stopLoading()
                self.handleError(empty: false)
            case .stopLoading:
                self.stopRefresh()
                self.stopLoading()
            case .noMoreData:
                self.removeInfinitedScrolling()
                self.tableView.es.noticeNoMoreData()
            case .resetNoMoreData:
                self.addInfinitedScrolling()
                self.tableView.es.resetNoMoreData()
            case .removeFooter:
                self.tableView.es.removeRefreshFooter()
            }
        }
        viewModel.loadData()
    }
    
    func addInfinitedScrolling() {
        if tableView.footer != nil { return }
        tableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let `self` = self else { return }
            if self.viewModel.isLoadingData {
                self.tableView.es.stopLoadingMore()
                return
            }
            self.viewModel.loadData(loadMore: true)
        }
    }

    func removeInfinitedScrolling() {
        tableView.es.removeRefreshFooter()
    }
    
    func stopRefresh() {
        self.tableView.es.stopLoadingMore()
    }
    
    private func startLoading() {
        loadingView.startAnimation()
        self.emptyView.removeFromSuperview()
    }
    
    private func stopLoading() {
        loadingView.stopAnimation()
    }
    
    private func handleError(empty: Bool = false) {
        var config = UDEmptyConfig(title: .init(titleText: ""),
                                   description: .init(descriptionText: ""),
                                   type: .noNotice,
                                   labelHandler: nil,
                                   primaryButtonConfig: nil,
                                   secondaryButtonConfig: nil)
        if self.emptyView.superview == nil {
            self.view.addSubview(self.emptyView)
            self.updateEmptyViewSize()
        }
        
        if empty {
            if DocsNetStateMonitor.shared.isReachable {
                config.description = nil
                config.type = UDEmptyType.noData
            } else {
                config.description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.Doc_Doc_NetException)
                config.type = UDEmptyType.noWifi
            }
        } else {
            config.description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_title)
            config.type = UDEmptyType.loadingFailure
        }
        self.emptyView.update(config: config)
    }
    
    // MARK: - Actions
    @objc
    private func onTapClose() {
        close()
    }
    
    @objc
    private func onTapMore() {
        self.delegate?.syncBlock(vc: self, onMoreClick: self.viewModel.syncBlockToken)
    }
    
    @objc
    func tapDismiss() {
        close()
    }
    
    override func dragDismiss() {
        close()
    }
    
    func close(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.dismiss(animated: animated) {
            self.delegate?.syncBlock(vc: self, onClose: self.viewModel.syncBlockToken)
            completion?()
        }
    }
                                   
    func didChangeStatusBarOrientation(to newOrentation: UIInterfaceOrientation) {
        guard SKDisplay.phone, newOrentation != .unknown else { return }
        updateContentSize()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingPresentAnimation(animateDuration: 0.25)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingDismissAnimation(animateDuration: 0.25)
    }
    
    // MARK: - UITableViewDelegate UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.referenceListData?.references?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SyncBlockReferenceItemCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? SyncBlockReferenceItemCell,
            let item = self.viewModel.referenceListData?.references?.safe(index: indexPath.row) {
            cell.update(item)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard needFooterView else {
            return nil
        }
        let count = self.viewModel.referenceListData?.noPermissionCount ?? 0
        guard count > 0 else {
            return nil
        }
        
        self.listFooterView.update(title: BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Hidden_Description(count))//"已隐藏没有权限的文档数：\(count)")
        return self.listFooterView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard needFooterView else {
            return 0
        }
        let count = self.viewModel.referenceListData?.noPermissionCount ?? 0
        guard count > 0 else {
            return 0
        }
        return Layout.FooterHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = self.viewModel.referenceListData?.references?.safe(index: indexPath.row) else {
            return
        }
        self.delegate?.syncBlock(vc: self, onItemClick: item)
    }
}

// MARK: - Public Method
extension SyncBlockReferenceViewController {
    public func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}
