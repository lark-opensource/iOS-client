import ECOInfra
import EcosystemWeb
import HTTProtocol
import LarkContainer
import LarkWebViewContainer
import UIKit
import WebKit
class LarkWebViewWithHTTPWKURLSchemeHandler: UIViewController {
    private var webView: LarkWebView { view as! LarkWebView }
    override func loadView() {
        let config = LarkWebViewConfigBuilder()
            .setMonitorConfig(LarkWebViewMonitorConfig(
                enableMonitor: true,
                enableInjectJS: true
            ))
            .build(
                bizType: .init("Demo"),
                isAutoSyncCookie: true,
                performanceTimingEnable: true,
                advancedMonitorInfoEnable: true
            )
        config.webViewConfig.registerIntercept(schemes: offline_v2_schemes(), delegate: DemoResourceIntercept())
        let larkWebView = LarkWebView(
            frame: .zero,
            config: config
        )
        view = larkWebView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let request = URLRequest(url: URL(string: "http://lark-webview-demo.web.bytedance.net")!)
        webView.load(request)
    }
}

class DemoResourceIntercept: WKResourceInterceptProtocol {
    func shouldInterceptRequest(webView: WKWebView, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else {
                if let response = response, let data = data {
                    completionHandler(.success((response, data)))
                } else {
                    completionHandler(.failure(NSError(domain: "WebAppResourceIntercept", code: -1)))
                }
            }
        }
        task.resume()
    }
    
    var jssdk: String = ""
}
