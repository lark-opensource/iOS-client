//
//  ToastStatusBinder.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/17.
//
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignToast

enum ToastStatus {
    case tips(String, fromWindow: Bool = false)
    case success(String, fromWindow: Bool = false)
    case warning(String)
    case failure(String, fromWindow: Bool = false)
    case loading(info: String, disableUserInteraction: Bool, fromWindow: Bool = false)
    case remove
}

protocol ToastStatusReceiver: AnyObject {
    func change(toastStatus: ToastStatus)
}

extension UIViewController: ToastStatusReceiver {
    func change(toastStatus: ToastStatus) {
        switch toastStatus {
        case .tips(let info, let fromWindow):
            if let window = view.window, fromWindow {
                UDToast.showTips(with: info, on: window)
            } else {
                UDToast.showTips(with: info, on: view)
            }
        case .success(let info, let fromWindow):
            if let window = view.window, fromWindow {
                UDToast.showSuccess(with: info, on: window)
            } else {
                UDToast.showSuccess(with: info, on: view)
            }
        case .warning(let info):
            UDToast.showWarning(with: info, on: view)
        case .failure(let info, let fromWindow):
            if let window = view.window, fromWindow {
                UDToast.showFailure(with: info, on: window)
            } else {
                UDToast.showFailure(with: info, on: view)
            }
        case .loading(let info, let disableUserInteraction, let fromWindow):
            if let window = view.window, fromWindow {
                UDToast.showLoading(with: info, on: window, disableUserInteraction: disableUserInteraction)
            } else {
                UDToast.showLoading(with: info, on: view, disableUserInteraction: disableUserInteraction)
            }
        case .remove:
            UDToast.removeToast(on: view)
            if let window = view.window { UDToast.removeToast(on: window) }
        }
    }
}

extension Reactive where Base: ToastStatusReceiver {
    var toast: Binder<ToastStatus> {
        Binder(base) { target, toastStatus in
            target.change(toastStatus: toastStatus)
        }
    }
}
