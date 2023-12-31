//
//  VCWraper.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/20.
//

import UIKit
import Foundation

/// Wraper for adding VC.view as subview
final class VCWraper: UIView {
    var childController: UIViewController? {
        didSet {
            if let view = oldValue?.viewIfLoaded, view.superview == self {
                view.removeFromSuperview() // remove child view if replace childController
            }
            if childController != nil {
                checkSubviewAdded()
            }
        }
    }
    // if delayLoadToAppear, will load view before appeared on window
    var delayLoadToAppear = false

    private var appeared = false
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        guard !appeared else {
            return
        }

        appeared = true
        checkSubviewAdded()
    }

    func checkSubviewAdded() {
        if let vc = childController, appeared || !delayLoadToAppear, vc.view.superview != self {
            vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vc.view.frame = self.bounds
            self.addSubview(vc.view)
        }
    }
}
