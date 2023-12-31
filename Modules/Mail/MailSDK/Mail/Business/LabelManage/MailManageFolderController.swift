//
//  MailManageFolderController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/11/10.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkAlertController
import Homeric
import LarkGuideUI
import UniverseDesignTabs
import UniverseDesignButton

class MailManageFolderController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    enum Scene {
        case editFolder
        case setting
    }

    // MARK: - Property
    private let disposeBag = DisposeBag()
    var labels: [MailFilterLabelCellModel] = []
    var allLabels: [MailFilterLabelCellModel] = []
    var scene: Scene = .editFolder
    lazy var sessionIDs = [String]()
    weak var delegate: MailManageTagNavigateDelegate?

    private var didLoaded = false

    weak var tagDelegate: MailManageTagDelegate?
    lazy var guideKey = "all_email_feishuversion"
    var upsetFolderID: String?

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }
    let accountContext: MailAccountContext
    
    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }


    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
        setupViews()
        getLabels()
        MailCommonDataMananger
            .shared
            .batchEndChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.mailBatchChangesEnd(change)
            }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    MailLogger.debug("[mail_folder] manage folder get mailLabelChange \(change.labels.count)")
                    self?.getLabels(scrollToNewFolder: (self?.upsetFolderID ?? nil) != nil)
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }

    func mailBatchChangesEnd(_ change: MailBatchEndChange) {
        MailRoundedHUD.remove(on: view)
        self.sessionIDs.lf_remove(object: change.sessionID)
        MailLogger.debug("[mail_folder] delete folder mailBatchChangesEnd sessionID: \(change.sessionID)")
        if change.code == 1 {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Folder_DeletedSuccessfully(""), on: self.view)
        } else {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Folder_DeleteFailed, on: self.view)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MailRoundedHUD.remove(on: self.view)
    }

    // MARK: - Views
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.registerClass(MailManageLabelCell.self)
        tableView.registerClass(MailManageLabelEmptyCell.self)
        tableView.tableFooterView = UIView()
        tableView.accessibilityIdentifier = MailAccessibilityIdentifierKey.TableViewLabelManageKey
        tableView.tableFooterView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 15)
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = ModelViewHelper.listColor()
        return tableView
    }()

    private lazy var confirmButton: UIButton = {
        let confirmButton = UIButton(type: .custom)
        confirmButton.layer.cornerRadius = 10
        confirmButton.layer.masksToBounds = true
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        confirmButton.setTitle(BundleI18n.MailSDK.Mail_Folder_CreateNewFolder, for: .normal)
        confirmButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault), for: .normal)
        confirmButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillDisabled), for: .disabled)
        confirmButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.didClickCreateFolderButton()
        }).disposed(by: disposeBag)
        return confirmButton
    }()

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_Manage_FolderManageMobile
        self.view.backgroundColor = ModelViewHelper.listColor()
        updateNavAppearanceIfNeeded()

        self.view.addSubview(tableView)

        let bottomOffset = Display.pad ? 16 : Display.bottomSafeAreaHeight + 16
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomOffset - 48 - 16)
        }
        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-bottomOffset)
        }
    }

    @objc
    func getLabels(scrollToNewFolder: Bool = false) {
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
            let newLabels = labels.genSortedSystemFirst()
            self.updateView(newLabels, scrollToNewFolder: scrollToNewFolder)
            self.didLoaded = true
        }).disposed(by: disposeBag)
    }

    func updateView(_ labels: [MailFilterLabelCellModel], scrollToNewFolder: Bool = false) {
        self.allLabels = labels
        var managelabels: [MailFilterLabelCellModel] = []
        if FeatureManager.enableSystemFolder() {
            managelabels = labels.filter {
                ($0.tagType == .folder || ($0.isSystem && managableSystemFolders.contains($0.labelId)))
                && $0.labelId != Mail_LabelId_Stranger
            }
        } else {
            managelabels = labels.filter {
                $0.isSystem == false &&
                $0.tagType == .folder &&
                ($0.mailClientType == .larkMail || $0.mailClientType == .googleMail) &&
                $0.labelId != Mail_LabelId_Stranger
            }
        }
        self.labels = managelabels
        self.tableView.reloadData()
        if scrollToNewFolder {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short, execute: { [weak self] in
                self?.scrollToNewFolder()
            })
        }
    }

    func scrollToNewFolder() {
        guard let newFolderID = upsetFolderID else { return }
        guard let index = self.labels.firstIndex(where: { $0.labelId == newFolderID }) else { return }
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal, execute: { [weak self] in
            if let cell = self?.tableView.cellForRow(at: indexPath) as? MailManageLabelCell {
                cell.showPressStatus()
            }
        })

        self.upsetFolderID = nil
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if labels.isEmpty {
            return 1
        } else {
            return labels.count
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if labels.isEmpty {
            return CGFloat.maximum(tableView.bounds.size.height, 0.01)
        } else {
            return 48
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if labels.isEmpty {
            if !didLoaded { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(for: indexPath) as MailManageLabelEmptyCell
            cell.config(.folder)
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(for: indexPath) as MailManageLabelCell
            let label = labels[indexPath.row]
            cell.config(label)
            cell.delegate = self
            cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelManageCellKey + "\(indexPath.row)"
            return cell
        }
    }

    @objc
    func didClickCreateFolderButton() {
        didClickCreateFolder()
    }
}

extension MailManageFolderController: MailManageEmptyCellDelegate {
    func didClickCreateFolder() {
        let createFolderVC = MailCreateTagController(accountContext: accountContext)
        createFolderVC.scene = .newFolder
        createFolderVC.folderTree = FolderTree.build(allLabels)
        createFolderVC.folderDelegate = self
        createFolderVC.loadLabels = allLabels.filter({ $0.tagType == .folder || $0.isSystem })
        MailTracker.log(event: "email_folder_create_click", params: [MailTracker.sourceParamKey(): MailTracker.source(type: .folderManage)])
        if #available(iOS 13.0, *) {
//            createFolderVC.modalTransitionStyle = .partialCurl
            createFolderVC.modalPresentationStyle = .overCurrentContext// .automatic
            navigator?.present(LkNavigationController(rootViewController: createFolderVC), from: self)
        } else {
            if self.navigationController != nil {
                navigator?.push(createFolderVC, from: self)
            } else {
                self.delegate?.pushVC(createFolderVC)
            }
        }
    }

    func didClickCreateLabel() {}
}

