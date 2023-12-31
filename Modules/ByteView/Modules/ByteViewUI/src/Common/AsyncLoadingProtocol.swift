//
//  AsyncLoadingProtocol.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

protocol AsyncLoadingProtocol: UIView {
    var deadline: DispatchTimeInterval { get }
    func playIfNeeded(_ closure: @escaping () -> Void)
    func stopIfNeeded(_ closure: @escaping () -> Void)
}

extension AsyncLoadingProtocol {

    var deadline: DispatchTimeInterval { .milliseconds(200) }

    private var isLoading: Bool {
        get {
            let object = objc_getAssociatedObject(self, &AssociatedKeys.isLoading)
            return (object as? NSNumber)?.boolValue ?? false
        }

        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.isLoading,
                                     NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func playIfNeeded(_ closure: @escaping () -> Void) {
        Logger.ui.info("[\(self)] loading ready")
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + deadline) {
            if self.isLoading {
                Logger.ui.info("[\(self)] loading start")
                closure()
            } else {
                Logger.ui.info("[\(self)] loading skip")
            }
        }
    }

    func stopIfNeeded(_ closure: @escaping () -> Void) {
        Logger.ui.info("[\(self)] loading stop")
        closure()
        isLoading = false
    }
}

private enum AssociatedKeys {
    static var isLoading = "isLoading"
}
