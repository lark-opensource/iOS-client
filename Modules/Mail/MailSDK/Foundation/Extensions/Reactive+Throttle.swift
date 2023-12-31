//
//  Reactive+Throttle.swift
//  MailSDK
//
//  Created by li jiayi on 2021/8/18.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: UIButton {
    var throttleTap: ControlEvent<Void> {
        return ControlEvent<Void>(events: tap.throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance))
    }
}
