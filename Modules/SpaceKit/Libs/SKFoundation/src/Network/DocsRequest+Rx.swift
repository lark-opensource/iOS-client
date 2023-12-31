//
//  DocsRequest+Rx.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/13.
//  

import Foundation
import RxSwift

extension DocsRequest {

    // 只关心 ResultData，不关心原始 Data、Response 和 Error
    public func rxStart() -> Single<ResponseData?> {
        return Single<ResponseData?>.create { single in
            self.start { (result, error) in
                if let error = error {
                    single(.error(error))
                } else {
                    single(.success(result))
                }
            }
            return Disposables.create {
                self.cancel()
            }
        }
    }

    // 只关心 ResultData，不关心原始 Data、Response 和 Error
    public func rxStartWithLogID() -> Single<(ResponseData?, String?)> {
        return Single<(ResponseData?, String?)>.create { single in
            self.start { [weak self] (result, error) in
                if let error = error {
                    single(.error(error))
                } else {
                    single(.success((result, self?.responseLogID)))
                }
            }
            return Disposables.create {
                self.cancel()
            }
        }
    }

    // 需要处理原始 Data 或 Response，不关心 Error
    public func rxData() -> Single<(Data?, URLResponse?)> {
        return Single<(Data?, URLResponse?)>.create { single in
            self.start { (data, response, error) in
                if let error = error {
                    single(.error(error))
                } else {
                    single(.success((data, response)))
                }
            }
            return Disposables.create {
                self.cancel()
            }
        }
    }

    // 需要 ResultData 和 Error，不关心 Response
    public func rxResponse() -> Single<(ResponseData?, Error?)> {
        return Single<(ResponseData?, Error?)>.create { single in
            self.start { (result, error) in
                single(.success((result, error)))
            }
            return Disposables.create {
                self.cancel()
            }
        }
    }

//    // 需要处理原始的 Data、Resposne 和 Error
//    public func rxRawResponse() -> Single<(Data?, URLResponse?, Error?)> {
//        return Single<(Data?, URLResponse?, Error?)>.create { single in
//            self.start { (data, response, error) in
//                single(.success((data, response, error)))
//            }
//            return Disposables.create {
//                self.cancel()
//            }
//        }
//    }
}