// MARK: - MailManageLabelCellDelegate
extension MailManageFolderController: MailManageLabelCellDelegate {
    func didClickEditLabel(_ model: MailFilterLabelCellModel?) {}
    func didClickDeleteLabel(_ model: MailFilterLabelCellModel?) {}

    func didClickEditFolder(_ model: MailFilterLabelCellModel?) {
        /// show create label page
        let editFolderVC = MailCreateTagController(accountContext: accountContext)
        editFolderVC.scene = .editFolder
        editFolderVC.label = model
        editFolderVC.folderDelegate = self
        let tags = allLabels.filter({ $0.tagType == .folder || $0.isSystem })
        editFolderVC.loadLabels = tags
        editFolderVC.folderTree = FolderTree.build(tags)
        MailTracker.log(event: "email_folder_edit", params: [MailTracker.sourceParamKey(): MailTracker.source(type: .folderManage)])
        if #available(iOS 13.0, *) {
            editFolderVC.modalPresentationStyle = .overCurrentContext
            navigator?.present(LkNavigationController(rootViewController: editFolderVC), from: self)
        } else {
            if self.navigationController != nil {
                navigator?.push(editFolderVC, from: self)
            } else {
                self.delegate?.pushVC(editFolderVC)
            }
        }
    }

    func didClickDeleteFolder(_ model: MailFilterLabelCellModel?) {
        if let folderID = model?.labelId {
            if Store.settingData.mailClient {
                deleteFolderReq(folderID: folderID, folderName: model?.text ?? "")
            } else {
                let alert = LarkAlertController()
                let folderTree = FolderTree.build(labels)
                let hasSubFolder = folderTree.findChilds(folderID).count > 1
                alert.setContent(text: hasSubFolder ? BundleI18n.MailSDK.Mail_Folder_DeleteFolderDesc : BundleI18n.MailSDK.Mail_Folder_ConfirmDeleteWithoutSubfolders, alignment: .center)
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
                alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_CustomLabels_Remove, dismissCompletion: { [weak self] in
                    guard let `self` = self else { return }
                    self.deleteFolderReq(folderID: folderID, folderName: model?.text ?? "")
                })
                navigator?.present(alert, from: self)
            }
        }
    }

    func deleteFolderReq(folderID: String, folderName: String) {
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Folder_Deleting, on: self.view, disableUserInteraction: false)
        MailTracker.log(event: "email_folder_delete", params: [MailTracker.sourceParamKey(): MailTracker.source(type: .folderManage)])
        let event = MailAPMEvent.LabelManageAction()
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.action_type("delete"))
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.mailbox_type("folder"))
        event.markPostStart()
        MailManageFolderDataSource.default.deleteFolder(folderID: folderID).subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self else { return }
            if resp.sessionID.isEmpty || resp.sessionID == "0" {
                MailRoundedHUD.remove(on: self.view)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Folder_DeletedSuccessfully(folderName), on: self.view)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            } else {
                MailLogger.debug("[mail_folder] delete folder resp.sessionID: \(resp.sessionID)")
                self.sessionIDs.append(resp.sessionID)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            }
            event.postEnd()
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            MailLogger.debug("[mail_folder] delete folder error")
            MailRoundedHUD.remove(on: self.view)
            var needReportFail = false
            if error.mailErrorCode == MailErrorCode.migrationReject {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_Inbox_ActionFailed)
                alert.setContent(text: BundleI18n.MailSDK.Mail_Inbox_MigrationCannotExecuteAction, alignment: .center)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_CloseAnyway)
                self.navigator?.present(alert, from: self)
            } else if error.mailErrorCode == MailErrorCode.deleteFolderHasSubFolder {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToDelete)
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_DeleteFolderRetry, alignment: .center)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK)
                self.navigator?.present(alert, from: self)
            } else if error.mailErrorCode == MailErrorCode.deleteFolderHasEmail {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToDelete)
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_DeleteFolderMailRetry, alignment: .center)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK)
                self.navigator?.present(alert, from: self)
            } else {
                if Store.settingData.mailClient {
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_ServerError)
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK)
                    self.navigator?.present(alert, from: self)
                } else {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Folder_DeleteFailed, on: self.view,
                                               event: ToastErrorEvent(event: .folder_delete_custom_fail))
                    needReportFail = true
                }
            }
            if needReportFail {
                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            } else {
                /// 三方客户端厂商限制操作错误不上报
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            }
            event.postEnd()
        }).disposed(by: self.disposeBag)
    }
}

extension MailManageFolderController: MailCreateFolderTagDelegate {
    func didCreateNewFolder(labelId: String) {
        if accountContext.featureManager.open(.folderSort, openInMailClient: true) {
            upsetFolderID = labelId
        }
    }

    func didEditFolder(labelId: String) {
        if accountContext.featureManager.open(.folderSort, openInMailClient: true) {
            upsetFolderID = labelId
        }
    }

    func didCreateFolderAndDismiss(_ toast: String, create: Bool, moveTo: Bool, folder: MailFilterLabelCellModel) {
        if labels.isEmpty {
            return
        }
        if create && !Store.settingData.mailClient
            && !accountContext.featureManager.open(.folderSort, openInMailClient: true) {
            let indexPath = IndexPath(row: max(0, labels.count - 1), section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }

    func didEditFolderAndDismiss() {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToEdit)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK)
        navigator?.present(alert, from: self)
    }
}

extension MailManageFolderController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return view
    }
}
