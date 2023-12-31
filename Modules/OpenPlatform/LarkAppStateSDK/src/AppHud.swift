//
//  File.swift
//  LarkAppStateSDK
//
//  Created by lilun.ios on 2021/1/15.
//

import Foundation
import RoundedHUD
import EENavigator

extension RoundedHUD {
    @discardableResult
    public static func opShowFailure(with text: String, on view: UIView? = nil) -> RoundedHUD? {
        if let targetView = view {
            return RoundedHUD.showFailure(with: text, on: targetView)
        }
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            return RoundedHUD.showFailure(with: text, on: fromVC.view)
        }
        return nil
    }
}
