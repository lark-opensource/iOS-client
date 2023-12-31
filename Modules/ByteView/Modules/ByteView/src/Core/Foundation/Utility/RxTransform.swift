//
//  RxTransform.swift
//  ByteView
//
//  Created by kiri on 2021/9/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

/// 临时兼容rx，后面会删除
final class RxTransform {
    static func completable<T>(queue: DispatchQueue = .global(), action: @escaping ((@escaping (Result<T, Error>) -> Void)) -> Void) -> Completable {
        Completable.deferred {
            Completable.create { observer in
                action({ result in
                    queue.async {
                        switch result {
                        case .success:
                            observer(.completed)
                        case .failure(let error):
                            observer(.error(error))
                        }
                    }
                })
                return Disposables.create()
            }
        }
    }

    static func single<T>(queue: DispatchQueue = .global(), action: @escaping ((@escaping (Result<T, Error>) -> Void)) -> Void) -> Single<T> {
        Single<T>.deferred {
            Single<T>.create { observer in
                action({ result in
                    queue.async {
                        switch result {
                        case .success(let obj):
                            observer(.success(obj))
                        case .failure(let error):
                            observer(.error(error))
                        }
                    }
                })
                return Disposables.create()
            }
        }
    }
}
