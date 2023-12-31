//
//  RootViewController.swift
//  LarkCanvasDev
//
//  Created by Saafo on 2021/3/8.
//

import UIKit
import Foundation
import EENavigator
import SnapKit
import LarkUIKit

@available(iOS 13.0, *)
class RootViewController: UIViewController {
    var modalBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Modal", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        return btn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(modalBtn)
        modalBtn.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        modalBtn.addTarget(self, action: #selector(presentModal), for: .touchUpInside)
    }

    @objc
    func presentModal() {
        Navigator.shared.present(
            ViewController(),
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }
}
