//
//  DriveArchivePreviewController.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/5.
//

import UniverseDesignToast
import SnapKit
import UIKit
import SKCommon
import SKResource
import SKFoundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import EENavigator
import SpaceInterface
import UniverseDesignLoading
import SKInfra

enum DriveArchivePreviewAction {
    case startLoading
    case endLoading
    case failure(Error)
    case updateRootNode(DriveArchiveFolderNode)
    case pushFolderNode(DriveArchiveFolderNode)
    case showToast(String)
    case openFile([DriveSDKLocalFileV2])
}

protocol DriveArchiveViewModelType: AnyObject {
    typealias Action = DriveArchivePreviewAction
    var rootNodeName: String { get }
    var actionHandler: ((Action) -> Void)? { get set }
    var additionalStatisticParameters: [String: String]? { get set }
    func startPreview()
    func didClick(node: DriveArchiveNode)
}

class DriveArchivePreviewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private let cellReuseIdentifier = "DriveArchiveNodeCell"

    private lazy var breadcrumbsView: SKBreadcrumbsView<DriveArchiveNode> = {
        let rootName = SKFilePath.getFileNamePrefix(name: archiveViewModel.rootNodeName)
        let rootNode = DriveArchiveFolderNode(name: rootName, parentNode: nil, childNodes: [])
        let view = SKBreadcrumbsView<DriveArchiveNode>(rootItem: rootNode, config: SKBreadcrumbsViewConfig(titleMaxWidth: 105))
        view.clickHandler = { [weak self] node in
            guard let folderNode = node as? DriveArchiveFolderNode else { return }
            self?.popTo(folderNode: folderNode)
            var parmas: [String: Any] = ["click": "title_path", "target": "none"]
            self?.bizDelegate?.statistic(event: DocsTracker.EventType.driveFileOpenClick, params: parmas)
        }
        return view
    }()

    private lazy var folderTableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = UDColor.bgBody
        view.register(DriveArchiveNodeTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        view.separatorInset.left = 76
        view.separatorColor = UIColor.ud.N300
        view.tableHeaderView = UIView(frame: .zero)
        view.tableFooterView = UIView(frame: .zero)
        view.delegate = self
        view.dataSource = self
        return view
    }()

    private var loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
    private var circleLoadingView: UDSpin = {
        let view = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
        return view
    }()

    private var hintView: UIView = {
        let view = UDEmpty(config: .init(title: .init(titleText: ""),
                                         description: .init(descriptionText: BundleI18n.SKResource.Drive_Drive_EmptyFolderInArchive),
                                         imageSize: 100,
                                         type: .noContent,
                                         labelHandler: nil,
                                         primaryButtonConfig: nil,
                                         secondaryButtonConfig: nil))
        return view
    }()

    private let archiveViewModel: DriveArchiveViewModelType
    private var isLoaded = false
    private var displayMode: DrivePreviewMode

    weak var bizDelegate: DriveBizViewControllerDelegate?

    var currentFolderNode: DriveArchiveFolderNode? {
        didSet {
            folderTableView.reloadData()
            let needShowHintView = currentFolderNode?.childNodes.isEmpty ?? false
            DispatchQueue.main.async {
                self.hintView.isHidden = !needShowHintView
            }
        }
    }

    init(viewModel: DriveArchiveViewModelType, displayMode: DrivePreviewMode) {
        archiveViewModel = viewModel
        self.displayMode = displayMode
        super.init(nibName: nil, bundle: nil)
        archiveViewModel.actionHandler = { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleViewModel(action: action)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isLoaded else { return }
        isLoaded = true
        archiveViewModel.startPreview()
    }

    private func setupUI() {
        view.accessibilityIdentifier = "drive.archive.view"
        view.addSubview(breadcrumbsView)
        breadcrumbsView.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.top.equalToSuperview()
            make.height.equalTo(44)
        }
        view.addSubview(folderTableView)
        folderTableView.snp.makeConstraints { make in
            make.top.equalTo(breadcrumbsView.snp.bottom)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
        view.addSubview(hintView)
        hintView.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.center.equalToSuperview()
        }
        hintView.isHidden = true
        showLoadingIndicator()
    }

    private func showLoadingIndicator() {
        if displayMode == .card {
            if circleLoadingView.superview == nil {
                view.addSubview(circleLoadingView)
                circleLoadingView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            circleLoadingView.isHidden = false
            circleLoadingView.reset()
        } else {
            if let loadingView = self.loadingView, loadingView.displayContent.superview == nil {
                view.addSubview(loadingView.displayContent)
                loadingView.displayContent.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                loadingView.startAnimation()
            }
        }
    }

    private func hideLoadingIndicator() {
        if let loadingView = self.loadingView {
            loadingView.stopAnimation()
            loadingView.displayContent.removeFromSuperview()
        }
        circleLoadingView.isHidden = true
        circleLoadingView.removeFromSuperview()
    }
    
    private func popTo(folderNode: DriveArchiveFolderNode) {
        breadcrumbsView.popTo(item: folderNode)
        currentFolderNode = folderNode
    }

    private func handleViewModel(action: DriveArchiveViewModelType.Action) {
        switch action {
        case .startLoading:
            showLoadingIndicator()
        case .endLoading:
            hideLoadingIndicator()
        case .failure(let error):
            DocsLogger.error("Drive.Preview.Archive --- Preview Archive Error", extraInfo: ["error": error])
            handlerError(error)
        case .updateRootNode(let rootFolderNode):
            currentFolderNode = rootFolderNode
            breadcrumbsView.reset(rootItem: rootFolderNode)
            bizDelegate?.openSuccess(type: openType)
        case .pushFolderNode(let folderNode):
            breadcrumbsView.push(item: folderNode)
            currentFolderNode = folderNode
        case .showToast(let message):
            UDToast.showFailure(with: message, on: view)
        case .openFile(let files):
            let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
            let appId = archiveViewModel.additionalStatisticParameters?[DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue]
            let vc = DocsContainer.shared.resolve(DriveSDK.self)!.createLocalFileController(localFiles: files,
                                                                                   index: 0,
                                                                                   appID: appId ?? DKSupportedApp.miniApp.rawValue,
                                                                                   thirdPartyAppID: nil,
                                                                                   naviBarConfig: config)
            Navigator.shared.push(vc, from: self)
        }
    }
    
    private func handlerError(_ error: Error) {
        if let driveError = error as? DriveError, case .previewLocalArchiveTooLarge = driveError {
            bizDelegate?.unSupport(self, reason: .sizeTooBig, type: openType)
        } else {
            let extraInfo = ["error_message": error.localizedDescription]
            bizDelegate?.previewFailed(self, needRetry: false, type: openType, extraInfo: extraInfo)
        }
    }
}

