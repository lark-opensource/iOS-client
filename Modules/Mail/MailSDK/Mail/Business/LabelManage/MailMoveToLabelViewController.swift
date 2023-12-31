//
//  MailMoveToLabelViewController.swift
//  MailSDK
//
//  Created by majx on 2019/7/17.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import Homeric
import UniverseDesignButton
import LarkAlertController
import RustPB

class MailMoveToLabelViewController: MailBaseViewController, UITableViewDataSource,
                                     UITableViewDelegate {
    enum Scene {
        case moveToLabel
        case moveToFolder
    }

    let fromLabelId: String
    let threadIds: [String]
    var didMoveLabelCallback: ((MailFilterLabelCellModel, String, String) -> Void)?
    var spamAlertContent = SpamAlertContent()
    var ignoreUnauthorized: Bool = false
    private var disposeBag = DisposeBag()
    private var filterThreadLabels: [MailFilterLabelCellModel] = []
    private var allLabels: [MailFilterLabelCellModel] = []
    private var selectedLabel: MailFilterLabelCellModel?
    private var newLabelID: String?
    private var selectedIndexPath = IndexPath(row: -1, section: 0)
    var scene: Scene = .moveToLabel
    let accountContext: MailAccountContext
    weak var newFolderDelegate: MailMessageListExternalDelegate?
    var blockMoveToSuccessToast: Bool = false

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }

    init(threadIds: [String], fromLabelId: String, accountContext: MailAccountContext) {
        self.threadIds = threadIds
        self.fromLabelId = fromLabelId
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        getLabels()

        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(_):
                    self?.getLabels()
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }

    @objc
    func confirmHandler() {
        if let selectedLabel = selectedLabel {
            moveToLabel(selectedLabel)
        } else {
            dismissSelf()
        }
    }

    func reloadData() {
        asyncRunInMainThread {
            self.tableView.reloadData()
        }
    }

    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func cancel() {
        dismiss(animated: true, completion: nil)
    }

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_CustomLabels_MoveTo
        self.view.backgroundColor = ModelViewHelper.listColor()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()

        let createFolderButtonItem = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Manage_CreateMobile, fontStyle: .medium)
        createFolderButtonItem.button.tintColor = UIColor.ud.primaryContentDefault
        createFolderButtonItem.addTarget(self, action: #selector(didClickCreateLabelButton), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = createFolderButtonItem

        let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        cancelBtn.button.tintColor = UIColor.ud.textTitle
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = cancelBtn

        view.addSubview(tableView)
        let bottomOffset = Display.bottomSafeAreaHeight == 0 ? 24 : Display.bottomSafeAreaHeight
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomOffset)
        }
    }

    func getLabels(useNewLabel: Bool = false) {
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
            self.allLabels = labels
            var filterLabels = [MailFilterLabelCellModel]()
            if self.scene == .moveToLabel {
                filterLabels = labels.filter {
                    if $0.tagType == .folder {
                        return false
                    }
                    if $0.labelId == self.fromLabelId {
                        return false
                    }
                    if $0.labelId == Mail_LabelId_Inbox && smartInboxLabels.contains(self.fromLabelId) {
                        return false
                    }
                    if !$0.isSystem || self.targetSystemLabels.contains($0.labelId) {
                        return true
                    }
                    return false
                }
            } else {
                filterLabels = labels.filter {
                    if $0.tagType == .label && !self.targetLabelsForFolder.contains($0.labelId) {
                        return false
                    }
                    if $0.labelId == Mail_LabelId_Stranger {
                        return false
                    }
                    return true
                }
                var (system, other) = filterLabels.genSortedSystemAndOtherForMoveTo()
                system.append(contentsOf: other)
                filterLabels = system
            }
            for (index, tag) in filterLabels.enumerated() where self.fromLabelId == tag.labelId {
                self.selectedLabel = tag
                self.selectedIndexPath = IndexPath(row: index, section: 0)
            }
            self.filterThreadLabels = filterLabels
            if self.newLabelID != nil {
                for (index, label) in filterLabels.enumerated() where label.labelId == self.newLabelID {
                    self.selectedIndexPath = IndexPath(row: index, section: 0)
                    self.selectedLabel = label
                }
            }
            self.reloadData()
        }).disposed(by: disposeBag)
   }

    lazy var targetSystemLabels: [String] = {
        return [Mail_LabelId_Inbox, Mail_LabelId_FLAGGED, Mail_LabelId_Archived, Mail_LabelId_Trash, Mail_LabelId_Spam]
    }()
    var targetLabelsForFolder = {
        if FeatureManager.enableSystemFolder() {
            return [Mail_LabelId_Inbox,
                    Mail_LabelId_Archived,
                    Mail_LabelId_Sent,
                    Mail_LabelId_Draft,
                    Mail_LabelId_Trash,
                    Mail_LabelId_Spam]
        } else {
            return systemRootEnableMoveTo
        }
    }()

    private func moveToLabel(_ label: MailFilterLabelCellModel) {
        disposeBag = DisposeBag()
        var fromLabelId = self.fromLabelId
        if smartInboxLabels.contains(fromLabelId) {
            fromLabelId = Mail_LabelId_Inbox
        }
        var reportType: Email_Client_V1_ReportType? = nil
        if accountContext.featureManager.open(.newSpamPolicy)
            && (fromLabelId == Mail_LabelId_Spam || label.labelId == Mail_LabelId_Spam) {
            reportType = label.labelId == Mail_LabelId_Spam ? .moveIntoSpam : .moveOutofSpam
        }
        if scene == .moveToLabel {
            guard !Store.settingData.mailClient else { return }
            MailDataSource.shared.moveMultiLabelRequest(threadIds: self.threadIds,
                                                        fromLabel: fromLabelId,
                                                        toLabel: label.labelId,
                                                        ignoreUnauthorized: self.ignoreUnauthorized,
                                                        reportType: reportType)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.didMoveLabelCallback?(label, "", "")
                self.dismiss(animated: true) {
                    // success
                    if self.threadIds.count > 1 {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_MultiMoveToSucceed(self.threadIds.count, label.text), on: self.view)
                    } else {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_MoveToSucceed(label.text), on: self.view)
                    }
                }
            }, onError: { (error) in
                // error
                MailLogger.error("mail move to label error: \(error).")
                InteractiveErrorRecorder.recordError(event: .mail_lable_or_folder_move_fail)
            }).disposed(by: disposeBag)
        } else {
            MailLogger.debug("[mail_folder] moveToFolder fromLabelId: \(fromLabelId) toFolder: \(label.labelId)")
            if fromLabelId == label.labelId {
                dismissSelf()
                return
            }
            moveToFolder(label, fromLabelId: fromLabelId, reportType: reportType)
        }
    }

    func moveToFolder(_ label: MailFilterLabelCellModel, fromLabelId: String, reportType: Email_Client_V1_ReportType? = nil, newFolderToast: String = "") {
        let selfView: UIView = self.presentingViewController?.view ?? self.view
        MailDataSource.shared.moveToFolderRequest(threadIds: threadIds,
                                                  fromID: fromLabelId,
                                                  toFolder: label.labelId,
                                                  ignoreUnauthorized: self.ignoreUnauthorized,
                                                  reportType: reportType)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                if !newFolderToast.isEmpty {
                    /// Messagelist需要收到通知pop到首页（非当前folder）
                    self.dismiss(animated: true, completion: {
                        self.newFolderDelegate?.didMoveToNewFolder(toast: newFolderToast, undoInfo: (response.uuid, label.labelId))
                        self.didMoveLabelCallback?(label, newFolderToast, response.uuid)
                    })
                } else {
                    self.didMoveLabelCallback?(label, "", response.uuid)
                    self.dismiss(animated: true) {
                        if !self.blockMoveToSuccessToast {
                            MailRoundedHUD.remove(on: selfView)
                            // success
                            if self.threadIds.count > 1 {
                                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_MultiMoveToSucceed(self.threadIds.count, label.text), on: selfView)
                            } else {
                                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Folder_MovedTo(label.text), on: selfView)
                            }
                        }
                    }
                }
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            MailLogger.error("mail move to folder error: \(error).")
            MailRoundedHUD.remove(on: selfView)
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Folder_MoveFailed, on: selfView)
            InteractiveErrorRecorder.recordError(event: .mail_lable_or_folder_move_fail)
        }).disposed(by: disposeBag)
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.registerClass(MailEditLabelCell.self)
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.bounds = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 15)
        tableView.backgroundColor = ModelViewHelper.listColor()
        return tableView
    }()

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterThreadLabels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as MailEditLabelCell
        let label = filterThreadLabels[indexPath.row]
        var paddingCount: Int? = nil
        if FeatureManager.enableSystemFolder() { // 有奇怪的需求需要 @liutefeng
            let idNames = label.idNames.filter({
                if systemLabels.contains($0) && !systemRootEnableMoveTo.contains($0) { // 不是规定范围的systemLabelis要去掉
                    return false
                }
                return true
            })
            paddingCount = max(idNames.count - 1, 0)
        }
        cell.config(label, paddingCount: paddingCount)
        cell.hiddenOptionButton(true)
        if scene == .moveToFolder && label.isSystem {
            cell.labelIcon.tintColor = UIColor.ud.iconN1
        }
        cell.isSelected = (indexPath == selectedIndexPath)
        cell.hideSelectIcon = !cell.isSelected
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let label = filterThreadLabels[indexPath.row]

        if (label.labelId == Mail_LabelId_Spam || fromLabelId == Mail_LabelId_Spam) && selectedLabel != label {
            LarkAlertController.showSpamAlert(
                type: .conversationMoveToFolder(label.text, label.labelId),
                content: spamAlertContent,
                from: self,
                navigator: accountContext.navigator,
                userStore: accountContext.userKVStore
            ) { [weak self] ignore in
                self?.ignoreUnauthorized = ignore
                self?.didSelectLabel(label: label, indexPath: indexPath)
            }
        } else {
            didSelectLabel(label: label, indexPath: indexPath)
        }
    }

    private func didSelectLabel(label: MailFilterLabelCellModel, indexPath: IndexPath) {
        selectedLabel = label
        selectedIndexPath = indexPath
        self.newLabelID = nil
        tableView.reloadData()
        if selectedIndexPath.row != -1 {
            confirmHandler()
        }
    }

    // MARK: - MailEditLabelsBottomViewDelegate
    @objc
    func didClickCreateLabelButton() {
        let createLabelVC = MailCreateTagController(accountContext: accountContext)
        createLabelVC.delegate = self
        createLabelVC.folderDelegate = self
        createLabelVC.showSuccessToast = false
        createLabelVC.loadLabels = allLabels.filter({ $0.tagType == .label })
        createLabelVC.threadIds = threadIds
        createLabelVC.fromLabelId = fromLabelId
        createLabelVC.folderTree = FolderTree.build(allLabels)
        if scene == .moveToFolder {
            createLabelVC.scene = .newFolderAndMoveTo
            MailTracker.log(event: "email_folder_create_click", params: ["source": "mobile_moveto"])
        } else if scene == .moveToLabel {
            createLabelVC.scene = .newLabel
        }
        if #available(iOS 13.0, *) {
            createLabelVC.modalPresentationStyle = .automatic
            navigator?.present(LkNavigationController(rootViewController: createLabelVC), from: self)
        } else {
            navigator?.push(createLabelVC, from: self)
        }
    }
}

