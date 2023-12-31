//
//  FocusCreationController.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import RxSwift
import FigmaKit
import LarkUIKit
import EENavigator
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkNavigator

public final class FocusCreationNoStatusDescController: BaseUIViewController, UserResolverWrapper {

    @ScopedInjectedLazy private var focusManager: FocusManager?

    /// 新状态创建成功的回调
    public var onCreatingSuccess: ((UserFocusStatus) -> Void)?

    private let disposeBag = DisposeBag()

    /// 用于在退出时和修改的数据做对比
    private lazy var newFocusStatus = makeNewFocusStatus()
    /// 用于保存修改的数据
    private lazy var changedFocusStatus = makeNewFocusStatus()

    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    public  let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeNewFocusStatus() -> UserFocusStatus {
        var focus = UserFocusStatus()
        focus.title = ""
        focus.iconKey = ""
        focus.isNotDisturbMode = false
        focus.type = .custom
        return focus
    }

    /// Header，获取保存 iconKey 和 title
    private lazy var focusTitleCell = EditableFocusTitleCell(userResolver: userResolver)

    private lazy var saveButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkFocus.Lark_Profile_Save)
        item.setProperty(alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        item.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        item.button.titleLabel?.adjustsFontSizeToFitWidth = true
        item.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
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
        table.register(cellWithClass: EditableFocusTitleCell.self)
        table.register(headerFooterViewClassWith: NormalSettingTableHeaderView.self)
        return table
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.LarkFocus.Lark_Profile_NewStatus
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        setupNavigationButton()
        changeSaveButtonState()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.focusTitleCell.becomeFirstResponder()
        }

        focusTitleCell.onEditing = { [weak self] in
            guard let self = self else { return }
            self.changeSaveButtonState()
        }
        focusTitleCell.onReachLimitation = { [weak self] in
            guard let self = self else { return }
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_CharactersLimit, on: self.view)
            // 上报名称长度超限事件
            FocusTracker.didShowStatusNameOutOfRangeToast()
        }
        navigationController?.presentationController?.delegate = self
        if Display.pad {
            self.preferredContentSize = CGSize(width: 540, height: 620)
            self.modalPresentationControl.dismissEnable = true
        }
        FocusTracker.didShowFocusDetailPage(pageType: .create, status: newFocusStatus)
    }

    private func changeSaveButtonState() {
        if focusTitleCell.currentTextCount > 0 {
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
    private func didTapSaveButton() {
        focusTitleCell.resignFirstResponder()
        // 名称不能为空
        guard focusTitleCell.currentTextCount > 0 else {
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_StatusNameDesc, on: view)
            return
        }

        changedFocusStatus.title = focusTitleCell.focusName ?? ""
        changedFocusStatus.iconKey = focusTitleCell.iconKey ?? ""

        var richText = FocusStatusDescRichText()
        // innerText 为 RichText 序列化，反序列化必备参数，需要传值
        richText.innerText = ""
        changedFocusStatus.statusDesc.richText = richText

        let loadingHUD = UDToast.showSavingLoading(on: self.view, disableUserInteraction: true)
        focusManager?.dataService.createFocusStatus(
            title: changedFocusStatus.title,
            iconKey: changedFocusStatus.iconKey,
            statusDescRichText: changedFocusStatus.statusDesc.richText,
            notDisturb: changedFocusStatus.isNotDisturbMode,
            updateDataSourceImmediately: false,
            onSuccess: { [weak self] newStatus in
                guard let self = self else { return }
                self.dismiss(animated: true) {
                    self.onCreatingSuccess?(newStatus)
                }
            }, onFailure: { [weak self] error in
                loadingHUD.remove()
                guard let self = self else { return }
                UDToast.autoDismissFailure(BundleI18n.LarkFocus.Lark_Profile_FailedSaveRetry, error: error, on: self.view)
            }
        )

        // 上报图标的修改事件，名称修改事件不上传
        if changedFocusStatus.iconKey != newFocusStatus.iconKey {
            FocusTracker.didChangeStatusIconInDetailPage(pageType: .create, status: .custom)
        }
        FocusTracker.didTapSaveButtonOnDetailPage(
            pageType: .create,
            status: changedFocusStatus
        )
    }

    @objc
    private func didTapCancelButton() {
        focusTitleCell.resignFirstResponder()
        if hasUncommittedChanges() {
            // 如果有未保存修改，二次确认后关闭
            showAbondonAlert()
        } else {
            // 如果没有修改，直接退出
            dismiss(animated: true)
        }
        FocusTracker.didTapCancelButtonOnDetailPage(pageType: .create, status: newFocusStatus)
    }

    // MARK: Data validation

    private func hasUncommittedChanges() -> Bool {
        if let iconKey = focusTitleCell.iconKey, !iconKey.isEmpty {
            changedFocusStatus.iconKey = iconKey
        }
        if let title = focusTitleCell.focusName, !title.isEmpty {
            changedFocusStatus.title = title
        }
        return changedFocusStatus != newFocusStatus
    }

    private func showAbondonAlert() {
        let source = UDActionSheetSource(
            sourceView: cancelButton.button,
            sourceRect: cancelButton.button.bounds,
            preferredContentWidth: 350,
            arrowDirection: .up
        )
        let abandonAlert = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        abandonAlert.setTitle(BundleI18n.LarkFocus.Lark_Profile_ExitEditDesc)
        abandonAlert.addDestructiveItem(text: BundleI18n.LarkFocus.Lark_Profile_Exit) { [weak self] in
            self?.dismiss(animated: true)
        }
        abandonAlert.setCancelItem(text: BundleI18n.LarkFocus.Lark_Profile_Cancel)
        userResolver.navigator.present(abandonAlert, from: self)
    }

    // MARK: DataSource & Delegate

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:     return 1
        case 1:     return 1
        default:    return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = focusTitleCell
            cell.iconKey = nil
            cell.focusName = nil
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withClass: SwitchSettingTableCell.self)
            cell.textLayout = .vertical
            cell.title = BundleI18n.LarkFocus.Lark_Profile_EnableMuteNotification
            cell.detail = BundleI18n.LarkFocus.Lark_Profile_MobNewStatusMuteNotification_Desc
            cell.isOn = false
            cell.onSwitch = { [weak self] isOn in
                self?.changedFocusStatus.isNotDisturbMode = isOn
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withClass: NormalSettingTableHeaderView.self)
        if section == 1 {
            header.title = BundleI18n.LarkFocus.Lark_Profile_MessageNotification
        }
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 隐藏最后一行的分割线
        guard let cell = cell as? NormalSettingTableCell else { return }
        let numberOfRow = tableView.numberOfRows(inSection: indexPath.section)
        let isLastRowInSection = indexPath.row == numberOfRow - 1
        cell.setDividingLineHidden(isLastRowInSection)
    }
}

extension FocusCreationNoStatusDescController: UITableViewDataSource, UITableViewDelegate {
}

@available(iOS 13, *)
extension FocusCreationNoStatusDescController: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !hasUncommittedChanges()
    }

    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showAbondonAlert()
    }
}
