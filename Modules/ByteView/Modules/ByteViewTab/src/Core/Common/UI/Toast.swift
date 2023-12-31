//
//  Toast.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/19.
//

import Foundation
import UniverseDesignToast

final class Toast {
    static func show(_ text: String, on view: UIView) {
        UDToast.showTips(with: text, on: view)
    }

    static func showSuccess(_ text: String, on view: UIView) {
        UDToast.showSuccess(with: text, on: view)
    }

    static func showFailure(_ text: String, on view: UIView) {
        UDToast.showFailure(with: text, on: view)
    }
}
