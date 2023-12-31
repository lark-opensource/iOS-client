//
//  TTAdSplashDelegateImpl.swift
//  LarkSplash
//
//  Created by Supeng on 2020/10/23.
//

import UIKit
import Foundation
import TTAdSplashSDK

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

final class SplashSDK: NSObject {
    private weak var splashDelegate: SplashDelegate?

    init(splashDelegate: SplashDelegate) { self.splashDelegate = splashDelegate }

    func register() { TTAdSplashManager.shareInstance()?.register(self, paramsBlock: { [:] }) }

    func displaySplash(onWindow window: UIWindow, isHotLaunch: Bool, fromIdle: Bool) {
        TTAdSplashManager.shareInstance()?.displaySplash(onWindow: window,
                                                         splashShowType: fromIdle ? .hide : .show,
                                                         isHotLaunch: isHotLaunch)
    }

    func clearCache() {
        //清除缓存资源
        TTAdSplashManager.clearResouceCache()
    }
}

extension SplashSDK: TTAdSplashDelegate {

    func request(withUrl urlString: String, responseBlock: @escaping TTAdSplashResponseBlock) {
        splashDelegate?.request(withUrl: urlString) { responseBlock($0, $1, $2) }
    }

    func splashViewWillAppear(withAdModel model: TTAdSplashModel) {
        splashDelegate?.splashViewWillAppear(withSplashID: Int64(model.splashID) ?? 0)
    }

    func splashViewDidDisappear(withAdModel model: TTAdSplashModel) { splashDelegate?.splashDidDisapper() }

    func splashDebugLog(_ log: String) { splashDelegate?.splashDebugLog(log) }

    func logoAreaHeight() -> UInt { 0 }

    func skipButtonBottomOffset(with mode: TTAdSplashBannerMode) -> UInt { 0 }

    func splashBaseUrl() -> String { "" }

    func enableSplashLog() -> Bool { true }

    func displayContentMode() -> TTAdSplashDisplayContentMode { .scaleAspectFill }

    func splashAction(withCondition condition: [AnyHashable: Any]) {
        splashDelegate?.splashAction(withCondition: condition)
    }

    func isSupportLandscape() -> Bool { UIDevice.current.userInterfaceIdiom == .pad }

    func track(withTag tag: String, label: String, extra: [AnyHashable: Any]) {
        splashDelegate?.track(withTag: tag, label: label, extra: extra)
    }
}
