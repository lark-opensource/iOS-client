//
//  FreshnessDatePickerViewController.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/8.
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

final class FreshnessDatePickerViewController: FreshnessBaseViewController {

    var didClickCompletion: ((Date) -> Void)?
    private var currentDate: Date

    private lazy var completeButton: UIButton = {
        let button = UIButton()
        // 完成
        button.setTitle(BundleI18n.SKResource.Doc_Doc_SearchDone,
                        withFontSize: 16,
                        fontWeight: .regular, colorsForStates: [
                            (UDColor.primaryContentDefault, .normal),
                            (UDColor.textDisabled, .disabled)
                        ])
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()

    private lazy var cancelTextButton: UIButton = {
        let button = UIButton()
        // 取消
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel,
                        withFontSize: 16,
                        fontWeight: .regular, colorsForStates: [
                            (UDColor.iconN1, .normal)
                        ])
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        return button
    }()

    private lazy var datePicker: UDDateWheelPickerView = {
        let config = UDWheelsStyleConfig(mode: .yearMonthDay, maxDisplayRows: 5)
        let datePicker = UDDateWheelPickerView(wheelConfig: config)
        datePicker.select(date: currentDate)
        return datePicker
    }()

    init(date: Date) {
        self.currentDate = date
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("docFresh: freshnessSettingVC deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupUI() {
        super.setupUI()
        headerView.toggleCloseButton(isHidden: true)
        headerView.backgroundColor = UDColor.bgBody
        headerView.setTitle(BundleI18n.SKResource.LarkCCM_CM_Verify_ValidityPeriod_Until_Title)

        datePicker.dateChanged = { [weak self] (newDate) in
            self?.dateDidChange(date: newDate)
        }

        containerView.addSubview(headerView)
        headerView.addSubview(cancelTextButton)
        headerView.addSubview(completeButton)
        containerView.addSubview(datePicker)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(Layout.headerHeight)
        }
        cancelTextButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerView.titleCenterY)
            make.left.equalToSuperview().inset(16)
        }
        completeButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerView.titleCenterY)
            make.right.equalToSuperview().inset(16)
        }
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(256)
            make.bottom.equalToSuperview()
        }
    }

    private func dateDidChange(date: Date) {
        DocsLogger.debug("freshness: dateDidChange \(date)")
        currentDate = date
        completeButton.isEnabled = (date >= Date.sk.tomorrow())
    }

    @objc
    private func didClickConfirm() {
        didClickCompletion?(currentDate)
        dismiss(animated: true)
    }
}
