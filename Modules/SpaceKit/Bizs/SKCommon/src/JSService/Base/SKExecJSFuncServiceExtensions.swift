//
//  SKExecJSFuncServiceExtensions.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/7/19.
//  


import SKFoundation
import RxSwift
import HandyJSON
import SKInfra

public enum SKExecJSError: Error {
    case parseError
    case dataNil
}

// MARK: - rx 相关的接口
public extension SKExecJSFuncService {
    
    /// 利用 rx 接口调用，并使用 Codable 去解析
    func rxCallFuctionWithCodable<T: Codable>(_ function: DocsJSCallBack, params: [String: Any], defaultValueWhenDataNil: T? = nil) -> Observable<T> {
        return rxCallFuction(function, params: params, parseData: Self.parseCodable, defaultValueWhenDataNil: defaultValueWhenDataNil)
    }
    /// 利用 rx 接口调用，并使用 HandyJSON 去解析
    func rxCallFuctionWithHandyJSON<T: HandyJSON>(_ function: DocsJSCallBack, params: [String: Any], defaultValueWhenDataNil: T? = nil) -> Observable<T> {
        return rxCallFuction(function, params: params, parseData: Self.parseHandyJSON, defaultValueWhenDataNil: defaultValueWhenDataNil)
    }
    /// 利用 rx 接口调用，并解析返回数据
    func rxCallFuction<T>(_ function: DocsJSCallBack,
                          params: [String: Any],
                          parseData: @escaping ((Any) -> T?),
                          defaultValueWhenDataNil: T? = nil) -> Observable<T> {
        return Observable<T>.create({ [weak self] (ob) -> Disposable in
            self?.callFuntionWithParse(function, params: params,
                                       parseData: parseData,
                                       defaultValueWhenDataNil: defaultValueWhenDataNil) { result in
                switch result {
                case .success(let obj):
                    ob.onNext(obj)
                case .failure(let error):
                    ob.onError(error)
                }
                ob.onCompleted()
            }
            return Disposables.create()
        })
    }
}
    
// MARK: - 非 rx 相关的接口
public extension SKExecJSFuncService {
    
    /// 调用 js ，并且解析数据
    /// - Parameters:
    ///   - function: 调用的方法
    ///   - params: 调用的参数
    ///   - parseData: 根据返回的数据解析成对应的返回类型
    ///   - defaultValueWhenDataNil: 当 data 为 nil，如果有传该参数为nil 时会抛出 dataNil 的错误。
    ///   - completion: 结果回调
    func callFuntionWithParse<T>(_ function: DocsJSCallBack,
                                 params: [String: Any],
                                 parseData: @escaping ((Any) -> T?),
                                 defaultValueWhenDataNil: T? = nil,
                                 completion: ((Result<T, Error>) -> Void)?) {
        self.callFunction(function, params: params) { data, error in
            DocsLogger.debug("callFuntionWithParse js \(function.rawValue) params: \(params) data: \((data as? [String: Any])?.jsonString ?? "")")
            if let error = error {
                DocsLogger.error("callFuntionWithParse js \(function.rawValue) failed, params: \(params), error: \(error.localizedDescription)")
                completion?(.failure(error))
            } else if let data = data {
                guard let obj = parseData(data) else {
                    DocsLogger.error("callFuntionWithParse js \(function.rawValue) parse failed, params: \(params), data: \(data)")
                    completion?(.failure(SKExecJSError.parseError))
                    return
                }
                completion?(.success(obj))
            } else {
                guard let objc = defaultValueWhenDataNil else {
                    DocsLogger.error("callFuntionWithParse js \(function.rawValue), params: \(params), data is nil")
                    completion?(.failure(SKExecJSError.dataNil))
                    return
                }
                completion?(.success(objc))
            }
        }
    }
    /// 调用 js，并用 Codable 解析
    func callFuctionWithCodable<T: Codable>(_ function: DocsJSCallBack,
                                            params: [String: Any],
                                            defaultValueWhenDataNil: T? = nil,
                                            completion: ((Result<T, Error>) -> Void)?) {
        self.callFuntionWithParse(function, params: params, parseData: Self.parseCodable,
                                  defaultValueWhenDataNil: defaultValueWhenDataNil, completion: completion)
    }
    /// 调用 js，并用 HandyJSON 解析
    func callFuctionWithHandyJSON<T: HandyJSON>(_ function: DocsJSCallBack,
                                                  params: [String: Any],
                                                  defaultValueWhenDataNil: T? = nil,
                                                  completion: ((Result<T, Error>) -> Void)?) {
        self.callFuntionWithParse(function, params: params, parseData: Self.parseHandyJSON,
                                  defaultValueWhenDataNil: defaultValueWhenDataNil, completion: completion)
    }
}

// MARK: - private
public extension SKExecJSFuncService {
    /// 解析 codable
    static func parseCodable<T: Codable>(_ data: Any) -> T? {
        if let jsonData = (data as? [String: Any])?.json,
           let obj = try? JSONDecoder().decode(T.self, from: jsonData) {
            return obj
        } else {
            return nil
        }
    }
    /// 解析 handyJSOn
    static func parseHandyJSON<T: HandyJSON>(_ data: Any) -> T? {
        if let dataDic = data as? [String: Any],
           let obj = T.deserialize(from: dataDic) {
            return obj
        } else {
            return nil
        }
    }
    
    /// 解析 FastDecodable
    static func parseFastDecodable<T: SKFastDecodable>(_ data: Any) -> T? {
        if let dataDic = data as? [String: Any] {
            return T.convert(from: dataDic)
        } else {
            return nil
        }
    }
}
