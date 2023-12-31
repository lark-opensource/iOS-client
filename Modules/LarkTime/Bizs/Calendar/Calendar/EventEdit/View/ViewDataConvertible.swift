//
//  ViewDataConvertible.swift
//  Calendar
//
//  Created by 张威 on 2020/3/15.
//

import RxSwift
import RxCocoa

protocol ViewDataConvertible: AnyObject {
    associatedtype ViewDataType
    var viewData: ViewDataType? { get set }
}

extension ObservableType {

    /// 用于简化 ViewData 的数据绑定
    func bind<VD>(to vd: VD) -> Disposable where VD: ViewDataConvertible, Element == VD.ViewDataType {
        return self.observeOn(MainScheduler.asyncInstance)
            .bind(onNext: {  [weak vd] viewData in
                vd?.viewData = viewData
            })
    }

    /// 用于简化 ViewData 的数据绑定
    func bind<VD>(to vd: VD) -> Disposable where VD: ViewDataConvertible, Element == VD.ViewDataType? {
        return self.observeOn(MainScheduler.asyncInstance)
            .bind(onNext: {  [weak vd] viewData in
                vd?.viewData = viewData
            })
    }

}
