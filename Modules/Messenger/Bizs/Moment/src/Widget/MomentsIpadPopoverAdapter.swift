//
//  MomentsIpadPopoverAdapter.swift
//
//  Created by liluobin on 2022/1/18.
//

import Foundation
import LarkUIKit
import EENavigator
import UIKit
final class MomentsIpadPopoverAdapter {

    static func popoverView(_ view: UIView,
                            fromVC: UIViewController,
                            sourceView: UIView,
                            preferredContentSize: CGSize,
                            sourceRect: CGRect? = nil,
                            backgroundColor: UIColor? = nil,
                            permittedArrowDirections: UIPopoverArrowDirection? = nil,
                            deinitCallBack: (() -> Void)? = nil) -> UIViewController {
        let presentVC = ContainerViewController()
        presentVC.deinitCallBack = deinitCallBack
        presentVC.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalTo(presentVC.view.safeAreaLayoutGuide.snp.edges)
        }
        presentVC.modalPresentationStyle = .popover
        // 指定 Popover 指向的 View，必须指定，否则会崩溃
        presentVC.popoverPresentationController?.sourceView = sourceView

        // 指定 Popover 提调整位置
        if let sourceRect = sourceRect {
            presentVC.popoverPresentationController?.sourceRect = sourceRect
        }
        // 指定 Popover 允许的箭头朝向（可选）
        if let permittedArrowDirections = permittedArrowDirections {
            presentVC.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        }
        // 指定 Popover的颜色
        if let backgroundColor = backgroundColor {
            presentVC.popoverPresentationController?.backgroundColor = backgroundColor
        }

        // 指定 Popover 的大小（可选）
        presentVC.preferredContentSize = preferredContentSize
        fromVC.present(presentVC, animated: true)
        return presentVC
    }

    static func popoverVC(_ vc: UIViewController,
                           fromVC: UIViewController,
                           sourceView: UIView,
                           preferredContentSize: CGSize,
                           sourceRect: CGRect? = nil,
                          permittedArrowDirections: UIPopoverArrowDirection? = nil) {
        vc.modalPresentationStyle = .popover
        // 指定 Popover 指向的 View，必须指定，否则会崩溃
        vc.popoverPresentationController?.sourceView = sourceView
        // 指定 Popover 提调整位置
        if let sourceRect = sourceRect {
            vc.popoverPresentationController?.sourceRect = sourceRect
        }
        // 指定 Popover 允许的箭头朝向（可选）
        if let permittedArrowDirections = permittedArrowDirections {
            vc.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        }
        // 指定 Popover 的大小（可选）
        vc.preferredContentSize = preferredContentSize
        fromVC.present(vc, animated: true)
    }
}

private final class ContainerViewController: UIViewController {
    var deinitCallBack: (() -> Void)?
    deinit {
        deinitCallBack?()
    }
}