// MARK: - MailCreateLabelTagDelegate
extension MailMoveToLabelViewController: MailCreateLabelTagDelegate {
    func didCreateNewLabel(labelId: String) {
        self.newLabelID = labelId
        self.getLabels(useNewLabel: true)
    }

    func didCreateLabelAndDismiss(_ toast: String, create: Bool) {
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }
}

// MARK: - MailCreateFolderTagDelegate
extension MailMoveToLabelViewController: MailCreateFolderTagDelegate {
    func didCreateNewFolder(labelId: String) {
        self.newLabelID = labelId
        self.getLabels(useNewLabel: true)
    }

    func didEditFolder(labelId: String) {}

    func didCreateFolderAndDismiss(_ toast: String, create: Bool, moveTo: Bool, folder: MailFilterLabelCellModel) {
        if moveTo {
            /// 调用MoveTo接口
            var fromLabelId = self.fromLabelId
            if smartInboxLabels.contains(fromLabelId) {
                fromLabelId = Mail_LabelId_Inbox
            }
            moveToFolder(folder, fromLabelId: fromLabelId, newFolderToast: toast)
        } else {
            MailRoundedHUD.showSuccess(with: toast, on: self.view)
        }
    }

    func didEditFolderAndDismiss() {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToEdit)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK)
        navigator?.present(alert, from: self)
    }
}
