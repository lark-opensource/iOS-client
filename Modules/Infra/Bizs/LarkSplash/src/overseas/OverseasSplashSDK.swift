//
//  TTAdSplashDelegateImpl.swift
//  LarkSplash
//
//  Created by Supeng on 2020/10/23.
//

import UIKit
import Foundation
import BDASplashSDKI18N

/// SplashSDK的代理，回调开屏事件
public protocol SplashDelegate: AnyObject {
    /// 请求数据
    func request(withUrl urlString: String, responseBlock: @escaping (Data?, Error?, NSInteger) -> Void)
    /// 开屏页面将要展示
    func splashViewWillAppear(withSplashID id: Int64)
    /// 开屏页面结束展示
    func splashDidDisapper()
    /// 开屏SDK log输出
    func splashDebugLog(_ log: String)
    /// 开屏点击事件
    func splashAction(withCondition condition: [AnyHashable: Any])
    /// 埋点上报
    func track(withTag tag: String, label: String, extra: [AnyHashable: Any])
}

class SplashSDK: NSObject {
    private weak var splashDelegate: SplashDelegate?

    init(splashDelegate: SplashDelegate) { self.splashDelegate = splashDelegate }

    func register() {
        SplashLogger.shared.info(event: "overseas splash register")
        let config = [kBDASplashPickMode: 0]
        let params = [kBDASplashAppName: ""]
        BDASplashManager.sharedInstance()?.register(withDelete: self, config: config, params: params)
    }

    func displaySplash(onWindow window: UIWindow, isHotLaunch: Bool, fromIdle: Bool) {
        BDASplashManager.sharedInstance()?.tryFetchAdInfo()
        SplashLogger.shared.info(event: "overseas display splash fromIdle:\(fromIdle)")
        if !fromIdle {
            SplashLogger.shared.info(event: "overseas display splash on window")
            let model = BDASplashManager.sharedInstance()?.pickBrandAD({ (_) -> Bool in
                return true
            }, isWarmStart: isHotLaunch)
            if model != nil { // model为空时不展示开屏, 无需显示window
                window.makeKeyAndVisible()
            }
            BDASplashManager.sharedInstance()?.displaySplash(on: window)
        }
    }

    func clearCache() {
        BDASplashManager.sharedInstance()?.clearSplashDataCache()
    }
}

extension SplashSDK: TTAdSplashDelegate {
    func splashLogoView(with color: BDASplashLogoColor) -> UIView? {
        return nil
    }

    func splashBGView(withFrame frame: CGRect) -> UIView? {
        return nil
    }

    func splashFakeLaunchView() -> UIView? {
        return nil
    }

    func splashAction(withCondition condition: [AnyHashable : Any]?, animationBlock: BDASplashAnimationBlock? = nil) {
        splashDelegate?.splashAction(withCondition: condition ?? [:])
    }

    func trackURLs(_ URLs: [Any]?, dict trackDict: [AnyHashable : Any]?) { }

    func trackMonitorService(_ service: String?, metric: [AnyHashable : Any]?, category: [AnyHashable : Any]?, extra: [AnyHashable : Any]?) { }

    func request(withUrl urlString: String?, requestType: BDASplashRequestType, method: BDAdSplashRequestMethod, headers: [AnyHashable : Any]?, body: [AnyHashable : Any]?, param: [AnyHashable : Any]?, responseBlock: BDAdSplashResponseBlock? = nil) {
        SplashLogger.shared.info(event: "overseas request splash data")
        let defaultError = NSError(domain: "", code: 0)
        splashDelegate?.request(withUrl: urlString ?? "") { responseBlock?($0 ?? Data(), $1 ?? defaultError, $2) }
    }

    func splashViewWillAppear(withAdModel model: TTAdSplashModel?) {
        SplashLogger.shared.info(event: "overseas splash view will appear")
        splashDelegate?.splashViewWillAppear(withSplashID: Int64(model?.splashID ?? "") ?? 0)
    }

    func splashViewDidDisappear(withAdModel model: TTAdSplashModel?) {
        SplashLogger.shared.info(event: "overseas splash view did disappear")
        splashDelegate?.splashDidDisapper()
    }

    func splashDebugLog(_ log: String?) { splashDelegate?.splashDebugLog(log ?? "") }

    func logoAreaHeight() -> UInt { 0 }

    func skipButtonBottomOffset(with mode: TTAdSplashBannerMode) -> UInt { 0 }

    func splashBaseUrl() -> String? { "" }

    func enableSplashLog() -> Bool { true }

    func isSupportLandscape() -> Bool { UIDevice.current.userInterfaceIdiom == .pad }

    func track(withTag tag: String?, label: String?, extra: [AnyHashable: Any]?) {
        splashDelegate?.track(withTag: tag ?? "", label: label ?? "", extra: extra ?? [:])
    }
}
