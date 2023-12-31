//
//  DriveImportAsDocsViewController.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/25.
//

import Foundation
import EENavigator
import SnapKit
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import SpaceInterface

class DriveConvertFileViewController: BaseViewController {

    // MARK: - View
    private var loadingView: DocsLoadingViewProtocol?

    private let importFailedView: DriveImportFailedView = DriveImportFailedView()

    // MARK: - ViewModel
    private let viewModel: DKConvertFileVMProtocol

    // MARK: - 埋点
    private let performanceLogger: DrivePerformanceRecorder

    private let actionSource: DriveStatisticActionSource

    private let previewFrom: DrivePreviewFrom

    private var isNotifyAdmin: Bool = false

    // MARK: 文件名，显示标题用
    private let fileName: String

    // MARK: - 生命周期
    init(viewModel: DKConvertFileVMProtocol,
         loadingView: DocsLoadingViewProtocol?,
         performanceLogger: DrivePerformanceRecorder? = nil,
         actionSource: DriveStatisticActionSource,
         previewFrom: DrivePreviewFrom) {
        self.performanceLogger = performanceLogger ?? DrivePerformanceRecorder(
            fileToken: viewModel.fileID,
            fileType: viewModel.fileType.rawValue,
            sourceType: .preview,
            additionalStatisticParameters: nil
        )
        self.viewModel = viewModel
        self.loadingView = loadingView
        self.fileName = viewModel.name
        self.actionSource = actionSource
        self.previewFrom = previewFrom
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(file: SpaceEntry,
                     loadingView: DocsLoadingViewProtocol?,
                     actionSource: DriveStatisticActionSource,
                     previewFrom: DrivePreviewFrom) {
        let fileMeta = DriveFileMeta(size: 0,
                                     name: file.name ?? "",
                                     type: file.fileType ?? "unknow",
                                     fileToken: file.objToken,
                                     mountNodeToken: "",
                                     mountPoint: "",
                                     version: "",
                                     dataVersion: "",
                                     source: .other,
                                     tenantID: file.ownerTenantID,
                                     authExtra: nil)
        let fileInfo = DriveFileInfo(fileMeta: fileMeta)
        let performanceLogger = DrivePerformanceRecorder(fileToken: file.objToken,
                                                         fileType: file.fileType ?? "",
                                                         previewFrom: previewFrom,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let viewModel = DriveConvertFileViewModel(fileInfo: fileInfo,
                                                  performanceLogger: performanceLogger)
        self.init(viewModel: viewModel,
                  loadingView: loadingView,
                  performanceLogger: performanceLogger,
                  actionSource: actionSource,
                  previewFrom: previewFrom)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.driveInfo("DriveConvertFileViewController deinit")
        performanceLogger.importFinished(result: .cancel, code: .cancel)
        reportClientCommerce()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 打开埋点
        performanceLogger.importStart()
        setupNavbarTitle()
        startLoading()
        setupViewModel()
        reportImportToOnlineFile()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 用户取消埋点 如果打开成功已经上报过 则不会上报取消
    }

    // MARK: - UI
    private func setupNavbarTitle() {
        self.title = fileName
        navigationBar.titleLabel.isHidden = false
    }

    private func startLoading() {
        if let loadingView = loadingView {
            if loadingView.displayContent.superview != view {
                view.addSubview(loadingView.displayContent)
                loadingView.displayContent.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
            loadingView.text = BundleI18n.SKResource.Drive_Drive_FileImporting
            view.bringSubviewToFront(loadingView.displayContent)
            loadingView.startAnimation()
        } else {
            showLoading()
        }
        /**
         导航栏为Docs自定义
         在改变子视图层级时，如：bringSubviewToFront() 需要重新将自定义导航栏放置到顶层, 避免子视图遮住导航栏
         */
        view.bringSubviewToFront(navigationBar)
    }

    private func stopLoading() {
        if loadingView == nil {
            hideLoading()
        } else {
            loadingView?.stopAnimation()
        }
    }

    private func showImportFailedView(viewType: DriveImportFailedViewType) {
        DocsLogger.driveInfo("DriveConvertFileViewController.showImportFailedView", extraInfo: ["viewType": viewType])
        
        importFailedView.isHidden = false
        importFailedView.retryAction = { [weak self] in
            guard let self = self else {
                DocsLogger.driveInfo("DriveConvertFileViewController.showImportFailedView: self is nil")
                return
            }
            self.handleRetryAction(viewType: viewType)
        }
        importFailedView.fileSizeText = DriveConvertFileConfig.getFileSizeText(from: self.viewModel.fileSize)
        importFailedView.render(type: viewType)
        
        if !importFailedView.isDescendant(of: view) { // 避免重复添加subview
            view.addSubview(importFailedView)
            importFailedView.snp.makeConstraints { (make) in
                make.top.equalTo(navigationBar.snp.bottom)
                make.left.right.bottomMargin.equalToSuperview()
            }
        }
                ///dlp error toast
        switch viewType {
        case .dlpExternalDetcting:
            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpErrorCode: DlpErrorCode.dlpExternalDetcting.rawValue)
            let dlpMsg = DlpErrorCode.errorMsg(with: DlpErrorCode.dlpExternalDetcting.rawValue)
            UDToast.showFailure(with: dlpMsg, on: view.window ?? view)
        case .dlpExternalSensitive:
            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpErrorCode: DlpErrorCode.dlpExternalSensitive.rawValue)
            let dlpMsg = DlpErrorCode.errorMsg(with: DlpErrorCode.dlpExternalSensitive.rawValue)
            UDToast.showFailure(with: dlpMsg, on: view.window ?? view)
        default: break
        }
    }
    
    private func hideImportFailedView() {
        importFailedView.isHidden = true
    }

    // MARK: - View Model
    /// 绑定viewMdeol 事件 viewModel准备加载数据
    private func setupViewModel() {
        viewModel.bindAction = { [weak self] action in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.handleViewModelAction(action)
            }
        }
        /// 检查文件大小是否大于20M
        if viewModel.isFileSizeOverLimit() {
            showImportFailedView(viewType: .fileSizeOverLimit)
        } else {
            viewModel.convertFile()
        }
    }

