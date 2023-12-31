//
//  NoPermissionLoadingView.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/8.
//

import UIKit
import SnapKit
import UniverseDesignColor
import LarkUIKit
import RxSwift
import RxCocoa

final class NoPermissionLoadingView: LoadingPlaceholderView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.text = I18N.Lark_Conditions_Ongoing
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func startAnimating() {
        animationView.play()
    }

    func stopAnimating() {
        animationView.stop()
    }
}
extension Reactive where Base: NoPermissionLoadingView {
    var animating: Binder<Bool> {
        return Binder(self.base) { view, animated in
            if animated {
                view.startAnimating()
                view.isHidden = false
            } else {
                view.stopAnimating()
                view.isHidden = true
            }
        }
    }
}
