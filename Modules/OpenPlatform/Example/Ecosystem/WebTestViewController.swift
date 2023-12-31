import AnimatedTabBar
import ECOInfra
import EcosystemWeb
import EENavigator
import LarkNavigator
import LarkTab
import LarkUIKit
import RxRelay
import UIKit
import WebKit
class WebTestViewController: UITableViewController, TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate, LarkNaviBarAbility {
    var tab: Tab { Tab.feed }
    var controller: UIViewController { self }
    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Web测试入口控制器") }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }
    lazy var ds: [(String, () -> ())] = [
        ("占位置", {}),
        ("WKURLSchemeHandler 拦截 http(s) 调研", {
            Navigator.shared.showDetailOrPush(LarkWebViewWithHTTPWKURLSchemeHandler(), wrap: LkNavigationController.self, from: self)
        }),
        ("套件统一浏览器测试", {
            let alert = UIAlertController(title: "打开套件统一浏览器", message: "请输入网址，请注意，不符合URL规范在统一工程会导致崩溃", preferredStyle: .alert)
            alert.addTextField()
            alert.textFields?.first?.text = "https://lark-webview-demo.web.bytedance.net"
            alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak alert] action in
                Navigator.shared.showDetailOrPush(URL(string: alert?.textFields?.first?.text ?? "")!, wrap: LkNavigationController.self, from: self)
            }))
            alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { action in
            }))
            self.present(alert, animated: true)
        }),
        ("appID法打开网页应用", {
            let alert = UIAlertController(title: "appID法打开网页应用", message: "请输入appID", preferredStyle: .alert)
            alert.addTextField()
            alert.textFields?.first?.text = "cli_a13693c2c07bd00b"
            alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak alert] action in
                WebAppIntegratedSoftwareDevelopmentKit.fetchWebAppBrowser(appID: alert?.textFields?.first?.text ?? "", initTrace: nil, startHandleTime: nil) { result in
                    switch result {
                    case .success(let browser):
                        Navigator.shared.showDetailOrPush(browser, wrap: LkNavigationController.self, from: self)
                    case .failure(let error):
                        print(error)
                    }
                }
            }))
            alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { action in
            }))
            self.present(alert, animated: true)
        }),
        ("present套件统一浏览器", {
            let alert = UIAlertController(title: "present套件统一浏览器", message: "请输入网址，请注意，不符合URL规范在统一工程会导致崩溃", preferredStyle: .alert)
            alert.addTextField()
            alert.textFields?.first?.text = "https://lark-webview-demo.web.bytedance.net"
            alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak alert] action in
                Navigator.shared.present(URL(string: alert?.textFields?.first?.text ?? "")!, from: self)
            }))
            alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { action in
            }))
            self.present(alert, animated: true)
        }),
        ("清除WKWebView缓存", {
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {
                print("清除WKWebView缓存结束")
            }
        }),
        ("查看HTTPCookieStorage", {
            print(HTTPCookieStorage.shared.cookies)
        }),
        ("查看WKHTTPCookieStore", {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                print(cookies)
            }
        }),
        ("print openplatform_error_page_info settings", {
            print(ECOConfig.service().getDictionaryValue(for: "openplatform_error_page_info"))
        }),
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        let top = naviHeight + UIApplication.shared.statusBarFrame.height
        tableView.contentInset = UIEdgeInsets(top: top, left: 0.0, bottom: 0.0, right: 0.0)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ds.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = ds[indexPath.row].0
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {tableView.deselectRow(at: indexPath, animated: true)}
        ds[indexPath.row].1()
    }
}
