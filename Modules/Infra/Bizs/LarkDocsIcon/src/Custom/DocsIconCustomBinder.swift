//
//  DocsIconCustomBinder.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/15.
//

import Foundation
import RxSwift

//MARK: -------  DocsIconCustomBinder -----------
// 自定义bunder注册和获取
public class DocsIconCustomBinder {

    public static let shared = DocsIconCustomBinder()
    private init() {}
    private var binderMap: [String: any DocsIconCustomBinderProtocol] = [:]
    
    public func register<T: DocsIconCustomModelProtocol>(model: T.Type, binder: some DocsIconCustomBinderProtocol<T>) {
        binderMap[model.modelName] = binder
    }
    
    public func getBinder<T: DocsIconCustomModelProtocol>(model: T) -> (any DocsIconCustomBinderProtocol)? {
        return binderMap[type(of: model).modelName]
    }
}

//MARK: -------  DocsIconCustomModelProtocol -----------
// 自定义model 协议
public protocol DocsIconCustomModelProtocol {
    //主要用户自定义唯一标识
    static var modelName: String { get }
}

extension DocsIconCustomModelProtocol where Self: AnyObject {
    //class进行默认实现，struct需要自己手动实现：推荐使用：模块名+类名
    static var modelName: String {
        NSStringFromClass(self)
    }
}

//MARK: -------  DocsIconCustomBinderProtocol -----------
// 自定义binder 协议
// swift对协议对泛型支持还不够理想，多定义了个binder(model: Any)才不会报错， 其实没有多大用，并加了默认实现，可以忽略这个方法
// 业务正常实现binder(model: Model)即可
public protocol DocsIconCustomBinderProtocol<Model> {
    associatedtype Model
    func binder(model: Any) -> Observable<UIImage>
    func binder(model: Model) -> Observable<UIImage>
}


public extension DocsIconCustomBinderProtocol {
    func binder(model: Any) -> Observable<UIImage> {
        guard let actualModel = model as? Model else {
            fatalError("model error")
        }
        return binder(model: actualModel)
    }
}
