//
//  BaseViewController.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/3.
//

import Foundation
import UIKit
import LarkSceneManager

class BaseViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        if self.navigationItem.leftBarButtonItem == nil &&
            self == self.navigationController?.viewControllers.first &&
            self.view.window?.rootViewController == self.navigationController &&
            SceneManager.shared.supportsMultipleScenes {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Close", style: .done, target: self, action: #selector(clickClose)
            )
        }
    }

    @objc
    func clickClose() {
        if #available(iOS 13.0, *) {
            guard let session = self.view.window?.windowScene?.session else { return }
            let options = UIWindowSceneDestructionRequestOptions()
            // 缩小消失
            options.windowDismissalAnimation = .standard
            // 向上划出
//            options.windowDismissalAnimation = .commit
            // 向下划出
//            options.windowDismissalAnimation = .decline

            UIApplication.shared.requestSceneSessionDestruction(session,
                                                                options: options,
                                                                errorHandler: nil)
        }
    }
}
