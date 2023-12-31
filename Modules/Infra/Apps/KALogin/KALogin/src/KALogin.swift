//
//  KALogin.swift
//  KALogin
//
//  Created by Nix Wang on 2021/12/15.
//

import Foundation
import UIKit
import AppLink
import MBProgressHUD

class KALoginContext {
    var kaLoginCompletion: ((Result<String, Error>) -> Void)?
}

public class KALogin {
    public static let shared = KALogin()
    private let loginAPI = KALoginAPI.shared
    private let context = KALoginContext()

    private init() {}

    public func setup() {
    }

    public func startLogin(rootViewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        MBProgressHUD.showAdded(to: rootViewController.view, animated: true)
        loginAPI.getAuthURL { [weak self] result in
            guard let `self` = self else { return }

            switch result {
            case .success(let url):
                debugPrint("App link: \(url)")

                if let url = URL(string: url) {
                    AppLinkManager.shared.open(url, context: AppLinkContext(sourceViewController: rootViewController))
                } else {
                    assertionFailure("Invalid URL: \(url)")
                }

                MBProgressHUD.hide(for: rootViewController.view, animated: true)

                break
            case .failure(let error):
                debugPrint("Failed to get auth url: \(error)")
                self.context.kaLoginCompletion?(.failure(error))
                self.context.kaLoginCompletion = nil

                MBProgressHUD.hide(for: rootViewController.view, animated: true)
            }
        }
    }
}
