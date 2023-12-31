//
//  RxDocsRequest.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/23.
//

import Foundation
import Alamofire
import RxSwift

@available(*, deprecated, message: "Using DocsRequest.rxXXX method instead")
public final class RxDocsRequest<T> {
    public init() {}
    var request: DocsRequest<T>?
    public func request(_ path: String,
                 params: Params? = nil,
                 method: DocsHTTPMethod = .GET,
                 encoding: ParamEncodingType = .urlEncodeDefault,
                 headers: [String: String]? = nil,
                 needVerifyData: Bool = true,
                 callbackQueue: DispatchQueue = .main,
                 timeout: Double? = nil) -> Observable<T?> {
        let request = DocsRequest<T>(path: path, params: params)
        if let timeout = timeout {
            request.set(timeout: timeout)
        }
        self.request = request
        return Observable<T?>.create({ (observer) -> Disposable in
            if let header = headers {
                request.set(headers: header)
            }
            request.set(method: method)
                .set(encodeType: encoding)
                .set(needVerifyData: needVerifyData)
                .start(callbackQueue: callbackQueue, result: { (result, error) in
                    if let error = error {
                        observer.on(.error(error))
                    } else {
                        observer.onNext(result)
                        observer.onCompleted()
                    }
                })
            return Disposables.create {
                request.cancel()
            }
        })
    }
}
