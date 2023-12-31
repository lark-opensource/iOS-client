//
//  FocusEditController.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import RustPB
import SnapKit
import RxSwift
import FigmaKit
import LarkUIKit
import EENavigator
import LarkContainer
import LarkRustClient
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkNavigator

final class FocusEditNoDescController: BaseUIViewController, UserResolverWrapper {

    @ScopedInjectedLazy private var focusManager: FocusManager?

    var onDeletingSuccess: ((UserFocusStatus, [Int64: UserFocusStatus]) -> Void)?
    var onUpdatingSuccess: ((UserFocusStatus) -> Void)?

    var changedFocusStatus: UserFocusStatus

    var originalFocusStatus: UserFocusStatus

    var focusTitleCell: FocusTitleCell

    private let disposeBag = DisposeBag()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver, focusStatus: UserFocusStatus) {
        self.userResolver = userResolver
        self.changedFocusStatus = focusStatus
        self.originalFocusStatus = focusStatus
        if originalFocusStatus.canEdit {
            self.focusTitleCell = EditableFocusTitleCell(userResolver: userResolver)
        } else {
            self.focusTitleCell = UneditableFocusTitleCell()
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let table = InsetTableView()
        table.delegate = self
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = UITableView.automaticDimension
        table.estimatedSectionHeaderHeight = UITableView.automaticDimension
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.register(cellWithClass: NormalSettingTableCell.self)
        table.register(cellWithClass: SwitchSettingTableCell.self)
        table.register(cellWithClass: ButtonSettingTableCell.self)
        table.register(cellWithClass: EditableFocusTitleCell.self)
        table.register(cellWithClass: UneditableFocusTitleCell.self)
        table.register(headerFooterViewClassWith: NormalSettingTableHeaderView.self)
        return table
    }()

    private lazy var saveButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkFocus.Lark_Profile_Save)
        item.setProperty(alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        item.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        item.button.titleLabel?.adjustsFontSizeToFitWidth = true
        item.addTarget(self, action: #selector(didTapUpdateButton), for: .touchUpInside)
        return item
    }()

    private lazy var cancelButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkFocus.Lark_Profile_Cancel)
        item.setProperty(alignment: .left)
        item.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        item.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        item.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        item.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.LarkFocus.Lark_Profile_ModifyStatus
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        setupNavigationButton()
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        focusTitleCell.iconKey = changedFocusStatus.iconKey
        focusTitleCell.focusName = changedFocusStatus.title
        changeSaveButtonState()
        (focusTitleCell as? EditableFocusTitleCell)?.onEditing = { [weak self] in
            self?.changeSaveButtonState()
        }
        (focusTitleCell as? EditableFocusTitleCell)?.onReachLimitation = { [weak self] in
            guard let self = self else { return }
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_CharactersLimit, on: self.view)
            // 上报名称长度超限事件
            FocusTracker.didShowStatusNameOutOfRangeToast()
        }
        navigationController?.presentationController?.delegate = self
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if Display.pad {
            self.preferredContentSize = CGSize(width: 540, height: 620)
            self.modalPresentationControl.dismissEnable = true
        }
        FocusTracker.didShowFocusDetailPage(pageType: .edit, status: originalFocusStatus)
    }

    private func changeSaveButtonState() {
        if focusTitleCell.focusName?.count ?? 0 > 0 {
            saveButton.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        } else {
            saveButton.button.setTitleColor(UIColor.ud.textDisabled, for: .normal)
        }
    }

    private func setupNavigationButton() {
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = cancelButton
    }

    @objc
    private func didTapUpdateButton() {
        // 名称不能为空
        guard let title = focusTitleCell.focusName, !title.isEmpty else {
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_StatusNameDesc, on: view)
            return
        }
        // 写入修改
        if let title = focusTitleCell.focusName {
            changedFocusStatus.title = title
        }
        if let iconKey = focusTitleCell.iconKey {
            changedFocusStatus.iconKey = iconKey
        }
        updateFocusStatus()
        FocusTracker.didTapSaveButtonOnDetailPage(
            pageType: .edit,
            status: changedFocusStatus
        )
    }

    @objc
    private func didTapDeleteButton(_ sender: UIView) {
        let source = UDActionSheetSource(
            sourceView: sender,
            sourceRect: sender.bounds,
            preferredContentWidth: 350,
            arrowDirection: .down
        )
        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        let deleteAlert = UDActionSheet(config: config)
        deleteAlert.setTitle(BundleI18n.LarkFocus.Lark_Profile_DeleteStatusDesc)
        deleteAlert.addDestructiveItem(text: BundleI18n.LarkFocus.Lark_Profile_DeleteStatus) { [weak self] in
            self?.deleteFocusStatus()
            FocusTracker.didTapConfirmButtonInDeletionAlert()
        }
        deleteAlert.setCancelItem(text: BundleI18n.LarkFocus.Lark_Profile_Cancel) {
            FocusTracker.didTapCancelButtonInDeletionAlert()
        }
        userResolver.navigator.present(deleteAlert, from: self)
        FocusTracker.didTapDeleteButtonInEditPage()
        FocusTracker.didShowDeletionAlert()
    }

    @objc
    private func didTapCancelButton() {
        (focusTitleCell as? EditableFocusTitleCell)?.resignFirstResponder()
        if hasUncommittedChanges() {
            showAbondonAlert()
        } else {
            dismiss(animated: true)
        }
        FocusTracker.didTapCancelButtonOnDetailPage(pageType: .edit, status: originalFocusStatus)
    }

    private func deleteFocusStatus() {
        (focusTitleCell as? EditableFocusTitleCell)?.resignFirstResponder()
        let loadingHUD = UDToast.showSavingLoading(on: self.view, disableUserInteraction: true)
        focusManager?.dataService.deleteFocusStatus(
            byID: originalFocusStatus.id,
            updateDataSourceImmediately: false,
            onSuccess: { [weak self] statusDic in
                loadingHUD.remove()
                guard let self = self else { return }
                self.dismiss(animated: true) {
                    self.onDeletingSuccess?(self.originalFocusStatus, statusDic)
                }
            }, onFailure: { [weak self] error in
                loadingHUD.remove()
                guard let self = self else { return }
                UDToast.autoDismissFailure(BundleI18n.LarkFocus.Lark_Profile_FailedSaveRetry, error: error, on: self.view)
            })
    }

    private func updateFocusStatus() {
        (focusTitleCell as? EditableFocusTitleCell)?.resignFirstResponder()
        // 如果没有更新直接关闭
        guard let updater = FocusStatusUpdater.assemble(old: originalFocusStatus, new: changedFocusStatus) else {
            dismiss(animated: true)
            return
        }
        let loadingHUD = UDToast.showSavingLoading(on: self.view, disableUserInteraction: true)

        focusManager?.dataService.updateFocusStatus(
            with: updater,
            onSuccess: { [weak self] newStatus in
                loadingHUD.remove()
                guard let self = self else { return }
                self.dismiss(animated: true) {
                    self.onUpdatingSuccess?(newStatus)
                }
            }, onFailure: { [weak self] _ in
                loadingHUD.remove()
                guard let self = self else { return }
                UDToast.autoDismissFailure(BundleI18n.LarkFocus.Lark_Profile_FailedSaveRetry, on: self.view)
            })

        // 上报名称的修改事件
        if updater.fields.contains(.title) {
            FocusTracker.didChangeStatusNameInDetailPage(pageType: .edit, status: changedFocusStatus)
        }
        // 上报图标的修改事件
        if updater.fields.contains(.iconKey) {
            FocusTracker.didChangeStatusIconInDetailPage(pageType: .edit, status: changedFocusStatus)
        }
    }

    // MARK: Data validation

    private func hasUncommittedChanges() -> Bool {
        if let iconKey = focusTitleCell.iconKey, !iconKey.isEmpty {
            changedFocusStatus.iconKey = iconKey
        }
        if let title = focusTitleCell.focusName, !title.isEmpty {
            changedFocusStatus.title = title
        }
        return FocusStatusUpdater.assemble(old: originalFocusStatus, new: changedFocusStatus) != nil
    }

    private func showAbondonAlert() {
        let source = UDActionSheetSource(
            sourceView: cancelButton.button,
            sourceRect: cancelButton.button.bounds,
            preferredContentWidth: 350,
            arrowDirection: .up
        )
        let cancelAlert = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        cancelAlert.setTitle(BundleI18n.LarkFocus.Lark_Profile_ExitEditDesc)
        cancelAlert.addDestructiveItem(text: BundleI18n.LarkFocus.Lark_Profile_Exit) { [weak self] in
            self?.dismiss(animated: true)
        }
        cancelAlert.setCancelItem(text: BundleI18n.LarkFocus.Lark_Profile_Cancel)
        userResolver.navigator.present(cancelAlert, from: self)
    }

    // MARK: DataSource & Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount: Int = 2   // 头部、消息通知
        if !changedFocusStatus.settingsV2.isEmpty {
            sectionCount += 1       // 同步设置
        }
        if changedFocusStatus.canEdit {
            sectionCount += 1       // 删除状态
        }
        return sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            // TODO: 之前默认的自定义状态没有同步设置，此处不应耦合，考虑改掉
            if changedFocusStatus.canEdit {
                return 1    // 删除按钮
            } else {
                return changedFocusStatus.settingsV2.count
            }
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        // 标题行
        case 0:
            let cell = self.focusTitleCell
            cell.iconKey = changedFocusStatus.iconKey
            cell.focusName = changedFocusStatus.title
            cell.clipsToBounds = false
            cell.layer.masksToBounds = false
            return cell
        // 开启通知静音
        case 1:
            let cell = tableView.dequeueReusableCell(withClass: SwitchSettingTableCell.self)
            cell.textLayout = .vertical
            cell.title = BundleI18n.LarkFocus.Lark_Profile_EnableMuteNotification
            cell.detail = BundleI18n.LarkFocus.Lark_Profile_MobNewStatusMuteNotification_Desc
            cell.isOn = changedFocusStatus.isNotDisturbMode
            cell.onSwitch = { [weak self] isOn in
                self?.changedFocusStatus.isNotDisturbMode = isOn
            }
            return cell
        case 2:
            if changedFocusStatus.canEdit {
                let cell = tableView.dequeueReusableCell(withClass: ButtonSettingTableCell.self)
                cell.style = .destructive
                cell.title = BundleI18n.LarkFocus.Lark_Profile_DeleteStatus
                cell.font = UIFont.ud.body0(.fixed)
                return cell
            } else {
                let syncSetting = changedFocusStatus.settingsV2[indexPath.row]
                let cell = tableView.dequeueReusableCell(withClass: SwitchSettingTableCell.self)
                cell.textLayout = .vertical
                cell.title = syncSetting.content
                cell.detail = syncSetting.explain
                cell.isOn = syncSetting.isOpen
                cell.onSwitch = { [weak self] isOn in
                    guard let self = self else { return }
                    self.changedFocusStatus.settingsV2[indexPath.row].isOpen = isOn
                }
                return cell
            }
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withClass: NormalSettingTableHeaderView.self)
        if section == 1 {
            header.title = BundleI18n.LarkFocus.Lark_Profile_MessageNotification
        } else if section == 2 {
            header.title = changedFocusStatus.canEdit ? nil : BundleI18n.LarkFocus.Lark_Profile_AutoOpen
        } else {
            header.title = nil
        }
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let deleteButton = tableView.cellForRow(at: indexPath) else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2, changedFocusStatus.canEdit {
            // 删除
            didTapDeleteButton(deleteButton)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 隐藏最后一行的分割线
        guard let cell = cell as? NormalSettingTableCell else { return }
        let numberOfRow = tableView.numberOfRows(inSection: indexPath.section)
        let isLastRowInSection = indexPath.row == numberOfRow - 1
        cell.setDividingLineHidden(isLastRowInSection)
    }
}

extension FocusEditNoDescController: UITableViewDataSource, UITableViewDelegate {
}

@available(iOS 13, *)
extension FocusEditNoDescController: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !hasUncommittedChanges()
    }

    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showAbondonAlert()
    }
}
