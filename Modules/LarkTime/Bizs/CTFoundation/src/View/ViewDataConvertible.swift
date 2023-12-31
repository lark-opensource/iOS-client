//
//  ViewDataConvertible.swift
//  CTFoundation
//
//  Created by 张威 on 2020/3/15.
//

import RxSwift
import RxCocoa

public protocol ViewDataConvertible: AnyObject {
    associatedtype ViewDataType
    var viewData: ViewDataType? { get set }
}

public extension ObservableType {

    /// 用于简化 ViewData 的数据绑定
    public func bind<VD>(to vd: VD) -> Disposable where VD: ViewDataConvertible, Element == VD.ViewDataType {
        return bind { [weak vd] viewData in
            if Thread.isMainThread {
                vd?.viewData = viewData
            } else {
                DispatchQueue.main.async {
                    vd?.viewData = viewData
                }
            }
        }
    }

    /// 用于简化 ViewData 的数据绑定
    public func bind<VD>(to vd: VD) -> Disposable where VD: ViewDataConvertible, Element == VD.ViewDataType? {
        return bind { [weak vd] viewData in
            if Thread.isMainThread {
                vd?.viewData = viewData
            } else {
                DispatchQueue.main.async {
                    vd?.viewData = viewData
                }
            }
        }
    }

}
