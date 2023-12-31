//
//  DocsVersionViewController.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2022/9/4.
//
//  获取文档历史版本列表VC
//

import Foundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import UniverseDesignLoading
import LarkTraitCollection
import RxSwift

public protocol VersionParentVCProtocol: NSObject {
    func didChangeVersionTo(item: DocsVersionItemData, from: FromSource?)
}

public protocol DocsVersionPanelDelegate: AnyObject {
    func didClickVersion(item: DocsVersionItemData, from: FromSource?)
    func getDocsTrackCommonParams() -> [String: Any]?
}

public final class DocsVersionViewController: DocsVersionGraggableViewController {
    private var viewModel: DocsVersionsPanelViewModel
    private var currentVersionToken: String?
    public weak var delegate: DocsVersionPanelDelegate?
    private let bag = DisposeBag()
    
    private lazy var failTipsView: EmptyListPlaceholderView = {
        let view = EmptyListPlaceholderView(frame: .zero)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(clickReload))
        view.addGestureRecognizer(gesture)
        return view
    }()
    
    private lazy var titleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
    }
     
    private lazy var loadingView = UIView().construct { it in
        it.backgroundColor = .clear
        let spin = UDLoading.presetSpin(color: .primary, loadingText: BundleI18n.SKResource.Doc_Facade_Loading)
        it.addSubview(spin)
        spin.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }
    }
    
    private lazy var versionListView: UITableView = {
        let tableV = UITableView()
        tableV.backgroundColor = .clear
        tableV.delegate = self
        tableV.dataSource = self
        tableV.separatorStyle = .none
        tableV.showsVerticalScrollIndicator = false
        tableV.showsHorizontalScrollIndicator = false
        tableV.contentInsetAdjustmentBehavior = .never
        tableV.register(DocsVersionSavedCell.self, forCellReuseIdentifier: DocsVersionSavedCell.reuseIdentifier)
        return tableV
    }()
    
    public init(title: String, currentVersionToken: String? = nil, viewModel: DocsVersionsPanelViewModel, shouldShowDragBar: Bool) {
        self.viewModel = viewModel
        self.currentVersionToken = currentVersionToken
        super.init(title: title, shouldShowDragBar: shouldShowDragBar)
        self.containerView.backgroundColor = UDColor.bgFloatBase
        self.titleLabel.text = title
        self.modalPresentationStyle = .overCurrentContext
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        showLoadingView()
        
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                if change.old != change.new, SKDisplay.pad {
                    self?.dismiss(animated: false)
                }
            }).disposed(by: bag)
        
        var params: [String: Any] = [:]
        if let commparam = self.delegate?.getDocsTrackCommonParams() {
            params.merge(other: commparam)
        }
        if viewModel.type == .sheet {
            DocsTracker.newLog(enumEvent: .sheetVersionPanel, parameters: params)
        } else {
            DocsTracker.newLog(enumEvent: .docsVersionPanel, parameters: params)
        }
    }
    
    override func setupUI() {
        super.setupUI()
        setupTableView()
        setupViewModel()
    }
    
    func setupTableView() {
        self.containerView.addSubview(self.versionListView)
        versionListView.isHidden = true
        versionListView.snp.makeConstraints { (make) in
            make.top.equalTo(60)
            make.left.bottom.right.equalToSuperview()
        }
        addInfinitedScrolling()
    }
    
    func setupViewModel() {
        viewModel.bindAction = {[weak self] action in
            guard let `self` = self else { return }
            switch action {
            case .reloadData:
                self.versionListView.isHidden = false
                self.versionListView.reloadData()
                self.stopLoading()
            case .loadEmpty:
                self.stopLoading()
                self.handleError(empty: true)
            case .loadError:
                self.stopLoading()
                self.handleError()
            case .stopLoading:
                self.stopRefresh()
                self.stopLoading()
            case .noMoreData:
                self.removeInfinitedScrolling()
                self.versionListView.es.noticeNoMoreData()
            case .resetNoMoreData:
                self.addInfinitedScrolling()
                self.versionListView.es.resetNoMoreData()
            case .removeFooter:
                self.versionListView.es.removeRefreshFooter()
            }
        }
        viewModel.loadData()
    }
    
    func stopRefresh() {
        versionListView.es.stopLoadingMore()
    }
    
    private func showLoadingView() {
        if loadingView.superview != view {
            containerView.addSubview(loadingView)
            loadingView.snp.makeConstraints { (make) in
                make.top.equalTo(60)
                make.left.bottom.right.equalToSuperview()
            }
        }
        containerView.bringSubviewToFront(loadingView)
        failTipsView.removeFromSuperview()
    }
    
    private func stopLoading() {
        loadingView.removeFromSuperview()
    }
    
    private func handleError(empty: Bool = false) {
        containerView.addSubview(failTipsView)
        failTipsView.snp.makeConstraints { (make) in
            make.top.equalTo(60)
            make.left.bottom.right.equalToSuperview()
        }
        if empty {
            failTipsView.config(error: ErrorInfoStruct(type: .empty, title: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_NoVersionsSaved_Mob, domainAndCode: nil))
        } else {
            failTipsView.config(error: ErrorInfoStruct(type: .openFileFail, title: BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_title, domainAndCode: nil))
        }
    }
    
    func addInfinitedScrolling() {
        if versionListView.footer != nil { return }
        versionListView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let `self` = self else { return }
            if self.viewModel.isLoadingData {
                self.versionListView.es.stopLoadingMore()
                return
            }
            self.viewModel.loadData(loadMore: true)
        }
    }

    func removeInfinitedScrolling() {
        versionListView.es.removeRefreshFooter()
    }
    
    @objc
    func clickReload() {
        showLoadingView()
        viewModel.loadData()
    }
    
    @objc
    func didChangeStatusBarOrientation(_ notification: Notification) {
        guard SKDisplay.phone else { return }
        guard let int = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
              let newOrientation = UIInterfaceOrientation(rawValue: int),
              newOrientation != .unknown else { return }
        let totalHeight = self.draggableMinViewHeight
        self.containerView.snp.remakeConstraints { (make) in
            if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
                make.width.equalToSuperview().multipliedBy(0.7)
                make.centerX.equalToSuperview()
            } else {
                make.left.right.equalToSuperview()
            }
            make.height.equalTo(totalHeight)
            make.bottom.equalTo(0)
        }
        self.view.layoutIfNeeded()
    }
    
    private func didSelectNewVerion(data: DocsVersionItemData) {
        DocsLogger.info("select new version: \(data.versionToken.encryptToken)", component: LogComponents.version)
        
        var params: [String: Any] = ["click": "saved_version", "target_version_id": data.version, "target": "ccm_docs_version_page_view"]
        if let commparam = self.delegate?.getDocsTrackCommonParams() {
            params.merge(other: commparam)
        }
        if viewModel.type == .sheet {
            DocsTracker.newLog(enumEvent: .sheetVersionSavedClick, parameters: params)
        } else {
            DocsTracker.newLog(enumEvent: .docsVersionSavedClick, parameters: params)
        }
        guard data.versionToken != self.currentVersionToken else {
            DocsLogger.info("same version do nothing", component: LogComponents.version)
            self.didClickClose()
            return
        }
        self.didClickClose()
        self.delegate?.didClickVersion(item: data, from: self.viewModel.fromSource)
    }
    
    override public func closePage() {
        var params: [String: Any] = ["click": "exit", "target": "none"]
        if let commparam = self.delegate?.getDocsTrackCommonParams() {
            params.merge(other: commparam)
        }
        DocsTracker.newLog(enumEvent: .docsVersionSavedClick, parameters: params)
        super.closePage()
    }
}

extension DocsVersionViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.versionDatas.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DocsVersionSavedCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? DocsVersionSavedCell {
            cell.delegate = self
            cell.renderCell(presenter: self.viewModel.versionDatas[indexPath.row])
            cell.updateSelect(self.currentVersionToken == self.viewModel.versionDatas[indexPath.row].versionToken)
            return cell
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 69.5
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.versionDatas.count else { return }
        let item = viewModel.versionDatas[indexPath.row]
        self.didSelectNewVerion(data: item)
    }
}

extension DocsVersionViewController: DocsVersionSavedCellDelegate {
    public func didClickCell(cell: UITableViewCell) {
        let indexPath = versionListView.indexPath(for: cell)
        if indexPath != nil, indexPath!.row < viewModel.versionDatas.count {
            let item = viewModel.versionDatas[indexPath!.row]
            self.didSelectNewVerion(data: item)
        }
    }
}
