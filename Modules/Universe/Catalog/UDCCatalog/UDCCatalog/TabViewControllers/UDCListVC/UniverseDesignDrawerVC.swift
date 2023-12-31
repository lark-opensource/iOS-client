//
//  UniversalDesignDrawerVC.swift
//  UDCCatalog
//
//  Created by 龙伟伟 on 2020/12/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignDrawer

class UniverseDesignDrawerVC: UIViewController {
    private lazy var transitionManager = UDDrawerTransitionManager(host: self)
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        transitionManager.addDrawerEdgeGesture(to: view)
        
        let btn = UIButton()
        btn.setTitle("这里", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.addTarget(self, action: #selector(btnHandler), for: .touchUpInside)
        view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.top.equalTo(200)
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.height.equalTo(48)
        }
    }

    @objc func btnHandler() {
        transitionManager.showDrawer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

extension UniverseDesignDrawerVC: UDDrawerAddable {
    var fromVC: UIViewController? {
        return self
    }

    var contentWidth: CGFloat {
        self.view.bounds.width * UDDrawerValues.contentDefaultPercent
    }

    var subVC: UIViewController? {
        UDDrawerGridViewController()
    }

    var direction: UDDrawerDirection {
        .right
    }
}

//extension UITabBarController {
//   open override var childForStatusBarStyle: UIViewController? {
//        return selectedViewController
//    }
//}
//
//extension UINavigationController {
//   open override var childForStatusBarStyle: UIViewController? {
//        return visibleViewController
//    }
//}
