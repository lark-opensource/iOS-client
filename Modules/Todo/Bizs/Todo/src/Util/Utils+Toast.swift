//
//  Utils+Toast.swift
//  Todo
//
//  Created by 张威 on 2020/12/20.
//

import RoundedHUD
import UniverseDesignToast

extension Utils {
    struct Toast {
        typealias Removable = () -> Void
    }
}

extension Utils.Toast {

    static let standardBottomInset: CGFloat = 162

    static let bottomSpace: CGFloat = 20

    private static func fixBottom(
        for toastView: UniverseDesignToast.UDToast,
        in view: UIView,
        bottomInset: CGFloat
    ) {
        guard let viewFrameInScreen = view.superview?.convert(view.frame, to: nil) else {
            toastView.setCustomBottomMargin(bottomInset)
            return
        }
        let marginBottom = max(0, bottomInset - max(0, UIScreen.main.bounds.height - viewFrameInScreen.bottom))
        toastView.setCustomBottomMargin(marginBottom)
    }

    @discardableResult
    static func showLoading(
        with message: String?,
        on view: UIView,
        disableUserInteraction: Bool = false,
        bottomInset: CGFloat = standardBottomInset
    ) -> Removable {
        assert(Thread.isMainThread)
        let text = message ?? I18N.Lark_Legacy_BaseUiLoading
        let toastView = UDToast.showLoading(with: text, on: view, disableUserInteraction: disableUserInteraction)
        fixBottom(for: toastView, in: view, bottomInset: bottomInset)
        return { toastView.remove() }
    }

    @discardableResult
    static func showError(
        with message: String,
        on view: UIView,
        bottomInset: CGFloat = standardBottomInset
    ) -> Removable {
        assert(Thread.isMainThread)
        let toastView = UDToast.showFailure(with: message, on: view)
        fixBottom(for: toastView, in: view, bottomInset: bottomInset)
        return { toastView.remove() }
    }

    @discardableResult
    static func showSuccess(
        with message: String,
        on view: UIView,
        bottomInset: CGFloat = standardBottomInset
    ) -> Removable {
        assert(Thread.isMainThread)
        let toastView = UDToast.showSuccess(with: message, on: view)
        fixBottom(for: toastView, in: view, bottomInset: bottomInset)
        return { toastView.remove() }
    }

    static func showWarning(with message: String, on view: UIView, delay: TimeInterval = 2.0) {
        assert(Thread.isMainThread)
        UDToast.showWarning(with: message, on: view, delay: delay)
    }

    static func showTips(with message: String, on view: UIView, delay: TimeInterval = 2.0) {
        assert(Thread.isMainThread)
        UDToast.showTips(with: message, on: view, delay: delay)
    }
}
