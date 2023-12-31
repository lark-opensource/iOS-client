//
//  ViewController.swift
//  LarkFeatureSwitchDev
//
//  Created by Crazy凡 on 2020/5/10.
//

import Foundation
import UIKit
import LarkFeatureSwitch

class ViewController: UIViewController {
    private var showDebugButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        showDebugButton.frame = view.bounds

        showDebugButton.setTitle("Show Debug", for: .normal)
        showDebugButton.addTarget(self, action: #selector(showDebugController), for: .touchUpInside)
        view.addSubview(showDebugButton)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let self = self else { return }
            self.showDebugButton.frame = self.view.bounds
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showDebugController()
    }

    @objc
    private func showDebugController() {
        self.present(
            UINavigationController(rootViewController: PadFeatureSwitchViewController()),
            animated: true,
            completion: nil
        )
    }
}
