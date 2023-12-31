//
//  PresentViewController.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/12.
//

import Foundation
import LarkUIKit

extension UIViewController {

    /// 根据当前是 iPhone 还是 iPad 进行Present
    /// - Parameters:
    ///   - phonePresentationStyle: iPhone 适用的 PresentationStyle
    ///   - padPopOverSourceView: iPad 适用的 PopOverView
    func customPresent(_ vc: UIViewController,
                       phonePresentationStyle: UIModalPresentationStyle = .fullScreen,
                       padPopOverSourceView: UIView? = nil,
                       animated: Bool = true,
                       completion: @escaping () -> Void = {}) {
        if Display.pad {
            if let sourceView = padPopOverSourceView {
                vc.modalPresentationStyle = .popover
                vc.popoverPresentationController?.sourceView = sourceView
                vc.popoverPresentationController?.sourceRect = sourceView.bounds
            }
        } else {
            vc.modalPresentationStyle = phonePresentationStyle
        }
        present(vc, animated: animated, completion: completion)
    }
}
