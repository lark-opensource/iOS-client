//
//  MainViewController.swift
//  LarkProfileDev
//
//  Created by Hayden Wang on 2021/6/29.
//

import Foundation
import UIKit
import SnapKit
import LarkProfile
import UniverseDesignColor
import UniverseDesignTheme

class MainViewController: UIViewController {

    private lazy var profileButton: UIButton = {
        let button = UIButton()
        button.setTitle("Profile", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didTapProfileButton(_:)), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(profileButton)
        profileButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(50)
        }
        if #available(iOS 13.0, *) {
            UDThemeManager.setUserInterfaceStyle(.unspecified)
        }
    }

    @objc
    private func didTapProfileButton(_ sender: UIButton) {
        let vc = ProfileViewController(provider: ProfileMockProvider(data: ProfileMockData()))
        if UIDevice.current.userInterfaceIdiom == .pad {
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
