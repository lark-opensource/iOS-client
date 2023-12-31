//
//  FreshnessSettingViewController.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/6/3.
//  


import SKFoundation
import SKUIKit
import SKResource
import SpaceInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignDialog
import UniverseDesignToast
import EENavigator
import RxSwift

struct FreshnessItem {
    var selected: Bool
    let freshStatus: FreshStatus
}

struct FreshSettingDependency {
    let freshInfo: FreshInfo
    let objToken: String
    let objType: DocsType
    var statisticParams: [String: Any]
}

final class FreshnessSettingViewController: FreshnessBaseViewController {

    weak var hostVC: UIViewController?

    private let dependency: FreshSettingDependency
    private var freshnessItems: [FreshnessItem] = []

    private lazy var checkboxListView: CheckBoxListView = CheckBoxListView()

    private lazy var clearButton: UIButton = {
        let button = UIButton()
        // 清除
        button.setTitle(BundleI18n.SKResource.Doc_Doc_ColorSelectClear,
                        withFontSize: 16,
                        fontWeight: .regular, colorsForStates: [
                            (UDColor.textTitle, .normal),
                            (UDColor.textDisabled, .disabled)
                        ])
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(clearFreshState), for: .touchUpInside)
        return button
    }()

    init(dependency: FreshSettingDependency) {
        self.dependency = dependency
        super.init()
        checkboxListView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("docFresh: freshnessSettingVC deinit")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupUI() {
        super.setupUI()
        headerView.setTitle(BundleI18n.SKResource.LarkCCM_CM_Verify_Validity_Title)
        titleLabel.text = BundleI18n.SKResource.LarkCCM_CM_Verify_Validity_Tooltip

        headerView.addSubview(clearButton)
        containerView.addSubview(headerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(checkboxListView)

        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(Layout.headerHeight)
        }
        clearButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerView.titleCenterY)
            make.right.equalToSuperview().inset(16)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        checkboxListView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(Layout.offset_16)
        }

        setupItems()
    }

    private func setupItems() {
        let currentStatus = self.dependency.freshInfo.freshStatus

        clearButton.isEnabled = currentStatus != .undecide

        freshnessItems = FreshStatus.allCases.compactMap {
            if $0 == .undecide || $0 == .maybeOutdated {
                return nil
            }
            let isSelected = ($0.rawValue == currentStatus.rawValue) ? true : false
            DocsLogger.debug("docFresh: isSelected: \(isSelected), current status: \(currentStatus)")
            return FreshnessItem(selected: isSelected, freshStatus: $0)
        }

        reloadCheckboxList()
    }

    private func reloadCheckboxList() {
        let subTitle = getFreshDueDate()
        let items = freshnessItems.map {
            var bttonTitle = ""
            if $0.freshStatus == .newest && !subTitle.isEmpty {
                // 修改按钮
                bttonTitle = BundleI18n.SKResource.Doc_Normal_PermissionModify
            }
            return CheckBoxListItem(selected: $0.selected,
                                    title: $0.freshStatus.name,
                                    subTitle: subTitle,
                                    buttonTitle: bttonTitle)
        }
        checkboxListView.reloadItems(items)
    }

    private func getFreshDueDate() -> String {
        guard dependency.freshInfo.freshStatus == .newest,
              let dueDate = dependency.freshInfo.deadlineTime,
              dueDate > 0 else {
            return ""
        }
        let dateFormat = DateFormatter().construct { it in
            it.dateFormat = "yyyy/MM/dd"
        }

        // 有效期至
        return BundleI18n.SKResource.LarkCCM_CM_Verify_ValidUntil2_Title + dateFormat.string(from: Date(timeIntervalSince1970: dueDate))
    }

    private func showDialog(item: FreshnessItem) {
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        config.style = .vertical
        let dialog = RotatableUDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_CM_Verify_Confirm_Title(item.freshStatus.name))
        if item.freshStatus != .outdated {
            dialog.setContent(text: BundleI18n.SKResource.LarkCCM_CM_Verify_Confirm_Text(item.freshStatus.name))
        }
        _ = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Normal_OK,
                             dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.updateFreshness(status: item.freshStatus) {
                let successTips = BundleI18n.SKResource.LarkCCM_CM_Verify_PeriodSet_Toast(item.freshStatus.name)
                UDToast.showSuccess(with: successTips, on: self.view.window ?? self.view)
                self.dismiss(animated: true)
            }
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        Navigator.shared.present(dialog, from: self, animated: true)
    }

    private func updateFreshness(status: FreshStatus, completion: (() -> Void)? = nil) {
        var newInfo = dependency.freshInfo
        newInfo.freshStatus = status
        FreshnessService.updateFreshStatus(info: newInfo,
                                           objToken: dependency.objToken,
                                           objType: dependency.objType)
        .observeOn(MainScheduler.instance)
        .subscribe {
            completion?()
        } onError: { error in
            DocsLogger.error("docFresh: update Faild \(error.localizedDescription)")
            UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_CM_Verify_Failed_Toast, on: self.view)
        }
        .disposed(by: disposeBag)
    }

    private func showSetValidTimeVC() {
        guard let hostVC = self.hostVC else { return }
        self.dismiss(animated: true) {
            let vc = FreshnessValidTimeViewContoller(dependency: self.dependency)
            vc.supportOrientations = hostVC.supportedInterfaceOrientations
            if hostVC.isMyWindowRegularSizeInPad {
                vc.modalPresentationStyle = .formSheet
                vc.transitioningDelegate = vc.panelFormSheetTransitioningDelegate
            } else {
                vc.modalPresentationStyle = .overFullScreen
                vc.transitioningDelegate = vc.panelTransitioningDelegate
            }
            Navigator.shared.present(vc, from: hostVC, animated: true)
        }
    }

    /// 清除时效性
    @objc private func clearFreshState() {
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        config.style = .vertical
        let dialog = RotatableUDDialog(config: config)
        // 文案：清除标记
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_CM_Verify_CancelLabel_Title)
        // 文案：确认后将取消xxx状态，读者将无法判断是否可以信任此文档
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_CM_Verify_CancelLabel_Description(dependency.freshInfo.freshStatus.name))
        _ = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Normal_OK,
                             dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.updateFreshness(status: .undecide) {
                let successTips = BundleI18n.SKResource.LarkCCM_CM_Verify_Canceled_Toast
                UDToast.showSuccess(with: successTips, on: self.view.window ?? self.view)
                self.dismiss(animated: true)
            }
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        Navigator.shared.present(dialog, from: self, animated: true)
    }

    private func reportClickEvent(item: FreshnessItem) {
        var params: [String: Any] = ["click": item.freshStatus.statisticValueForClickAction,
                                     "target": "none",
                                     "role": "up_edit"]
        params.merge(other: dependency.statisticParams)
        DocsTracker.newLog(enumEvent: .docfreshnessCardClick, parameters: params)
    }

}

extension FreshnessSettingViewController: CheckBoxListDelegate {
    func checkBoxList(didSelectRowAt index: Int) {
        guard index >= 0, index < freshnessItems.count else { return }
        let didClickItem = freshnessItems[index]
        
        if didClickItem.freshStatus == .outdated, dependency.freshInfo.freshStatus == .outdated {
            // 当前状态时已过期，点击已过期不响应
            return
        }
        
        if didClickItem.freshStatus == .newest {
            showSetValidTimeVC()
        } else {
            showDialog(item: didClickItem)
        }
        reportClickEvent(item: didClickItem)
    }

    func checkBoxListSubButtonDidClick() {
        // 修改有效期
        showSetValidTimeVC()
    }
}
