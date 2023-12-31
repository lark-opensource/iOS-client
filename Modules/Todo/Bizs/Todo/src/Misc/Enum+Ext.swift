//
//  Enum+Ext.swift
//  Todo
//
//  Created by 张威 on 2021/7/8.
//

import Foundation
import RxSwift

enum Either<L, R> {
    case left(L)
    case right(R)
}

enum Return<Type> {
    final class Completion {
        var onSuccess: ((Type) -> Void)?
        var onCompleted: (() -> Void)?
        var onError: ((Error) -> Void)?
    }

    // 同步值
    case sync(value: Type)
    // 异步值
    case async(completion: Completion)
}
