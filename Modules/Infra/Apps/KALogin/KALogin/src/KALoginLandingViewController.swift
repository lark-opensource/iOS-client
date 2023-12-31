//
//  KALoginLandingViewController.swift
//  KALogin
//
//  Created by Nix Wang on 2021/12/14.
//

import UIKit
import Foundation
import AppLink
import KADemoAssemble

@objc
public class KALoginLandingViewController: UIViewController {

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    public let landURL: String
    public let loginAPI = KALoginAPI.shared
    private let context: UIViewController

    @objc
    public init(landURL: String, from: UIViewController) {
        self.landURL = landURL
        self.context = from

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(statusLabel)
        statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true

        dispatch()
    }

    private func dispatch() {
        guard let components = URLComponents(string: landURL) else {
            assertionFailure("Invalid land URL: \(landURL)")
            return
        }

        guard let idpContext = components.queryItems?.first(where: { $0.name == "idp_context" })?.value else {
            assertionFailure("State not found in land URL: \(landURL)")
            return
        }
        let decodedData = Data(base64Encoded: idpContext)!
        let contextDict = try? JSONSerialization.jsonObject(with: decodedData, options: .allowFragments) as? NSDictionary
        guard let state = (contextDict?.enumerated()
                        .first(where: { $0.element.0 as? String == "state" })?.element.1) as? String else {
            assertionFailure("Invalid IDP context")
            return
        }

        statusLabel.text = "📡 " + "正在获取用户信息..."
        loginAPI.dispatch(state: state) { [weak self] result in
            guard let `self` = self else { return }

            switch result {
            case .success(let enterAppInfo):
                debugPrint("Enter app: \(enterAppInfo)")
                self.statusLabel.text = "✅ " + "成功"
                UIApplication.shared.keyWindow?.rootViewController = DemoEnv.rootViewController()
                break
            case .failure(let error):
                debugPrint("Failed dispatch: \(error)")
                self.statusLabel.text = "💣 " + error.localizedDescription
            }
        }
    }
}
