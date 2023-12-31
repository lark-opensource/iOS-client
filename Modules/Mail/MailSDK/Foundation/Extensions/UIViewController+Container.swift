//
//  UIViewController+Container.swift
//  Action
//
//  Created by tefeng liu on 2019/6/30.
//

import UIKit
import SnapKit

extension UIViewController {
    func displayContentController(_ vc: UIViewController, insert: Bool = false) {
        displayContentController(vc, onView: view, insert: insert)
    }

    func displayContentController(_ vc: UIViewController, onView parentView: UIView, insert: Bool = false) {
        addChild(vc)
        if insert {
            parentView.insertSubview(vc.view, at: 0)
        } else {
            parentView.addSubview(vc.view)
        }
        vc.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        vc.didMove(toParent: self)
    }

    func hideContentController(_ vc: UIViewController) {
        vc.hideFromParentViewController()
    }

    func hideFromParentViewController() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
