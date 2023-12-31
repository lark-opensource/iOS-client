//
//  DocsFeedViewModel+Observable.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/18.
//  


import RxSwift
import SKFoundation

// MARK: - 模型处理

extension Observable where Element == [[String: Any]] {
    
    enum MapError: Error {
        case deserializeError
    }
    
    func mapFeedModel<T: Codable>(type: T.Type, queue: DispatchQueue) -> Observable<T> {
        return flatMap { (parameters) -> RxSwift.Observable<T> in
            return RxSwift.Observable<T>.create { (ob) -> Disposable in
                queue.async {
                    var decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                        DocsLogger.feedError("mapFeedModel serialization error")
                        return
                    }
                    do {
                        let models = try decoder.decode(T.self, from: data)
                        ob.onNext(models)
                    } catch {
                        DocsLogger.feedError("requestFeedData new deserialize error:\(error)")
                        ob.onError(MapError.deserializeError)
                    }
                }
                return Disposables.create {}
            }
        }
    }
}
