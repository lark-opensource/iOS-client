//
//  MyAIAvatarSettingController.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import FigmaKit
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast

class MyAIAvatarSettingController: BaseUIViewController {

    var onSuccess: (() -> Void)?

    private let disposeBag = DisposeBag()

    lazy var avatarPicker: AIAvatarPickerView = {
        let view = AIAvatarPickerView(presetAvatars: viewModel.presetAvatars)
        return view
    }()

    lazy var saveButton: UIButton = {
        let button = AIUtils.makeAIButton()
        button.setTitle(BundleI18n.LarkAI.MyAI_IM_AISettings_Avatar_Save_Button, for: .normal)
        button.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
        return button
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

    let viewModel: MyAISettingViewModel

    override var navigationBarStyle: NavigationBarStyle {
        if #available(iOS 16, *) {
            return .custom(UIColor.clear)
        } else {
            return .custom(UIColor.ud.bgBody)
        }
    }

    override func loadView() {
        view = AIUtils.makeAuroraBackgroundView()
    }

    init(viewModel: MyAISettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = BundleI18n.LarkAI.MyAI_IM_AISettings_Avatar_Title
        navigationItem.leftBarButtonItem = cancelButton
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(avatarPicker)
        view.addSubview(saveButton)
        avatarPicker.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-16)
        }
        saveButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
        }

        // 将当前的头像设为选中状态
        if let selectedIndex = viewModel.presetAvatars.firstIndex(where: { $0.staticImageKey == viewModel.myAiAvatarKey }), selectedIndex != 0 {
            DispatchQueue.main.async {
                self.avatarPicker.setSelectedItem(selectedIndex, animated: false)
            }
        }

        self.viewModel.presetAvatarsUpdateDriver
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.avatarPicker.reloadData()
            }).disposed(by: self.disposeBag)

        viewModel.reportAvatarSettingShown()
    }

    private func dismissSelf() {
        navigationController?.dismiss(animated: true)
    }

    @objc
    private func didTapCancelButton() {
        dismissSelf()
        viewModel.reportAvatarSettingCancelClicked()
    }

    @objc
    private func didTapSaveButton() {
        let toast = UDToast.showLoading(on: view, disableUserInteraction: true)
        let avatarIndex = avatarPicker.currentSelectedIndex
        viewModel.currentAvatar = viewModel.presetAvatars[avatarIndex]
        viewModel.currentAvatarPlaceholderImage = avatarPicker.currentAvatarImage
        viewModel.updateAIAvatar(onSuccess: { [weak self] in
            guard let self = self else { return }
            toast.remove()
            self.onSuccess?()
            self.dismissSelf()
        }, onFailure: { [weak self] error in
            guard let self = self else { return }
            toast.remove()
            UDToast.showFailure(with: "Update avatar failed", on: self.view, error: error)
        })
        viewModel.reportAvatarSettingSaveClicked()
    }
}
