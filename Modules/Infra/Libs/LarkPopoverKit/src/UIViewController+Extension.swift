//
//  UIViewController+Extension.swift
//  LarkPopoverKit
//
//  Created by 李晨 on 2020/3/19.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa

extension UIViewController {

    /// 判断当前 vc 是不是以 popover 的样式展示
    public var isInPoperover: Bool {

        func isInPoperover(
            vc: UIViewController,
            in popoverVC: UIPopoverPresentationController) -> Bool {
            /// 根据 containerView 判断
            if let containerView = popoverVC.containerView,
                vc.view.window != nil {
                var isInPoperover: Bool = false
                var checkView: UIView = vc.view
                while let nextView = checkView.superview {
                    checkView = nextView
                    if nextView == containerView {
                        isInPoperover = true
                        break
                    }
                }
                return isInPoperover
            } else if popoverVC.adaptivePresentationStyle(for: vc.traitCollection) == .none {
                return true
            }

            /// 获取 presentingViewController, 通过 popoverPresentation 取有可能取不到造成崩溃
            guard let presentingViewController = vc.presentingViewController else {
                return false
            }

            /// 判断当前 window C/R
            if let window = presentingViewController.view.window {
                return window.traitCollection.horizontalSizeClass == .regular
            }
            return false
        }

        /// 判断系统 popover 样式
        if self.modalPresentationStyle == .popover,
            let popoverPresentationController = self.popoverPresentationController {
            return isInPoperover(vc: self, in: popoverPresentationController)
        }
        /// 判断自定义 popover 样式
        if self.modalPresentationStyle == .custom,
            let popoverPresentationController = self.presentationController as? UIPopoverPresentationController {
            return isInPoperover(vc: self, in: popoverPresentationController)
        }

        return false
    }

    /// 监听 popover 变化
    /// 目前的实现方式是监听 frame 变化
    /// 目前每次变化都会回调一次，如果使用 autolayout 布局，不需要响应 frame 变化的
    /// 可以添加 .distinctUntilChanged() 过滤重复信号
    public func isInPopoverObservable() -> Observable<Bool> {
        let vc = self
        var kvObservation: NSKeyValueObservation?
        return Observable<Bool>.create { [weak vc] (observer) -> Disposable in
            kvObservation = vc?.view.observe(\UIView.frame) {  (_, change) in
               if let vc = vc {
                 observer.onNext(vc.isInPoperover)
               }
            }
            if let vc = vc {
                observer.onNext(vc.isInPoperover)
            }
            return Disposables.create {
                kvObservation = nil
            }
        }
    }
}
