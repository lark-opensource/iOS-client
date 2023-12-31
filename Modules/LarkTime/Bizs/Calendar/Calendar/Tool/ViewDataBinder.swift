//
//  ViewDataBinder.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/16.
//

import RxSwift
import RxCocoa

protocol ViewDataReceiver: AnyObject {
    associatedtype ViewDataType
    func update(viewData: ViewDataType)
}

extension Reactive where Base: ViewDataReceiver {
    var viewData: Binder<Base.ViewDataType> {
        Binder(base, scheduler: MainScheduler.instance) { target, viewData in
            target.update(viewData: viewData)
        }
    }
}
