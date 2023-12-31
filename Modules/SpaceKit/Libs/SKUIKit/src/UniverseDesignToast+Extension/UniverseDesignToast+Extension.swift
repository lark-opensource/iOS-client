//
//  UniverseDesignToast+Extension.swift
//  SKUIKit
//
//  Created by zoujie on 2021/5/11.
//  


import SKFoundation
import UniverseDesignToast

extension UDToast: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == UDToast {
    enum MsgType {
        case tips
        case warn
        case success
        case failure
        case loading
    }
    class func showMessage(_ msg: String, on view: UIView, msgType: MsgType, disableUserInteraction: Bool = false) {

        switch msgType {
        case .tips:
            UDToast.showTips(with: msg, on: view)
        case .warn:
            UDToast.showWarning(with: msg, on: view)
        case .success:
            UDToast.showSuccess(with: msg, on: view)
        case .failure:
            UDToast.showFailure(with: msg, on: view)
        case .loading:
            UDToast.showLoading(with: msg, on: view, disableUserInteraction: disableUserInteraction)

        }
    }
}
