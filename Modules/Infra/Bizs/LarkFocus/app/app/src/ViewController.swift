//
//  ViewController.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/13.
//

import Foundation
import UIKit
import SnapKit
import LarkFocus
import UniverseDesignTheme
import LarkEmotion

class ViewController: UIViewController {

    private lazy var fadeAnimator = GenericFadeTransitionManager()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 5
        return stack
    }()

    private lazy var focusButton: UIButton = {
        let button = UIButton()
        button.setTitle("Focus", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(didTapFocusButton), for: .touchUpInside)
        return button
    }()

    private lazy var settingButton: UIButton = {
        let button = UIButton()
        button.setTitle("Setting", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(didTapSettingButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
        }
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(stackView)
        stackView.addArrangedSubview(focusButton)
        stackView.addArrangedSubview(settingButton)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        EmotionResouce.shared.reloadResouces(isOversea: false)
    }

    @objc
    private func didTapFocusButton() {
        let focusVC = FocusListController()
        focusVC.modalPresentationStyle = .custom
        focusVC.transitioningDelegate = fadeAnimator
        present(focusVC, animated: true)
    }

    @objc
    private func didTapSettingButton() {
        let settingVC = FocusSettingController()
        navigationController?.pushViewController(settingVC, animated: true)
    }
}
