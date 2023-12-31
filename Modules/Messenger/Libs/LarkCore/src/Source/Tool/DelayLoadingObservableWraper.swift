//
//  DelayLoadingObservableWraper.swift
//  LarkCore
//
//  Created by zc09v on 2021/2/4.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignToast

public final class DelayLoadingObservableWraper: NSObject {
    public static func wraper<T>(observable: Observable<T>, delay: Double = 0.5, showLoadingIn: UIView?, loadingText: String? = nil) -> Observable<T> {
        var hasFinish: Bool = false
        var hud: UDToast?
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            if !hasFinish, let showLoadingIn = showLoadingIn {
                hud = UDToast()
                hud?.showLoading(with: loadingText ?? "", on: showLoadingIn, disableUserInteraction: true)
            }
        })
        func finished() {
            DispatchQueue.main.async {
                hasFinish = true
                hud?.remove()
            }
        }
        return observable.do(onNext: { _ in
            finished()
        }, onError: { _ in
            finished()
        }, onCompleted: {
            finished()
        }, onDispose: {
            finished()
        })
    }
}
