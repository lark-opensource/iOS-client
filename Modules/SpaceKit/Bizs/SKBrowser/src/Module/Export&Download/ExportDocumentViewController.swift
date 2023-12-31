//
//  ExportDocumentViewController.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/20.
//

import Foundation
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignColor
import LarkTraitCollection
import UniverseDesignActionPanel

public final class ExportDocumentViewController: SKPanelController, ExportDocumentSelectDelegate {
//    fileprivate struct Const {
//        static let titleViewHeight: CGFloat = 48
//    }

    private(set) lazy var titleView = SKPanelHeaderView()
    private(set) lazy var selectView = ExportDocumentSelectView(infos: viewModel.itemsInfo, formSheet: modalPresentationStyle == .formSheet, hostSize: viewModel.hostSize, delegate: self)

    let viewModel: ExportDocumentViewModel
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    init(viewModel: ExportDocumentViewModel) {
        self.viewModel = viewModel
        if viewModel.docsInfo.inherentType == .docX {
            self.supportOrientations = viewModel.hostViewController?.supportedInterfaceOrientations ?? .portrait
        }
        super.init(nibName: nil, bundle: nil)
        titleView.setCloseButtonAction(#selector(didClickMask), target: self)
        titleView.setTitle(viewModel.titleText)
        transitioningDelegate = panelFormSheetTransitioningDelegate
        if SKDisplay.phone && supportedInterfaceOrientations != .portrait {
            dismissalStrategy = []
        } else {
            dismissalStrategy = [.viewSizeChanged, .larkSizeClassChanged, .systemSizeClassChanged]
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if SKDisplay.phone, supportedInterfaceOrientations != .portrait {
            updateContentSize()
        }
    }

    @objc
    public override func didClickMask() {
        dismiss(animated: true, completion: nil)
    }
    
    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
        containerView.addSubview(selectView)
        selectView.snp.makeConstraints { (make) in
            make.top.equalTo(titleView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(selectView.preferredHeight)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func updateContentSize() {
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            containerView.snp.remakeConstraints { (make) in
                make.centerX.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
            }
            selectView.updateWidth(view.bounds.width * 0.7)
        } else {
            containerView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
            selectView.updateWidth(view.bounds.width)
        }
        selectView.collectionView.reloadData()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.selectView.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    @objc
    func didChangeStatusBarOrientation(_ notice: Notification) {
        view.layoutIfNeeded()
        updateContentSize()
    }

    func didSelectExportDocument(_ info: ExportDocumentItemInfo) {
        var params = ["app_form": "null",
                      "module": viewModel.module.rawValue,
                      "sub_module": viewModel.module.subRawValue ?? "none",
                      "container_id": "null",
                      "container_type": "null",
                      "target": "null",
                      "click": "exports_as",
                      "sub_file_type": viewModel.docsInfo.fileType ?? "null",
                      "file_id": DocsTracker.encrypt(id: viewModel.docsInfo.objToken),
                      "file_type": viewModel.docsInfo.type.name,
                      "export_type": info.exportDocDownloadType.reportDescriptionV2]
        if let id = viewModel.containerID {
            params["container_id"] = DocsTracker.encrypt(id: id)
        }
        if let type = viewModel.containerType {
            params["container_type"] = type
        }

        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let isDocX = self.viewModel.docsInfo.inherentType == .docX
            let exportSupportComment = info.exportDocDownloadType.exportSupportComment && isDocX
            guard UserScopeNoChangeFG.HYF.exportSupportCommentEnable, exportSupportComment else {
                self.viewModel.startToExportDocument(info, needComment: nil)
                return
            }
            params["target"] = "ccm_docs_export_as_set_view"
            // viewModel要强引用在block内部
            let viewModel = self.viewModel
            let actionSheet = UDActionSheet.actionSheet(title: BundleI18n.SKResource.LarkCCM_Docs_Export_Scope_Options)
            actionSheet.addItem(text: BundleI18n.SKResource.LarkCCM_Docs_Export_Scope_TextCmt_Options, textColor: UDColor.textTitle) {
                viewModel.startToExportDocument(info, needComment: true)
                params["click"] = "confirm"
                params["export_content"] = "text_and_comment"
                DocsTracker.newLog(enumEvent: .docsExportAsSetClick, parameters: params)
            }
            actionSheet.addItem(text: BundleI18n.SKResource.LarkCCM_Docs_Export_Scope_Text_Options, textColor: UDColor.textTitle) {
                viewModel.startToExportDocument(info, needComment: false)
                
                params["click"] = "confirm"
                params["export_content"] = "text"
                DocsTracker.newLog(enumEvent: .docsExportAsSetClick, parameters: params)
            }
            actionSheet.addItem(text: BundleI18n.SKResource.LarkCCM_Docs_Export_Cancel_Button, style: .cancel) {
                params["click"] = "cancel"
                DocsTracker.newLog(enumEvent: .docsExportAsSetClick, parameters: params)
            }
            self.viewModel.hostViewController?.present(actionSheet, animated: true)
            DocsTracker.newLog(enumEvent: .spaceDocsMoreMenuClick, parameters: params)
            params["target"] = "none"
            DocsTracker.newLog(enumEvent: .docsExportAsSetView, parameters: params)
            
        }
        DocsTracker.log(enumEvent: .spaceRightClickMenuClick, parameters: params)

        DocsTracker.reportDriveDownload(event: .driveDownloadBeginClick,
                                        mountPoint: "explorer",
                                        fileToken: viewModel.docsInfo.objToken,
                                        fileType: viewModel.docsInfo.fileType ?? "")
        reportSpaceExportAsClick(info)
        if info.exportDocDownloadType == .docsLongImage {
            SecurityReviewManager.reportAction(viewModel.docsInfo.type,
                                               operation: OperationType.operationsExport,
                                               token: viewModel.docsInfo.objToken,
                                               appInfo: .snapshot,
                                               wikiToken: viewModel.docsInfo.wikiInfo?.wikiToken)

        }
    }

    private func reportSpaceExportAsClick(_ info: ExportDocumentItemInfo) {
        var params = ["app_form": "null",
                      "module": viewModel.module.rawValue,
                      "sub_module": viewModel.module.subRawValue ?? "none",
                      "container_id": "null",
                      "container_type": "null",
                      "target": "none",
                      "sub_file_type": viewModel.docsInfo.fileType ?? "null",
                      "file_id": DocsTracker.encrypt(id: viewModel.docsInfo.objToken),
                      "file_type": viewModel.docsInfo.type.name,
                      "click": info.exportDocDownloadType.reportDescriptionV2,
                      "is_version": viewModel.docsInfo.isVersion ? "true" : "false"]
        if let id = viewModel.containerID {
            params["container_id"] = DocsTracker.encrypt(id: id)
        }
        if let type = viewModel.containerType {
            params["container_type"] = type
        }
        DocsTracker.log(enumEvent: .spaceExportAsClick, parameters: params)
    }
}
