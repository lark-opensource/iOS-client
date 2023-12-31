import EENavigator
import Foundation
import LKCommonsLogging
import LarkContainer
import LarkFeatureGating
import LarkMessengerInterface
import LarkOPInterface
import RoundedHUD
import RxSwift
import Swinject
import WebBrowser
import WebKit
import LarkUIKit
import LarkReleaseConfig
import LarkOpenPlatform
import EcosystemWeb

// 分享，code from zhangmeng
/// 内部统一，为了不把WebViewController相关属性暴露为public，统一后删除
struct WebVCTarget: ShareH5InfoTarget {
    var isWebApp: Bool {
        webVC.isWebAppForCurrentWebpage
    }

    var appID: String? {
        webVC.appInfoForCurrentWebpage?.id
    }

    private let webVC: WebBrowser

    init(webVC: WebBrowser) {
        self.webVC = webVC
    }

    var targetVC: UIViewController {
        return webVC
    }

    var shareWebView: WKWebView {
        return webVC.webView
    }

    var commonMonitorInfo: [String: AnyHashable] {
        //  原封不动，未修改逻辑
        var info: [String: AnyHashable] = [:]
        info["url_info"] = monitorURLInfo
        return info
    }

    var monitorURLInfo: String {
        //  原封不动，未修改逻辑
        "url: host = \(webVC.webview.url?.host ?? "") path = \(webVC.webview.url?.path)"
    }

    func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?) {
        webVC.showAlert(title: title, message: message, handler: handler)
    }
}
