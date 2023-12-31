//
//  FeatureGatingDatasourceDefaultImpl.swift
//  LarkSetting
//
//  Created by 王元洵 on 2023/3/1.
//

import LarkRustClient
import Swinject
import RustPB
import LarkRustFG
import LarkFoundation
import LKCommonsLogging

final class FeatureGatingDatasourceDefaultImpl {

    private static let logger = Logger.log(FeatureGatingDatasourceDefaultImpl.self, category: "FeatureGatingDatasource")

    private func rustService(with id: String) -> RustService? {
        try? Container.shared.getUserResolver(userID: id, type: .both).resolve(assert: RustService.self)
    }
}

extension FeatureGatingDatasourceDefaultImpl: FeatureGatingDatasource {
    func fetchImmutableFeatureGating(with id: String) {
        _ = rustService(with: id)?
            .sendAsyncRequest(Behavior_V1_GetABExperimentFeatureMapRequest())
            .subscribe(onNext: { (response: Behavior_V1_GetABExperimentFeatureMapResponse) in
                FeatureGatingStorage.updateStaticCache(with: Set(response.featureWithAbMap.keys), and: id)
            })
    }
    
    func fetchImmutableFeatureGating(with id: String, and key: String) throws -> Bool { try getImmutableFeatureGating(userid: id, key: key) }

    func fetchGlobalFeatureGating(deviceID: String) {
        Self.logger.debug("start fetchGlobalFeatureGating, deviceId: \(deviceID)")
        DispatchQueue.global(qos: .background).async {
            Self.logger.debug("fetchGlobalFeatureGating get deviceID: \(deviceID)")
            let settingRequester = SettingRequester(deviceID: deviceID)
            settingRequester.execute()
        }
    }
}


class SettingRequester {

    private static let logger = Logger.log(SettingRequester.self, category: "SettingRequester")
    private let maxiumRetryCount: Int
    private let initialDelay: TimeInterval
    private var currentRetryCount = 0
    private let deviceID: String


    init(deviceID: String, maxiumRetryCount: Int = 3, initialDelay: TimeInterval = 1.0) {
        self.deviceID = deviceID
        self.maxiumRetryCount = maxiumRetryCount
        self.initialDelay = initialDelay
    }

    func settingURL() -> URLComponents? {
        guard let baseURL = DomainSettingManager.shared.currentSetting[.api]?.first else { return nil }
        var url = baseURL
        if !url.hasPrefix("http") {
            url = "https://" + baseURL
        }
        if url.hasSuffix("/") {
            url += "settings/v3"
        }else {
            url += "/settings/v3"
        }
        let params: [String: String] = [
            "device_id": deviceID,
            "platform": UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone",
            "version": LarkFoundation.Utils.appVersion,
            "tag": "NO_USER_FG"
        ]
        var settingRequest = URLComponents.init(string: url)
        settingRequest?.queryItems = params.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }
        return settingRequest
    }

    func execute() {
        guard let settingURL = settingURL()?.url else { return }
        Self.logger.debug("fetchGlobalFeatureGating Settings url is: \(settingURL)")
        let retryManager = RetryManager()
        var request = URLRequest(url: settingURL)
        request.httpMethod = "GET"
        retryManager.execute({ completion in
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data{
                    completion(.success(data))
                }else if let error = error {
                    completion(.failure(error))
                }
            }.resume()
        }, onSuccess: { data in
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let settings: [String: Any] = jsonResponse["data"] as? [String: Any],
                   let globalFeatureGatingService = Container.shared.resolve(GlobalFeatureGatingService.self) {
                    let globalfeatureGatings = settings.compactMapValues{ $0 as? Bool }
                    Self.logger.debug("CommonSettingLaunchTask get globalfeatureGatings: \(globalfeatureGatings)")
                    globalFeatureGatingService.update(new: globalfeatureGatings)
                }else {
                    Self.logger.error("fetchGlobalFeatureGating JSONSerialization transform error")
                }
            } catch {
                Self.logger.error("fetchGlobalFeatureGating error occurred: \(error)")
            }
        }, onFailure: { error in
            Self.logger.error("fetchGlobalFeatureGating http error: \(error)")
        })
    }
}


class RetryManager {
    private let maximumRetryCount: Int
    private let initialDelay: TimeInterval
    private var currentRetryCount = 0

    init(maximumRetryCount: Int = 3, initialDelay: TimeInterval = 0.0) {
        self.maximumRetryCount = maximumRetryCount
        self.initialDelay = initialDelay
    }

    func execute(_ task: @escaping (_ completion: @escaping (Result<Data, Error>) -> Void) -> Void,
                 onSuccess: @escaping (Data) -> Void,
                 onFailure: @escaping (Error) -> Void) {

        task { [weak self] result in
            switch result {
            case .success(let data):
                onSuccess(data)
            case .failure(let error):
                if let self = self, self.currentRetryCount < self.maximumRetryCount {
                    self.currentRetryCount += 1
                    let delay = self.initialDelay * pow(2.0, Double(self.currentRetryCount))
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.execute(task, onSuccess: onSuccess, onFailure: onFailure)
                    }
                } else {
                    onFailure(error)
                }
            }
        }
    }
}
