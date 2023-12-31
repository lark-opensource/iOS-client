//
//  DriveActivityViewController.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/12.
//

import UIKit
import SnapKit
import ESPullToRefresh
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import SpaceInterface
import SKInfra

class DriveActivityViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    var loadingView: DocsLoadingViewProtocol?

    private var tableView: UITableView = .init(frame: .zero)
    private let viewModel: DriveActivityViewModel
    private var versionDataMgr: VersionDataMananger?

    init(viewModel: DriveActivityViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Clean user info
        DriveActivityViewModel.userInfoDic.removeAll()
        DocsLogger.debug("DriveActivityViewController----deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startLoading()
        setupViewModel()
        setupVersionDataMgr()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopRefresh()
        self.stopLoading()
    }

   // MARK: - Prepare
    func setupUI() {
        title = BundleI18n.SKResource.Drive_Drive_HistoryRecordPageTitle
        setupTableView()
    }

    func setupTableView() {
        tableView = UITableView(frame: .zero)
        tableView.backgroundColor = UDColor.bgBody
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(DriveHistoryVersionTableCell.self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
            make.left.bottom.right.equalToSuperview()
        }

        let footerView = UIView()
        footerView.backgroundColor = UIColor.ud.N00
        tableView.tableFooterView = footerView

        addRefreshHeader()
        addInfinitedScrolling()

        tableView.contentInsetAdjustmentBehavior = .never
    }

    func setupViewModel() {
        viewModel.bindAction = {[weak self] action in
            guard let `self` = self else { return }
            switch action {
            case .reloadData:
                self.tableView.reloadData()
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

    func setupVersionDataMgr() {
        versionDataMgr = VersionDataMananger(fileToken: viewModel.fileMeta.fileToken, type: viewModel.docsInfo.type)
        versionDataMgr?.delegate = self
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

    func addRefreshHeader() {
        if tableView.header != nil { return }
        tableView.es.addPullToRefreshOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let `self` = self else { return }
            if self.viewModel.isLoadingData {
                self.tableView.es.stopPullToRefresh()
                return
            }
            self.viewModel.loadData()
        }
    }

    func stopRefresh() {
        tableView.es.stopPullToRefresh()
        tableView.es.stopLoadingMore()
    }
    // MARK: - Loading,

    func startLoading() {
        if let loadingView = loadingView {
            if loadingView.displayContent.superview != view {
                view.addSubview(loadingView.displayContent)
                loadingView.displayContent.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
            view.bringSubviewToFront(loadingView.displayContent)
            loadingView.startAnimation()
        } else {
            showLoading()
        }
        view.bringSubviewToFront(navigationBar)
    }

    func stopLoading() {
        if loadingView == nil {
            hideLoading()
        } else {
            loadingView?.stopAnimation()
        }
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let record = viewModel.historyRecords[indexPath.row]
        return record.recordHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let record = viewModel.historyRecords[indexPath.row]
        if let keyDeleted = record.cipherDelete, keyDeleted {
            DocsLogger.driveInfo("Record model's file key had deleted")
            return
        }
        guard let recordType = record.recordType else {
            DocsLogger.error("Record model has not type")
            return
        }
        if record.isDeleted || recordType == .delete || recordType == .rename {
            DocsLogger.driveInfo("Click deleted version or renamed version")
            return
        }
        if record.version == viewModel.fileMeta.version {
            currentVersionTransition()
        } else {
            historyVersionTransition(record: record)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.historyRecords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DriveHistoryVersionTableCell = tableView.dequeueReusableCell(for: indexPath)
        let presenter = viewModel.historyRecords[indexPath.row]
        cell.render(presenter: presenter)
        return cell
    }
}

// MARK: - Page Transition
private extension DriveActivityViewController {

    func currentVersionTransition() {
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = CFTimeInterval(UINavigationController.hideShowBarDuration)
        transition.timingFunction = CAMediaTimingFunction(name: .default)
        navigationController?.view.layer.add(transition, forKey: nil)
        navigationController?.popViewController(animated: false)
    }

    func historyVersionTransition(record: DriveHistoryRecordModel) {
        let configuration = DrivePreviewConfiguration(shouldShowRightItems: false,
                                                      loadingView: loadingView,
                                                      hitoryEditTimeStamp: record.timeStamp)
        let file = viewModel.generatePreviewViewModel(record: record)
        let context = [DKContextKey.from.rawValue: DrivePreviewFrom.history.rawValue,
                       DKContextKey.editTimeStamp.rawValue: record.timeStamp] as [String: Any]
        let vc = DocsContainer.shared.resolve(DriveSDK.self)!
             .createSpaceFileController(files: [file],
                                        index: 0,
                                        appID: DKSupportedApp.space.rawValue,
                                        isInVCFollow: false,
                                        context: context,
                                        statisticInfo: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - VersionDataDelegate
extension DriveActivityViewController: VersionDataDelegate {
    func didReceiveVersion(version: String, type: VersionDataMananger.VersionReceiveOperation) {
        viewModel.loadData()
    }
}
