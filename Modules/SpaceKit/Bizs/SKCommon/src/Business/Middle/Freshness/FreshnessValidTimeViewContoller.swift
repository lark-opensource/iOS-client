//
//  FreshnessValidTimeViewContoller.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/7.
//  

import SKFoundation
import SKUIKit
import SKResource
import SpaceInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignDatePicker
import EENavigator
import RxSwift
import RxRelay

final class FreshnessValidTimeViewContoller: FreshnessBaseViewController {

    enum ValidTimeOption: Equatable {
        case dueDay(num: Int)
        case custom(date: Date)

        var title: String {
            switch self {
            case .dueDay(let num):
                // xx天
                return BundleI18n.SKResource.LarkCCM_CM_Verify_ValidityPeriod_Days_Option(num)
            case .custom:
                // 自定义
                return BundleI18n.SKResource.LarkCCM_CM_Verify_ValidityPeriod_Custom_Option
            }
        }

        var dueDateString: String {
            let theDate: Date
            switch self {
            case .dueDay(let num):
                theDate = Date.sk.otherDay(num)
            case .custom(let date):
                theDate = date
            }
            let dateFormat = DateFormatter().construct { it in
                it.dateFormat = "yyyy/MM/dd"
            }
            return "\(BundleI18n.SKResource.LarkCCM_CM_Verify_ValidUntil2_Title) \(dateFormat.string(from: theDate))"
        }

        var dueDate: TimeInterval {
            switch self {
            case .dueDay(let num):
                return Date.sk.otherDay(num).timeIntervalSince1970
            case .custom(let date):
                return date.timeIntervalSince1970
            }
        }

        static func == (lhs: ValidTimeOption, rhs: ValidTimeOption) -> Bool {
            switch (lhs, rhs) {
            case (.dueDay, .custom):
                return false
            case (.dueDay(let num1), .dueDay(let num2)):
                return num1 == num2
            case (.custom, .custom):
                return true
            default:
                return false
            }
        }
    }

    private var currentSelectOption: ValidTimeOption?
    private lazy var timeOptions: [ValidTimeOption] = {
        var options = [7, 30, 90, 180, 365].map { ValidTimeOption.dueDay(num: $0) }
        options.append(ValidTimeOption.custom(date: Date.sk.tomorrow()))
        return options
    }()
    
    private var confirmButtonEnableRelay = BehaviorRelay<Bool>(value: true)

    private lazy var checkboxListView: CheckBoxListView = CheckBoxListView()

    private let dependency: FreshSettingDependency

    init(dependency: FreshSettingDependency) {
        self.dependency = dependency
        super.init()
        currentSelectOption = .dueDay(num: 90)
        reloadCheckboxList(selectedIndex: 2) // 默认选中90天

        self.checkboxListView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("docFresh: FreshnessValidTimeVC deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupUI() {
        super.setupUI()

        let headerTitle = BundleI18n.SKResource.LarkCCM_CM_Verify_Confirm_Title(FreshStatus.newest.name)
        headerView.setTitle(headerTitle)

        let descTitle: String
        switch dependency.freshInfo.freshStatus {
        case .maybeOutdated:
            // 文案会有反馈过期的用户收到通知的信息
            descTitle = BundleI18n.SKResource.LarkCCM_CM_Verify_MarkAsUpdated_NotifyAndSetPeriod_Descrip(FreshStatus.newest.name)
        case .undecide, .outdated, .newest:
            descTitle = BundleI18n.SKResource.LarkCCM_CM_Verify_SetPeriod_Text(FreshStatus.newest.name)
        }
        titleLabel.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        titleLabel.attributedText = NSMutableAttributedString(string: descTitle, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])

        confirmButton.setTitle(BundleI18n.SKResource.Doc_Normal_OK, for: .normal)
        confirmButton.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        confirmButtonEnableRelay.distinctUntilChanged().bind(to: confirmButton.rx.isEnabled).disposed(by: disposeBag)

        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(Layout.headerHeight)
        }
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        containerView.addSubview(checkboxListView)
        checkboxListView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
        }
        containerView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(checkboxListView.snp.bottom).offset(Layout.offset_24)
            make.left.equalToSuperview().offset(Layout.offset_16)
            make.height.equalTo(Layout.buttonHeight_40)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(Layout.offset_16)
        }
        containerView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.centerY.equalTo(cancelButton.snp.centerY)
            make.left.equalTo(cancelButton.snp.right).offset(13)
            make.right.equalToSuperview().offset(-Layout.offset_16)
            make.width.height.equalTo(cancelButton)
        }
    }

    @objc
    private func didClickConfirm() {
        updateFreshness()
    }

    private func showDatePicker(date: Date, completion: @escaping ((Date) -> Void)) {
        let vc = FreshnessDatePickerViewController(date: date)
        vc.supportOrientations = self.supportedInterfaceOrientations
        vc.didClickCompletion = completion
        if SKDisplay.pad, self.isMyWindowRegularSize() {
            vc.modalPresentationStyle = .formSheet
            vc.transitioningDelegate = vc.panelFormSheetTransitioningDelegate
        } else {
            vc.modalPresentationStyle = .overFullScreen
            vc.transitioningDelegate = vc.panelTransitioningDelegate
        }
        Navigator.shared.present(vc, from: self, animated: true)
    }

    private func updateFreshness() {
        guard let selectedOption = currentSelectOption else { return }
        var newInfo = dependency.freshInfo
        newInfo.deadlineTime = selectedOption.dueDate
        newInfo.freshStatus = .newest
        FreshnessService.updateFreshStatus(info: newInfo,
                                           objToken: dependency.objToken,
                                           objType: dependency.objType)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] in
            guard let self = self else { return }
            let successTips = BundleI18n.SKResource.LarkCCM_CM_Verify_PeriodSet_Toast(FreshStatus.newest.name)
            UDToast.showSuccess(with: successTips, on: self.view.window ?? self.view)
            self.dismiss(animated: true)
        } onError: { error in
            DocsLogger.error("docFresh: update Faild \(error.localizedDescription)")
            UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_CM_Verify_Failed_Toast, on: self.view)
        }
        .disposed(by: disposeBag)
    }

    private func reloadCheckboxList(selectedIndex: Int) {
        let items = timeOptions.enumerated().map {
            let isSelected = ($0.0 == selectedIndex)
            if isSelected {
                confirmButtonEnableRelay.accept(dependency.freshInfo.deadlineTime?.shortDate(timeFormatType: .long) != $0.1.dueDate.shortDate(timeFormatType: .long))
            }
            return CheckBoxListItem(selected: isSelected, title: $0.1.title,
                                    subTitle: $0.1.dueDateString,
                                    subTitleFontSize: 14)
        }
        checkboxListView.reloadItems(items)
    }
}

extension FreshnessValidTimeViewContoller: CheckBoxListDelegate {
    func checkBoxList(didSelectRowAt index: Int) {
        guard index >= 0, index < timeOptions.count else { return }
        let selectOption = timeOptions[index]
        switch selectOption {
        case .dueDay:
            guard selectOption != currentSelectOption else { return }
            currentSelectOption = selectOption
            reloadCheckboxList(selectedIndex: index)
        case .custom(let oldDate):
            showDatePicker(date: oldDate) { [weak self] newDate in
                guard let self else { return }
                self.timeOptions[index] = .custom(date: newDate)
                self.currentSelectOption = self.timeOptions[index]
                self.reloadCheckboxList(selectedIndex: index)
            }

        }
    }
}
