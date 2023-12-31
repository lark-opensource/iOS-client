//
//  KALoginViewController.swift
//  KALogin
//
//  Created by Nix Wang on 2021/12/14.
//

import Foundation
import UIKit
import AppLink

class KALoginViewController: UIViewController {
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Username"
        textField.borderStyle = .roundedRect
        textField.text = "zhangfei"
        return textField
    }()
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.text = "zhangfei"
        return textField
    }()
    private lazy var loginButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("登录", for: .normal)
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

    private let loginAPI = KALoginAPI.shared
    private let redirectURL: String
    private let context: KALoginContext

    init(redirectURL: String, context: KALoginContext) {
        self.redirectURL = redirectURL
        self.context = context

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let stackView = UIStackView(arrangedSubviews: [usernameTextField, passwordTextField, loginButton, statusLabel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        view.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: 300).isActive = true
    }

    @objc
    private func login() {
        statusLabel.text = "📡 " + "加载中..."
        loginButton.isEnabled = false
        loginAPI.verify(redirectURL: redirectURL) { [weak self] result in
            guard let `self` = self else { return }

            self.loginButton.isEnabled = true

            switch result {
            case .success(let url):
                debugPrint("Validate URL: \(url)")

                guard let validateURL = URL(string: url)  else {
                    assertionFailure("Invalid validate URL")
                    return
                }

                self.loginAPI.validate(url: validateURL) { [weak self] result in
                    guard let `self` = self else { return }

                    switch result {
                    case .success(let landURL):
                        debugPrint("Land URL: \(landURL)")

                        self.statusLabel.text = "✅ " + "加载成功"
                        if let url = URL(string: landURL) {
                            AppLinkManager.shared.open(url, context: AppLinkContext(sourceViewController: self))
                        } else {
                            assertionFailure("Invalid land URL")
                        }

                        break
                    case .failure(let error):
                        debugPrint("Failed to get land URL: \(error)")
                        self.context.kaLoginCompletion?(.failure(error))
                        self.context.kaLoginCompletion = nil
                    }
                }
                break
            case .failure(let error):
                self.context.kaLoginCompletion?(.failure(error))
                self.context.kaLoginCompletion = nil
            }
        }
    }

}
