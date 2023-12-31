//
//  LarkAvatarCustomBinder.swift
//  LarkAvatar
//
//  Created by huangzhikai on 2023/6/10.
//  支持自定义显示显示icon逻辑

import Foundation
import RxSwift

//MARK: -------  LarkAvatarCustomBinder -----------
// 自定义binder 注册和获取
public class LarkAvatarCustomBinder {

    public static let shared = LarkAvatarCustomBinder()
    
    //在这里注册，是为了，统一注册的地方，和达到懒加载的目的
    private init() {
        register(model: DocsIconBinderModel.self , binder: LarkAvatarDocsIconBinder())
    }
    
    private var binderMap: [String: any LarkAvatarCustomBinderProtocol] = [:]
    
    public func register<T: LarkAvatarCustommModelProtocol>(model: T.Type, binder: some LarkAvatarCustomBinderProtocol<T>) {
        binderMap[model.modelName] = binder
    }
    
    public func getBinder<T: LarkAvatarCustommModelProtocol>(model: T) -> (any LarkAvatarCustomBinderProtocol)? {
        return binderMap[type(of: model).modelName]
    }
}

//MARK: -------  LarkAvatarCustommModelProtocol -----------
// 自定义model 协议
public protocol LarkAvatarCustommModelProtocol {
    //主要用户自定义唯一标识
    static var modelName: String { get }
}

extension LarkAvatarCustommModelProtocol where Self: AnyObject {
    //class进行默认实现，struct需要自己手动实现：推荐使用：模块名+类名
    static var modelName: String {
        NSStringFromClass(self)
    }
}

//MARK: -------  LarkAvatarCustomBinderProtocol -----------
// 自定义binder 协议
// swift对协议对泛型支持还不够理想，多定义了个binder(model: Any)才不会报错， 其实没有多大用，并加了默认实现，可以忽略这个方法
// 业务正常实现binder(model: Model)即可
public protocol LarkAvatarCustomBinderProtocol<Model> {
    associatedtype Model
    func binder(model: Any) -> Observable<UIImage>
    func binder(model: Model) -> Observable<UIImage>
}


public extension LarkAvatarCustomBinderProtocol {
    func binder(model: Any) -> Observable<UIImage> {
        guard let actualModel = model as? Model else {
            fatalError("model error")
        }
        return binder(model: actualModel)
    }
}
