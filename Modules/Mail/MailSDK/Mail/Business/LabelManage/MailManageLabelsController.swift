//
//  MailManageLabelsController.swift
//  MailSDK
//
//  Created by majx on 2019/10/28.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkAlertController
import Homeric
import UniverseDesignTabs
import UniverseDesignButton

class MailManageLabelsController: MailBaseViewController, UITableViewDataSource,
                                  UITableViewDelegate, MailManageEmptyCellDelegate,
                                  MailManageLabelCellDelegate {
    enum Scene {
        case editLabel
        case setting
    }

    // MARK: - Property
    private let disposeBag = DisposeBag()
    var labels: [MailFilterLabelCellModel] = []
    var allLabels: [MailFilterLabelCellModel] = []
    var scene: Scene = .editLabel
    weak var delegate: MailManageTagNavigateDelegate?
    private var showCreateButton: Bool = false

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }
    
    let accountContext: MailAccountContext

    init(accountContext: MailAccountContext, showCreateButton: Bool = false) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
        self.showCreateButton = showCreateButton
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
        setupCreateButtonIfNeeded()
        /// if received label change log, refresh all labels
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MailRoundedHUD.remove(on: self.view)
    }

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_CustomLabels_ManageLabels
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

    func setupCreateButtonIfNeeded() {
        if !showCreateButton {
            return
        }
        // 备注：使用原生组件 UIBarButtonItem 需要设置字体（如下面第2行所示），不然会应用不到 Lark Circular 字体
        // 建议使用 LkBarButtonItem 组件，这里不改是因为颜色不敢动
        let saveBtn = UIBarButtonItem(title: BundleI18n.MailSDK.Mail_Manage_CreateMobile, style: .plain, target: self, action: #selector(didClickCreateLabelButton))
        saveBtn.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        saveBtn.setTitleTextAttributes([.foregroundColor: UIColor.ud.primaryContentDefault], for: .normal)
        saveBtn.setTitleTextAttributes([.foregroundColor: UIColor.ud.primaryContentPressed], for: .highlighted)
        saveBtn.setTitleTextAttributes([.foregroundColor: UIColor.ud.primaryFillSolid03], for: .disabled)
        navigationItem.rightBarButtonItem = saveBtn
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
        tableView.tableFooterView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 0.01)
        tableView.backgroundColor = ModelViewHelper.listColor()
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    private lazy var confirmButton: UIButton = {
        let confirmButton = UIButton(type: .custom)
        confirmButton.layer.cornerRadius = 10
        confirmButton.layer.masksToBounds = true
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        confirmButton.setTitle(BundleI18n.MailSDK.Mail_Label_NewLabel_Button, for: .normal)
        confirmButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault), for: .normal)
        confirmButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillDisabled), for: .disabled)
//        confirmButton.addTarget(self, action: #selector(didClickCreateLabelButton), for: .touchUpInside)
        confirmButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.didClickCreateLabelButton()
        }).disposed(by: disposeBag)
        return confirmButton
    }()

    // MARK: - Actions
    func getLabels() {
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
            self.allLabels = labels
            var managelabels: [MailFilterLabelCellModel] = []
            managelabels = labels.filter { $0.isSystem == false && $0.tagType == .label && ($0.mailClientType == .larkMail || $0.mailClientType == .googleMail) }
            asyncRunInMainThread {
                self.labels = managelabels
                self.tableView.reloadData()
            }
        }).disposed(by: disposeBag)
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
            let cell = tableView.dequeueReusableCell(for: indexPath) as MailManageLabelEmptyCell
            cell.config(.label)
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(for: indexPath) as MailManageLabelCell
            let label = labels[indexPath.row]
            cell.delegate = self
            cell.config(label)
            cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelManageCellKey + "\(indexPath.row)"
            return cell
        }
    }