    private func handleViewModelAction(_ action: DriveConvertFileAction) {
        switch action {
        case .exitConverting:
            exitConverting()
        case .showFailedView(let viewType):
            stopLoading()
            showImportFailedView(viewType: viewType)
        case let .routedToExternal(token, type):
            routedToExternal(token: token, type: type)
        case .updateFileSizeText(let text):
            importFailedView.fileSizeText = text
        case .networkChanged(let isReachable):
            handleNetworkChanged(isReachable: isReachable)
        case .showToast(let tips):
            UDToast.showTips(with: tips, on: view.window ?? view)
        }
    }

    private func handleNetworkChanged(isReachable: Bool) {
        DocsLogger.driveInfo("DriveConvertFileViewController.handleNetworkChanged", extraInfo: ["isReachable": isReachable])
        
        if !isReachable {
            showImportFailedView(viewType: .networkInterruption)
        }
        importFailedView.buttonEnable = isReachable
    }

    private func handleRetryAction(viewType: DriveImportFailedViewType) {
        DocsLogger.driveInfo("DriveConvertFileViewController.handleRetryAction", extraInfo: ["viewType": viewType])
        
        if viewType == .importFailedRetry || viewType == .networkInterruption {
            self.startLoading()
            self.hideImportFailedView()
            self.viewModel.convertFile()
        } else if viewType == .contactService {
            // 联系客服需要初始化一些数据
            HostAppBridge.shared.call(LaunchCustomerService())
            // 打开Lark的联系客服页面
            DocsLogger.driveInfo("DriveConvertFileViewController.showImportFailedView: open customer service")
            NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: LarkOpenEvent.customerService(controller: self))
        } else if viewType == .numberOfFileExceedsTheLimit {
            /// 通知管理员升级
            CreateLimitedNotifyRequest.notifysuitebot()
            self.isNotifyAdmin = true
            /// 埋点
            DriveStatistic.clientCommerce(action: DriveStatisticAction.notifyAdmin)
        }
    }

    // MARK: - Exit
    private func exitConverting() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Routed
    private func routedToExternal(token: String, type: DocsType) {
        let url = DocsUrlUtil.url(type: type, token: token)
        guard let navigationController = navigationController else {
            spaceAssertionFailure("Navigation Controller is nil")
            return
        }
        /// 找到当前VC在navigationController栈中的上一个VC
        let lastVCIndex = navigationController.viewControllers.endIndex - 2
        guard lastVCIndex >= 0 else {
            if SKDisplay.pad, navigationController.viewControllers.first == self {
                if let vc = Navigator.shared.response(for: url).resource as? UIViewController {
                    navigationController.setViewControllers([vc], animated: false)
                }
            } else {
                spaceAssertionFailure("Navigation Controller only have one viewControllers")
            }
            return
        }
        let lastVC = navigationController.viewControllers[lastVCIndex]
        navigationController.popViewController(animated: false)
        // 通过EENavigator跳转
        Navigator.shared.push(url, context: [:], from: lastVC, animated: true, completion: nil)
    }

    // MARK: - Report
    private func reportImportToOnlineFile() {
        // Drive业务埋点：导入为在线文档
        let additionalParameters = [DriveStatistic.ReportKey.source.rawValue: actionSource.rawValue]
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.importToOnlineFile,
                                               fileId: viewModel.fileID,
                                               additionalParameters: additionalParameters)
    }

    private func reportClientCommerce() {
        /// Drive业务埋点：用户取消了通知管理员的操作
        if importFailedView.type == .numberOfFileExceedsTheLimit && !isNotifyAdmin {
            DriveStatistic.clientCommerce(action: .cancel)
        }
    }
}
