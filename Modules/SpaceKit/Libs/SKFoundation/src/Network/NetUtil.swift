//
//  NetUtil.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/26.
//

import Foundation

public final class NetUtil {
    public static var shared: NetUtil = NetUtil()

//    https://forums.developer.apple.com/thread/65416
    func QCFNetworkCopySystemProxySettings() -> CFDictionary? {
        guard let proxiesSettingsUnmanaged = CFNetworkCopySystemProxySettings() else {
            return nil
        }
        return proxiesSettingsUnmanaged.takeRetainedValue()
    }

    func QCFNetworkCopyProxiesForURL(_ url: URL, _ proxiesSettings: CFDictionary) -> [[String: AnyObject]] {
        let proxiesUnmanaged = CFNetworkCopyProxiesForURL(url as CFURL, proxiesSettings)
        let proxies = proxiesUnmanaged.takeRetainedValue()
        return proxies as? [[String: AnyObject]] ?? []
    }

    public func getProxyHostFor(_ urlStr: String) -> String? {
        guard let myUrl = URL(string: urlStr) else {
            return nil
        }
        guard let proxySettings = QCFNetworkCopySystemProxySettings() else { return nil }
        //手机真机设置代理
        //                [["kCFProxyTypeKey": kCFProxyTypeHTTPS, "kCFProxyHostNameKey": 10.94.12.8, "kCFProxyPortNumberKey": 8888]]
        // 手机真机不设置代理
        //                [["kCFProxyTypeKey": kCFProxyTypeNone]]
        //手机设置vpn
        //                [["kCFProxyTypeKey": kCFProxyTypeNone]]
        // 模拟器，没开charles
        //                [["kCFProxyTypeKey": kCFProxyTypeNone]]
        // 模拟器，打开了charles
        //[["kCFProxyHostNameKey": 127.0.0.1, "kCFProxyTypeKey": kCFProxyTypeHTTPS, "kCFProxyPortNumberKey": 8888]]
        let proxies = QCFNetworkCopyProxiesForURL(myUrl, proxySettings)

        guard let proxy = proxies.first(where: { (proxyDict) -> Bool in
            return proxyDict[kCFProxyHostNameKey as String] != nil
        }) else {
            return nil
        }
        guard let type = proxy[kCFProxyTypeKey as String] as? String,
            let host = proxy[kCFProxyHostNameKey as String] as? String,
            let port = proxy[kCFProxyPortNumberKey as String] as? Int else {
                return nil
        }
        guard type == kCFProxyTypeHTTP as String || type == kCFProxyTypeHTTPS as String else {
            return nil
        }
        return "http://" + host + ":\(port)"
    }

    public func isUsingProxyFor(_ urlStr: String) -> Bool {
        return getProxyHostFor(urlStr) != nil
    }

    public func netDebugLog(_ msg: @autoclosure () -> String ) {
//        DocsLogger.info(msg(), component: LogComponents.net)
    }
}

//func QCFNetworkCopySystemProxySettings() -> CFDictionary? {
//    guard let proxiesSettingsUnmanaged = CFNetworkCopySystemProxySettings() else {
//        return nil
//    }
//    return proxiesSettingsUnmanaged.takeRetainedValue()
//}
//
//func QCFNetworkCopyProxiesForURL(_ url: URL, _ proxiesSettings: CFDictionary) -> [[String:AnyObject]] {
//    let proxiesUnmanaged = CFNetworkCopyProxiesForURL(url as CFURL, proxiesSettings)
//    let proxies = proxiesUnmanaged.takeRetainedValue()
//    return proxies as! [[String:AnyObject]]
//}
//
//if let myUrl = URL(string: "http://www.apple.com") {
//    if let proxySettings = QCFNetworkCopySystemProxySettings() {
//        let proxies = QCFNetworkCopyProxiesForURL(myUrl, proxySettings)
//        print(proxies)
//    }
//}