extension DriveArchivePreviewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let folderNode = currentFolderNode,
            folderNode.childNodes.count > indexPath.row else {
            assertionFailure("Drive.Preview.Archive --- Archive Folder Node Index out of range")
            DocsLogger.error("Drive.Preview.Archive --- Archive Folder Node Index out of range")
            return
        }
        let node = folderNode.childNodes[indexPath.row]
        archiveViewModel.didClick(node: node)
        let parmas: [String: Any] = ["click": "list_item", "target": "ccm_drive_page_view"]
        bizDelegate?.statistic(event: DocsTracker.EventType.driveFileOpenClick, params: parmas)
    }
}

extension DriveArchivePreviewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentFolderNode?.childNodes.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        guard let nodeCell = cell as? DriveArchiveNodeTableViewCell else {
            DocsLogger.error("Drive.Preview.Archive --- Failed to convert cell to subclass ArchiveCell")
            return cell
        }
        guard let folderNode = currentFolderNode,
            folderNode.childNodes.count > indexPath.row else {
            assertionFailure("Drive.Preview.Archive --- Archive Folder Node Index out of range")
            DocsLogger.error("Drive.Preview.Archive --- Archive Folder Node Index out of range")
            return nodeCell
        }
        let node = folderNode.childNodes[indexPath.row]
        nodeCell.updateUI(node: node)
        return nodeCell
    }
}

extension DriveArchivePreviewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .archiveView
    }
    
    var panGesture: UIPanGestureRecognizer? {
        folderTableView.panGestureRecognizer
    }
    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {
        if mode == .card {
            folderTableView.showsHorizontalScrollIndicator = false
            folderTableView.showsVerticalScrollIndicator = false
        }
    }
    
    func changingDisplayMode(_ mode: DrivePreviewMode) {
    }
        
    func updateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
        if mode == .normal {
            folderTableView.showsHorizontalScrollIndicator = true
            folderTableView.showsVerticalScrollIndicator = true
        }
    }
}