//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//   guard tableView.cellForRow(at: indexPath) != nil else { return }
//        if labels.isEmpty {
//            didClickCreateLabel()
//        }
//    }
    // MARK: - MailManageEmptyCellDelegate
    func didClickCreateFolder() {}

    func didClickCreateLabel() {
        let createLabelVC = MailCreateTagController(accountContext: accountContext)
        createLabelVC.scene = .newLabel
        createLabelVC.delegate = self
        createLabelVC.loadLabels = allLabels.filter({ $0.tagType == .label })
        if #available(iOS 13.0, *) {
            createLabelVC.modalPresentationStyle = .overCurrentContext
            navigator?.present(LkNavigationController(rootViewController: createLabelVC), from: self)
        } else {
            if self.navigationController != nil {
                navigator?.push(createLabelVC, from: self)
            } else {
                self.delegate?.pushVC(createLabelVC)
            }
        }
    }

    // MARK: - MailManageLabelCellDelegate
    func didClickEditLabel(_ model: MailFilterLabelCellModel?) {
        /// show create label page
        let editLabelVC = MailCreateTagController(accountContext: accountContext)
        editLabelVC.scene = .editLabel
        editLabelVC.delegate = self
        editLabelVC.label = model
        editLabelVC.loadLabels = allLabels.filter({ $0.tagType == .label })
        if #available(iOS 13.0, *) {
            editLabelVC.modalPresentationStyle = .overCurrentContext
            navigator?.present(LkNavigationController(rootViewController: editLabelVC), from: self)
        } else {
            if self.navigationController != nil {
                navigator?.push(editLabelVC, from: self)
            } else {
                self.delegate?.pushVC(editLabelVC)
            }
        }
    }

    func didClickDeleteLabel(_ model: MailFilterLabelCellModel?) {
        /// before delete the label, need to show alert
        if let labelId = model?.labelId {
            let labelName = model?.text ?? ""
            let alert = LarkAlertController()
            var text = BundleI18n.MailSDK.Mail_CustomLabels_Remove_Label_Confirmation_Empty(labelName)
            let hasChild = labels.contains { $0.parentID == labelId }
            if hasChild {
                text = BundleI18n.MailSDK.Mail_CustomLabels_DeleteWithChildren(labelName)
            }
            alert.setContent(text: text, alignment: .center)
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
            let event = createApmEvent(action: "delete")
            alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_CustomLabels_Remove, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                MailRoundedHUD.showLoading(on: self.view, disableUserInteraction: false)
                MailTracker.log(event: Homeric.EMAIL_LABEL_DELETE, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
                MailManageLabelsDataSource.default.deleteLabel(labelId: labelId).subscribe(onNext: { [weak self](_) in
                    guard let `self` = self else { return }
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_CustomLabels_Delete_Label_Notification(labelName), on: self.view)
                    self.getLabels()
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                    event.postEnd()
                }, onError: { [weak self] error in
                guard let `self` = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Label_DeleteFailed, on: self.view,
                                               event: ToastErrorEvent(event: .label_delete_custom_fail))
                    event.endParams.appendError(error: error)
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                    event.postEnd()
                }).disposed(by: self.disposeBag)
            })
            navigator?.present(alert, from: self)
        }
    }

    func didClickEditFolder(_ model: MailFilterLabelCellModel?) {}
    func didClickDeleteFolder(_ model: MailFilterLabelCellModel?) {}

    // MARK: - MailEditLabelsBottomViewDelegate
    @objc
    func didClickCreateLabelButton() {
        didClickCreateLabel()
    }
}

extension MailManageLabelsController: MailCreateLabelTagDelegate {
    /// if create a new label, refresh the list, and selected new label
    func didCreateNewLabel(labelId: String) {
        // do nothing

    }
    func didCreateLabelAndDismiss(_ toast: String, create: Bool) {
        if labels.isEmpty {
            return
        }
        if create {
            let indexPath = IndexPath(row: max(0, labels.count - 1), section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }
}

extension MailManageLabelsController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return view
    }
}

extension MailManageLabelsController {
    func createApmEvent(action: String) -> MailAPMEvent.LabelManageAction {
        let event = MailAPMEvent.LabelManageAction()
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.action_type(action))
        event.endParams.append(MailAPMEvent.LabelManageAction.EndParam.mailbox_type("label"))
        event.markPostStart()
        return event
    }
}
