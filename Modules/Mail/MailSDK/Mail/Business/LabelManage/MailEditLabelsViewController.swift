//
//  MailEditLabelsViewController.swift
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

enum MailEditLabelsScene {
    case msgList
    case searchMulti
    case homeMulti
    case homeSwipeAction
}

protocol MultiSelectTagDelegate: AnyObject {
    func changeLables(addLabels: [String], deleteLabels: [String], toast: String, scene: MailEditLabelsScene)
}

protocol MailEditLabelsDelegate: AnyObject {
    func showEditLabelToast(_ toast: String, uuid: String)
}

class MailEditLabelsViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    let mailItem: MailItem
    let threadId: String
    let fromLabel: String
    var scene: MailEditLabelsScene = .msgList

    var multiSelectFlag: Bool = false
    weak var multiSelectDelegate: MultiSelectTagDelegate?
    weak var editLabelDelegate: MailEditLabelsDelegate?
    var currentLabelRemoveHandler: (() -> Void)?
    var dismissCompletionHandler: ((String) -> Void)?

    private let disposeBag = DisposeBag()
    /// all custom labels (filtered system labels)
    var filterThreadLabels: [MailFilterLabelCellModel] = []
    var allLabels: [MailFilterLabelCellModel] = []
    private let originSelectedLabels: OrderSet<MailFilterLabelCellModel>
    private var selectedLabels = OrderSet<MailFilterLabelCellModel>()
    private var originSemiSelectedLabels = OrderSet<MailFilterLabelCellModel>()
    private var semiSelectedLabels = OrderSet<MailFilterLabelCellModel>()
    /// if create a new label, should selected the label
    private var newLabelID: String?

    private lazy var confirmButton: UDButton = {
        let config = UDButtonUIConifg.primaryBlue
        let confirmButton = UDButton(config)
        confirmButton.setTitle(BundleI18n.MailSDK.Mail_Common_Confirm, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        confirmButton.addTarget(self, action: #selector(confirmButtonHandler), for: .touchUpInside)
        confirmButton.layer.cornerRadius = 10
        confirmButton.layer.masksToBounds = true
        return confirmButton
    }()

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }
    

    
    let accountContext: MailAccountContext

    init(mailItem: MailItem, threadLabels: [MailFilterLabelCellModel], threadId: String, fromLabel: String, accountContext: MailAccountContext) {
        self.mailItem = mailItem
        self.threadId = threadId
        self.fromLabel = fromLabel
        self.selectedLabels = OrderSet(threadLabels)
        self.originSelectedLabels = OrderSet(threadLabels)
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    init(threadLabels: [MailFilterLabelCellModel], semiSelectedLabels: [MailFilterLabelCellModel], threadId: String, fromLabel: String, accountContext: MailAccountContext) {
        self.mailItem = MailItem(threadId: "", messageItems: [], composeDrafts: [], labels: [], code: .none, isExternal: false, isFlagged: false, isRead: false, isLastPage: true)
        self.threadId = threadId
        self.fromLabel = fromLabel
        self.selectedLabels = OrderSet(threadLabels)
        self.originSelectedLabels = OrderSet(threadLabels)
        self.semiSelectedLabels = OrderSet(semiSelectedLabels)
        self.originSemiSelectedLabels = OrderSet(semiSelectedLabels)
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
    func cancel() {
        dismiss(animated: true, completion: nil)
    }

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_CustomLabels_LabelAs
        self.view.backgroundColor = ModelViewHelper.listColor()
        updateNavAppearanceIfNeeded()

        if !Store.settingData.mailClient {
            let createBtn = UIButton(type: .custom)
            createBtn.addTarget(self, action: #selector(createLabelHandler), for: .touchUpInside)
            createBtn.setTitle(BundleI18n.MailSDK.Mail_Manage_CreateMobile, for: .normal)
            createBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            createBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            createBtn.setTitleColor(UIColor.ud.primaryContentPressed, for: .highlighted)
            createBtn.setTitleColor(UIColor.ud.primaryFillSolid03, for: .disabled)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createBtn)
        }

        let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        cancelBtn.button.tintColor = UIColor.ud.textTitle
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = cancelBtn

        view.addSubview(tableView)
        var bottomOffset = (Display.bottomSafeAreaHeight == 0 ? 24 : Display.bottomSafeAreaHeight) + 16
        if Display.pad {
            bottomOffset = 24
        }
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
    func createLabelHandler() {
        let createLabelVC = MailCreateTagController(accountContext: accountContext)
        createLabelVC.delegate = self
        createLabelVC.loadLabels = allLabels.filter({ $0.tagType == .label })
        createLabelVC.folderTree = FolderTree.build(allLabels)
        if #available(iOS 13.0, *) {
            createLabelVC.modalPresentationStyle = .overCurrentContext
            navigator?.present(LkNavigationController(rootViewController: createLabelVC), from: self)
        } else {
            navigator?.push(createLabelVC, from: self)
        }
    }

    func diffLabelIds() -> ([String], [String]) {
        let currentSelectedLabelIds = selectedLabels.map { $0.labelId }
        let originSelectedLabelIds = originSelectedLabels.map { $0.labelId }
        let diffSelectedLabelIds = currentSelectedLabelIds.filter {
            originSelectedLabelIds.contains($0) == false
        }

        let diffDeleteLabelIds = originSelectedLabelIds.filter {
            currentSelectedLabelIds.contains($0) == false
        }

        return (diffSelectedLabelIds.elements, diffDeleteLabelIds.elements)
    }

    func multiSelectDiffLabelIds() -> ([String], [String]) {

        let currentSelectedLabelIds = selectedLabels.map { $0.labelId }
        let originSelectedLabelIds = originSelectedLabels.map { $0.labelId }
        let currentSemiSelectedLabelIds = semiSelectedLabels.map { $0.labelId }
        let originSemiSelectedLabelIds = originSemiSelectedLabels.map { $0.labelId }
        let diffSelectedLabelIds = currentSelectedLabelIds.filter {
            originSelectedLabelIds.contains($0) == false
        }

        var diffDeleteLabelIds = originSelectedLabelIds.filter {
            currentSelectedLabelIds.contains($0) == false
        }
        // 中间态有两种变化可能，currentSemiSelectedLabelIds中包含则无变化,
        // 若全选会出现在selectedLabels, 反选则会从semiSelectedLabels中i移除
        let diffSemiCheckedDeleteLabelIds = originSemiSelectedLabelIds.filter {
            currentSemiSelectedLabelIds.contains($0) == false && currentSelectedLabelIds.contains($0) == false
        }
        diffDeleteLabelIds = diffDeleteLabelIds + diffSemiCheckedDeleteLabelIds

        return (diffSelectedLabelIds.elements, diffDeleteLabelIds.elements)
    }

    func getLabels() {
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
            var newLabel: MailFilterLabelCellModel?
            self.allLabels = labels
            let labels = labels.filter {
                if $0.labelId == self.newLabelID {
                    newLabel = $0
                }
                if $0.isSystem || $0.tagType == .folder {
                    return false
                }
                return true
            }

            // 要做一次颜色值的映射逻辑替换
            let newLabels = labels.map({ label -> MailFilterLabelCellModel in
                var newLabel = label
                let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColorHex ?? "")
                newLabel.fontColor = config.fontColor
                newLabel.bgColor = config.backgroundColor
                newLabel.colorType = config.colorType
                return newLabel
            })

            asyncRunInMainThread {
                self.filterThreadLabels = newLabels
                if let newLabel = newLabel {
                    self.selectedLabels.insert(newLabel)
                }
                self.tableView.reloadData()
                let count = self.filterThreadLabels.count
                if count > 0, self.newLabelID != nil {
                    self.tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: true)
                }
                self.newLabelID = nil
            }
        }).disposed(by: disposeBag)
   }

    @objc
    func confirmButtonHandler() {
        var haveChange = false
        var diffDeleteCount = 0
        var diffDeleteLabelIds: [String] = []
        if multiSelectFlag {
            let diffLabelIdsTuple: ([String], [String]) = multiSelectDiffLabelIds()
            let diffSelectedLabelIds = diffLabelIdsTuple.0
            let diffDeleteLabelIds = diffLabelIdsTuple.1
            diffDeleteCount = diffDeleteLabelIds.count
            let originCount = self.originSelectedLabels.filter({ !$0.isSystem }).count
            let selectedCount = self.selectedLabels.filter({ !$0.isSystem }).count
            let toastString = self.showMultiThreadChangeToast(originalLabelCount: originCount,
                                                              finalSelectedLabelCount: selectedCount,
                                                              removeLabelCount: diffDeleteCount)
            multiSelectDelegate?.changeLables(addLabels: diffSelectedLabelIds,
                                              deleteLabels: diffDeleteLabelIds, toast: toastString, scene: scene)
        } else {
            let diffLabelIdsTuple: ([String], [String]) = diffLabelIds()
            let diffSelectedLabelIds = diffLabelIdsTuple.0
            diffDeleteLabelIds = diffLabelIdsTuple.1
            diffDeleteCount = diffDeleteLabelIds.count

            if diffSelectedLabelIds.count > 0 {
                haveChange = true
                MailTracker.log(event: Homeric.EMAIL_THREAD_ADDLABEL,
                                params: [MailTracker.isMultiselectParamKey(): false,
                                         MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
            }
            if diffDeleteLabelIds.count > 0 {
                haveChange = true
                MailTracker.log(event: Homeric.EMAIL_THREAD_DELETELABEL,
                                params: [MailTracker.isMultiselectParamKey(): false,
                                         MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
            }
            if diffDeleteLabelIds.contains(self.fromLabel) {
                currentLabelRemoveHandler?()
            }
            MailDataSource.shared.multiMutLabelForThread(threadIds: [threadId],
                                                         addLabelIds: diffSelectedLabelIds,
                                                         removeLabelIds: diffDeleteLabelIds,
                                                         fromLabelID: fromLabel) // 传入folderid
                .subscribe(onNext: { [weak self] response in
                    guard let `self` = self else { return }
                    MailLogger.info("mail change labels - add \(diffSelectedLabelIds.count) | remove \(diffDeleteLabelIds.count)")
                    if self.scene == .homeSwipeAction {
                        self.editLabelDelegate?.showEditLabelToast(self.threadChangeToast(), uuid: response.uuid)
                    }
                }).disposed(by: disposeBag)
        }

        dismiss(animated: true) { [weak self] in
            guard let `self` = self else { return }
            if !haveChange || self.multiSelectFlag || self.scene == .homeSwipeAction {
                return
            }
            self.editLabelDelegate?.showEditLabelToast(self.threadChangeToast(), uuid: "")
            if diffDeleteLabelIds.contains(self.fromLabel) {
                self.dismissCompletionHandler?(self.threadChangeToast())
            }
        }
    }

    func threadChangeToast() -> String {
        var toastString = ""
        let originCount = self.originSelectedLabels.filter({ !$0.isSystem }).count
        let selectedCount = self.selectedLabels.filter({ !$0.isSystem }).count
        toastString = self.showThreadChangeToast(originalLabelCount: originCount, finalSelectedLabelCount: selectedCount)
        return toastString
    }

    func showThreadChangeToast(originalLabelCount: Int, finalSelectedLabelCount: Int) -> String {
        var toastString = ""
        if finalSelectedLabelCount == 0 && originalLabelCount > 0 {
            toastString = BundleI18n.MailSDK.Mail_Toast_RemoveLabelSuccess
        } else if finalSelectedLabelCount > originalLabelCount {
            toastString = BundleI18n.MailSDK.Mail_Toast_AddLabelSuccess
        } else {
            toastString = BundleI18n.MailSDK.Mail_Toast_ModifyLabelSuccess
        }
        return toastString
    }

    func showMultiThreadChangeToast(originalLabelCount: Int, finalSelectedLabelCount: Int, removeLabelCount: Int) -> String {
        print("toastString originalLabelCount: \(originalLabelCount) finalSelectedLabelCount: \(finalSelectedLabelCount) removeLabelCount: \(removeLabelCount)")
        var toastString = ""
        if (finalSelectedLabelCount == 0 && self.semiSelectedLabels.filter({ !$0.isSystem }).count == 0 &&
                (originalLabelCount > 0 || self.originSemiSelectedLabels.filter({ !$0.isSystem }).count > 0)) {
            toastString = BundleI18n.MailSDK.Mail_Toast_RemoveLabelSuccess
        } else if finalSelectedLabelCount > originalLabelCount {
            if removeLabelCount > 0 {
                toastString = BundleI18n.MailSDK.Mail_Toast_ModifyLabelSuccess
            } else {
                toastString = BundleI18n.MailSDK.Mail_Toast_AddLabelSuccess
            }
        } else {
            toastString = BundleI18n.MailSDK.Mail_Toast_ModifyLabelSuccess
        }
        return toastString
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

    // MARK: - TableView UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterThreadLabels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as MailEditLabelCell
        let label = filterThreadLabels[indexPath.row]
        cell.config(label)
        if selectedLabels.contains(where: { $0.labelId == label.labelId }) {
            cell.status = .checked
        } else if semiSelectedLabels.contains(where: { $0.labelId == label.labelId }) {
            cell.status = .semiChecked
        } else {
            cell.status = .uncheck
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let label = filterThreadLabels[indexPath.row]
        if originSemiSelectedLabels.contains(where: { $0.labelId == label.labelId }) {
            if let cell = tableView.cellForRow(at: indexPath) as? MailEditLabelCell {
                cell.status = updateEditCellStatus(cell.status)
                switch cell.status {
                case .uncheck:
                    semiSelectedLabels = semiSelectedLabels.filter { $0.labelId != label.labelId }
                    selectedLabels = selectedLabels.filter { $0.labelId != label.labelId }
                case .semiChecked:
                    semiSelectedLabels.insert(label)
                    selectedLabels = selectedLabels.filter { $0.labelId != label.labelId }
                case .checked:
                    semiSelectedLabels = semiSelectedLabels.filter { $0.labelId != label.labelId }
                    selectedLabels.insert(label)
                }
            }
        } else {
            if selectedLabels.contains(where: { $0.labelId == label.labelId }) {
                selectedLabels = selectedLabels.filter { $0.labelId != label.labelId }
            } else {
                selectedLabels.insert(label)
            }
            if let cell = tableView.cellForRow(at: indexPath) as? MailEditLabelCell {
                cell.status = updateEditCellStatusForAll(cell.status)
            }
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    private func updateEditCellStatus(_ status: MailEditLabelCell.EditLabelStatus) -> MailEditLabelCell.EditLabelStatus {
        var newStatus: MailEditLabelCell.EditLabelStatus = .uncheck
        switch status {
        case .uncheck:
            newStatus = .semiChecked
        case .semiChecked:
            newStatus = .checked
        case .checked:
            newStatus = .uncheck
        }
        return newStatus
    }

    private func updateEditCellStatusForAll(_ status: MailEditLabelCell.EditLabelStatus) -> MailEditLabelCell.EditLabelStatus {
        var newStatus: MailEditLabelCell.EditLabelStatus = .uncheck
        switch status {
        case .uncheck:
            newStatus = .checked
        case .semiChecked:
            newStatus = .checked // 理论上不会走到这里
        case .checked:
            newStatus = .uncheck
        }
        return newStatus
    }
}

// MARK: - Mail
extension MailEditLabelsViewController: MailCreateLabelTagDelegate {
    /// if create a new label, refresh the list, and selected new label
    func didCreateNewLabel(labelId: String) {
        self.newLabelID = labelId
    }
    func didCreateLabelAndDismiss(_ toast: String, create: Bool) {
        if filterThreadLabels.isEmpty {
            return
        }
        if create {
            let indexPath = IndexPath(row: max(0, filterThreadLabels.count - 1), section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }
}
