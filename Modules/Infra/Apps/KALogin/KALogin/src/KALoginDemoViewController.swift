//
//  KALoginDemoViewController.swift
//  KALogin
//
//  Created by Nix Wang on 2021/12/14.
//

import Foundation
import UIKit
import KALogin
import KADemoAssemble
import AppLink
import MBProgressHUD

public func getKALoginDemoViewController() -> UIViewController {
    return UINavigationController(rootViewController: KALoginDemoViewController())
}

class KALoginDemoViewController: UIViewController {
    private lazy var loginButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("开始登录", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(login), for: .touchUpInside)
        return button
    }()
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let kaLogin = KALogin.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(loginButton)
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        view.addSubview(statusLabel)
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        statusLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16).isActive = true

        KALogin.shared.setup()
    }

    @objc
    private func login() {
        kaLogin.startLogin(rootViewController: self) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let url):
                debugPrint("App link: \(url)")
                UIApplication.shared.keyWindow?.rootViewController = DemoEnv.rootViewController()
                break
            case .failure(let error):
                debugPrint("Failed to get auth url: \(error)")
                self.statusLabel.text = "💣 " + error.localizedDescription
            }
        }
    }
}
