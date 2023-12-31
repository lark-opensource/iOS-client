//
//  MyAINameSettingController.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignToast

class MyAINameSettingController: BaseUIViewController, UDTextFieldDelegate {

    var onSuccess: (() -> Void)?

    private let disposeBag = DisposeBag()

    let viewModel: MyAISettingViewModel

    private var currentName: String? {
        nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    lazy var nameField: UDTextField = {
        let view = AIUtils.makeAINameTextField()
        view.config.font = UIFont.ud.body0(.fixed)
        view.config.textAlignment = .left
        return view
    }()

    private lazy var saveButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkAI.MyAI_IM_AISettings_Name_Save_Button)
        item.setProperty(font: UIFont.ud.headline(.fixed), alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryPri600, for: .normal)
        item.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        item.button.titleLabel?.adjustsFontSizeToFitWidth = true
        item.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
        return item
    }()

    private lazy var cancelButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkAI.MyAI_Onboarding_EditAvatar_Cancel_Button)
        item.setProperty(alignment: .left)
        item.setProperty(font: UIFont.ud.body0(.fixed), alignment: .left)
        item.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        item.button.titleLabel?.adjustsFontSizeToFitWidth = true
        item.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        return item
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBody)
    }

    /*
    override func loadView() {
        view = AIUtils.makeAuroraBackgroundView()
    }
     */

    init(viewModel: MyAISettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = BundleI18n.LarkAI.MyAI_IM_AISettings_Name_Title
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = cancelButton
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }
        // 填写当前的名称
        nameField.text = viewModel.currentName
        // 调整“保存”按钮的可点击状态
        changeSaveButtonStateIfNeeded()
        nameField.input.rx.value.asDriver().drive(onNext: { [weak self] _ in
            self?.changeSaveButtonStateIfNeeded()
        }).disposed(by: self.disposeBag)
        // 打开页面弹起键盘
        DispatchQueue.main.async {
            self.nameField.becomeFirstResponder()
        }

        viewModel.reportNameSettingShown()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let gradientColor = UDColor.AIPrimaryContentDefault.toColor(withSize: nameField.bounds.size)
        nameField.config.borderActivatedColor = gradientColor
        nameField.config.textColor = gradientColor
    }

    private func changeSaveButtonStateIfNeeded() {
        saveButton.isEnabled = !(currentName ?? "").isEmpty
    }

    private func dismissSelf() {
        navigationController?.dismiss(animated: true)
    }

    @objc
    private func didTapCancelButton() {
        dismissSelf()
        viewModel.reportNameSettingCancelClicked()
    }

    @objc
    private func didTapSaveButton() {
        let toast = UDToast.showLoading(on: view, disableUserInteraction: true)
        viewModel.updateAIName(with: currentName ?? "My AI", onSuccess: { [weak self] in
            guard let self = self else { return }
            toast.remove()
            self.onSuccess?()
            self.dismissSelf()
        }, onFailure: { [weak self] error in
            guard let self = self else { return }
            toast.remove()
            UDToast.showFailure(with: "Update name failed", on: self.view, error: error)
        })
        viewModel.reportNameSettingSaveClicked()
    }
}
