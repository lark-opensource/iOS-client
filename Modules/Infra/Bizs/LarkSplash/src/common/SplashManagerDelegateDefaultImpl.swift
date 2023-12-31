//
//  SplashManagerDelegateDefaultImpl.swift
//  LarkSplash
//
//  Created by Supeng on 2020/10/23.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker
import EENavigator
import LarkStorage
import LarkRustClient
import LarkContainer
import ServerPB
import LarkCombine

final class SplashManagerDelegateDefaultImpl: SplashDelegate {
    static let shared = SplashManagerDelegateDefaultImpl()

    @KVConfig(key: KVKeys.Splash.lastSplashDataTime, store: KVStores.splash)
    private var lastSplashDataTime

    @KVConfig(key: KVKeys.Splash.lastSplashAdID, store: KVStores.splash)
    private var lastSplashAdID

    @KVConfig(key: KVKeys.Splash.hasSplashData, store: KVStores.splash)
    private var hasSplashData

    private var anyCancellable = Set<AnyCancellable>()

    private var linkDisplayWindows: UIWindow? = {
        if #available(iOS 13.0, *),
           let sceneDelegate = SplashManager.shareInstance.window.windowScene?.delegate as? UIWindowSceneDelegate,
           let rootWindow = sceneDelegate.window?.map({ $0 }) {
            return rootWindow
        } else {
            return UIApplication.shared.delegate?.window?.map { $0 }
        }
    }()

    // swiftlint:disable function_body_length
    func request(withUrl urlString: String,
                 responseBlock: @escaping (Data?, Error?, NSInteger) -> Void) {
        // sdk请求JSON配置，走serverPB
        let logger = SplashLogger.shared

        if urlString.contains("api/ad/splash//v15/") {
            guard let client = (try? Container.shared.getUserResolver(userID: SplashManager.shareInstance.userID).resolve(assert: RustService.self)) else {
                responseBlock(nil, nil, 400)
                return
            }
            logger.info(event: "begin fetch config-v15")
            Tracker.post(TeaEvent(Homeric.SPLASH_AD_PULL_REQUEST_DEV, params: ["stage": "start"]))
            var request = ServerPB.ServerPB_Ad_PullSplashADRequest()
            request.lastSplashAdID = self.lastSplashAdID ?? 0
            client.sendPassThroughAsyncRequestWithCombine(request,
                                                               serCommand: .pullSplashAd)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        logger.error(event: "fetch config failed", params: error.localizedDescription)
                        self.hasSplashData = false
                        responseBlock(nil, nil, 400)
                    @unknown default:
                        fatalError("should never have unknown case!")
                    }
                }, receiveValue: { (response: ServerPB.ServerPB_Ad_PullSplashADResponse) in
                    logger.info(event: "fetch config success")
                    responseBlock(response.splash, nil, 200)
                    Tracker.post(TeaEvent(Homeric.SPLASH_AD_PULL_REQUEST_DEV, params: ["stage": "success"]))

                    guard let dict = try? JSONSerialization.jsonObject(with: response.splash,
                                                                      options: .mutableContainers) as? [String: Any],
                          let config = dict["data"] as? [String: Any],
                          let splash = config["splash"] as? [Any],
                          !splash.isEmpty else {
                        logger.error(event: "parse config json failed")
                        self.hasSplashData = false
                        return
                    }
                    DispatchQueue.global().async {
                        if let theJSONData = try? JSONSerialization.data(
                            withJSONObject: config,
                            options: []),
                            let theJSONText = String(data: theJSONData,
                                                     encoding: .utf8) {
                            logger.info(event: "config result", params: theJSONText)
                        } else {
                            logger.error(event: "config result", params: "json error")
                        }
                    }
                    self.lastSplashDataTime = config["server_time"] as? TimeInterval ?? Date().timeIntervalSince1970
                    self.hasSplashData = true
                })
                .store(in: &anyCancellable)
        } else if urlString.hasPrefix("http") {
            // 其它请求走URLSession
            logger.info(event: "begin fetch config")
            guard let url = URL(string: urlString) else {
                logger.error(event: "covert to URL failed", params: "url: " + urlString)
                responseBlock(nil, nil, 400)
                return
            }
            Tracker.post(TeaEvent(Homeric.SPLASH_AD_DOWNLOAD_RESOURCE_DEV, params: ["stage": "start"]))
            let downloadStartTime = CFAbsoluteTimeGetCurrent()

            URLSession.shared.dataTask(with: .init(url: url), completionHandler: {(data, response, error) in
                if error != nil {
                    logger.error(event: "fetch config failed", params: "url: \(urlString), error: \(error?.localizedDescription)")
                    responseBlock(data, error, (response as? HTTPURLResponse)?.statusCode ?? 400)
                } else {
                    logger.info(event: "fetch config success")
                    let downloadEndTime = (CFAbsoluteTimeGetCurrent() - downloadStartTime) * 1_000
                    Tracker.post(TeaEvent(Homeric.SPLASH_AD_DOWNLOAD_RESOURCE_DEV,
                                          params: ["stage": "success",
                                                   "download_time": downloadEndTime]))
                    responseBlock(data, nil, (response as? HTTPURLResponse)?.statusCode ?? 200)
                }
            }).resume()
        }
    }

    func splashViewWillAppear(withSplashID id: Int64) {
        SplashLogger.shared.info(event: "will appear")
        guard let lastSplashDataTime = self.lastSplashDataTime,
              Calendar.current.isDateInToday(Date(timeIntervalSince1970: lastSplashDataTime))
        else {
            SplashLogger.shared.info(event: "Not today's configuration, no display")
            return
        }

        self.lastSplashAdID = id
        Navigator.shared.mainSceneWindow?.endEditing(true) //Global
        let launchParam = SplashManager.shareInstance.isHotLaunch ? "hot_launch" : "cold_launch"
        Tracker.post(TeaEvent(Homeric.SPLASH_PAGE_VIEW,
                              params: ["launch_type": launchParam,
                                       "splash_id": id]))
        SplashLogger.shared.info(event: "splash show", params: "\(launchParam), \(id), display_at: \(Date().timeIntervalSince1970)")
        SplashManager.shareInstance.window.isHidden = false
    }

    func splashDidDisapper() {
        SplashLogger.shared.info(event: "splash disappear", params: "disapear_at: \(Date().timeIntervalSince1970)")
        SplashManager.shareInstance.window.isHidden = true
    }

    func splashDebugLog(_ log: String) {
        SplashLogger.shared.info(event: "sdk log", params: log)
    }

    func splashAction(withCondition condition: [AnyHashable: Any]) {
        guard let urlString = condition[AnyHashable("web_url")] as? String,
           let link = URL(string: urlString),
           let lastShowSplashID = condition[AnyHashable("ad_id")],
           let linkDisplayWindows = self.linkDisplayWindows else { return }
        Tracker.post(TeaEvent(Homeric.SPLASH_PAGE_CLICK, params: ["click": "confirm", "splash_id": lastShowSplashID]))
        SplashLogger.shared.info(event: "click", params: urlString)
        Navigator.shared.open(link, from: linkDisplayWindows) //Global
    }

    func track(withTag tag: String, label: String, extra: [AnyHashable: Any]) {
        guard label == "skip", let lastShowSplashID = extra[AnyHashable("ad_id")] else { return }
        SplashLogger.shared.info(event: "click cancel")
        Tracker.post(TeaEvent(Homeric.SPLASH_PAGE_SKIP_CLICK,
                              params: ["click": "confirm", "splash_id": lastShowSplashID]))
    }
}
