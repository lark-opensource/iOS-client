//
//  MeegoFeatureGatingManager.swift
//  LarkMeego
//
//  Created by mzn on 2022/10/3.
//

import Foundation
import RxSwift
import LarkContainer
import LarkFoundation
import LarkMeegoNetClient
import LarkMeegoLogger

public struct FetchFeatureGatingRequestParams {
    public var keys: [String]
    public var appName: String
    public var meegoProjectKey: String
    public var meegoUserKey: String
    public var meegoTenantKey: String

    /// init
    public init(
     keys: [String],
     appName: String,
     meegoProjectKey: String,
     meegoUserKey: String,
     meegoTenantKey: String
    ) {
        self.keys = keys
        self.appName = appName
        self.meegoProjectKey = meegoProjectKey
        self.meegoUserKey = meegoUserKey
        self.meegoTenantKey = meegoTenantKey
    }

}

/// Meego FG管理类
final class MeegoFeatureGatingManager {
    private let disposeBag = DisposeBag()

    public static let shared = MeegoFeatureGatingManager()

    private var _registedFGKeys: [String] = []

    public var registedFGKeys: [String] {
        get {
            return _registedFGKeys
        }
    }

    init() {}

    /// 更新注册的key
    func updateLocalRegistedFGKeys(with keys: [String]) {
        keys.forEach { key in
            if !_registedFGKeys.contains(key) {
                _registedFGKeys.append(key)
                MeegoLogger.debug("updateLocalRegistedFGKeys _registedFGKeys append key = \(key).")
            }
        }
    }

    func fetchFeatureGating(with params: FetchFeatureGatingRequestParams, completionHandler: @escaping (Result<Response<MGFeatureGatingResponse>, Error>) -> Void) {
        let platform = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let request = MGFeatureGatingRequest(catchError: true,
                                             appName: params.appName,
                                             meegoUserKey: params.meegoUserKey,
                                             meegoTenantKey: params.meegoTenantKey,
                                             meegoProjectKey: params.meegoProjectKey,
                                             keys: params.keys,
                                             platform: platform,
                                             version: LarkFoundation.Utils.appVersion
        )

        if let netClient = try? Container.shared.getCurrentUserResolver().resolve(type: MeegoNetClient.self) {
            netClient.sendRequest(request) { result in
                switch result {
                case .success(let response):
                    completionHandler(.success(response))
                    MeegoLogger.info("fetchFeatureGating request success, response = \(response).")
                case .failure(let error):
                    completionHandler(.failure(error))
                    MeegoLogger.warn("fetchFeatureGating request fail. error = \(error)")
                }
            }
        }
    }
}
