//
//  SearchPickerDebugViewController.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/23.
//

#if !LARK_NO_DEBUG
import UIKit
import JavaScriptCore
import WebKit
import LarkSearchCore
import SnapKit
import LarkModel
import LarkContainer

// swiftlint:disable all
class PickerDebugContainer {
    static let shared = PickerDebugContainer()

    var config = PickerDebugConfig(
        featureConfig: PickerFeatureConfig(
            multiSelection: .init(isOpen: true),
            navigationBar: .init(title: "Demo", closeColor: .red, canSelectEmptyResult: false, sureColor: .blue),
            searchBar: .init(hasBottomSpace: false, autoFocus: true)
        ),
        searchConfig: PickerSearchConfig(entities: [
//            PickerConfig.ChatterEntityConfig(talk: .all, resign: .all),
            PickerConfig.ChatEntityConfig(tenant: .inner)
//            PickerConfig.DocEntityConfig(),
//            PickerConfig.UserGroupEntityConfig(userGroupVisibilityType: .ccm),
//            PickerConfig.WikiEntityConfig(),
//            PickerConfig.WikiSpaceEntityConfig()
        ], permission: [.checkBlock]),
        contactConfig: PickerContactViewConfig(entries: [
            PickerContactViewConfig.OwnedGroup(),
            PickerContactViewConfig.External(),
            PickerContactViewConfig.Organization(),
            PickerContactViewConfig.UserGroup()
        ]),
        disablePrefix: "",
        forceSelectPrefix: ""
    )
}

class SearchPickerWebController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    let userResolver: LarkContainer.UserResolver
    var webView: WKWebView!
//    var url: String { "http://localhost:3000/" }
    var url: String { "https://tosv.byted.org/obj/tos-lark-components-demo/picker/709/index.html" }
    var path: String { "" }
    var initializeFunc: String { "initUIConfig" }
    var jsonString: String = ""
    var source: String = ""

    @objc
    private func onClick() {
        self.navigationController?.dismiss(animated: true)
    }

    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.navigationItem.title = "Picker Demo"
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(onClick))
        view.backgroundColor = .white
        loadReactPage()
    }
    func loadReactPage() {
        let config = WKWebViewConfiguration()
        if let data = try? JSONEncoder().encode(PickerDebugContainer.shared.config),
           let configString = String(data: data, encoding: .utf8) {
            let scriptSource = """
window.__INITIAL_DATA__ = \(configString);
"""
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            config.userContentController.addUserScript(userScript)
        }
        config.userContentController.add(self, name: "openPicker")
        config.userContentController.add(self, name: "close")
        webView = WKWebView(frame: .zero, configuration: config)
#if swift(>=5.8)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
#endif
        let url = URL(string: url + path) ?? .init(fileURLWithPath: "")
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        webView.load(request)
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

//        webView.evaluateJavaScript("window.pickerCallback") { (res, error) in
//
//        }
    }
    func handleFormResult(data: String) {

    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "close" {
            self.navigationController?.dismiss(animated: true)
        } else if message.name == "openPicker" {
            if let configString = message.body as? String,
               let data = configString.data(using: .utf8) {
                do {
                    let config = try JSONDecoder().decode(PickerDebugConfig.self, from: data)
                    PickerDebugContainer.shared.config = config
                    if config.style == .search {
                        pushPicker(config: config)
                    } else {
                        presentPicker(config: config)
                    }
                } catch {
                    print("js data error: \(error)")
                }
            }
        }
    }

    private func presentPicker(config: PickerDebugConfig) {
        let pickerVC = SearchPickerNavigationController(resolver: self.userResolver)
        pickerVC.pickerDelegate = self
        pickerVC.featureConfig = config.featureConfig
        pickerVC.searchConfig = config.searchConfig
        pickerVC.defaultView = getDefaultView(config: config)
        self.present(pickerVC, animated: true)
    }

    private func pushPicker(config: PickerDebugConfig) {
        let pickerVC = SearchPickerViewController(resolver: self.userResolver)
        pickerVC.pickerDelegate = self
        pickerVC.featureConfig = config.featureConfig
        pickerVC.searchConfig = config.searchConfig
        pickerVC.defaultView = getDefaultView(config: config)
        navigationController?.pushViewController(pickerVC, animated: true)
    }

    private func getDefaultView(config: PickerDebugConfig) -> PickerDefaultViewType? {
        switch config.recommendType {
        case .contact:
            let contactView = PickerContactView(resolver: self.userResolver)
            contactView.config = config.contactConfig
            return contactView
        case .search:
            let recommendView = PickerRecommendListView(resolver: self.userResolver)
            return recommendView
        default: return nil
        }
    }
}

extension SearchPickerWebController: SearchPickerDelegate {
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        print(" finish")
        return true
    }
    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool {
        print(" cancel")
        return true
    }

    func pickerDidDismiss(pickerVc: SearchPickerControllerType) {
        print(" dismiss")
    }
}
// swiftlint:enable all
#endif
