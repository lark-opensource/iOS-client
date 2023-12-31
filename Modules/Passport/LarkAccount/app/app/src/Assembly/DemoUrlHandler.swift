//
//  DemoUrlHandler.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2020/11/27.
//

import UIKit
import LarkAccountInterface
import RoundedHUD
import EENavigator

class DemoUrlHandler {

    static func handle(url: URL) -> Bool {

        guard let host = url.host else {
            return false
        }
        let urlToPattern = "//\(host)\(url.path)"
        print("DemoUrlHandler handle pattern: \(urlToPattern) url:\(url)")

        if urlToPattern == "//client/web" {
            return AccountServiceAdapter.shared.handleSSOSDKUrl(url)
        }

        if urlToPattern == "//client/verify" {
            AccountServiceAdapter.shared.checkAuth(
                info: .url(url.queryParameters["qr_code"] ?? "", url.queryParameters["bundle_id"] ?? "")
            ) { (result) in
                switch result {
                case .success(let vc):
                    vc.modalPresentationStyle = .overCurrentContext
                    UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: false, completion: nil)
                case .failure(let error):
                    print("DemoUrlHandler handle pattern: \(urlToPattern) error: \(error)")
                    if let window = Navigator.shared.mainSceneWindow {
                        RoundedHUD.showFailure(with: "\(error)", on: window)
                    }
                }
            }
            return true
        }
        return false
    }
}
