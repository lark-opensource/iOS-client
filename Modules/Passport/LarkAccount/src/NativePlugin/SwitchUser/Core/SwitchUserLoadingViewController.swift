//
//  SwitchUserLoadingViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/10/4.
//

import Foundation

typealias SwitchUserLoadingDismissCallback = (() -> Void)

class SwitchUserLoadingViewController: UIViewController {

    let callback: SwitchUserLoadingDismissCallback

    init(dismissCallback: @escaping SwitchUserLoadingDismissCallback) {
        self.callback = dismissCallback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
