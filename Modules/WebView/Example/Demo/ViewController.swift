//
//  ViewController.swift
//  Demo
//
//  Created by tefeng liu on 2020/10/30.
//

import UIKit
import LarkWebViewContainer
import LarkWebviewNativeComponent

class ViewController: UIViewController {
    var webview: LarkWebView!

    let localPath = "/Users/minguangliu/Desktop/ByteDanceCode/lark-native-components/examples/test.html"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // LarkWebView
        webview = LarkWebView(frame: self.view.bounds, config: LarkWebViewConfig(), parentTrace: nil)
        LarkWebviewNativeComponent.enableNativeRender(webview: webview, compenents: [NativeAvatarComponent.self])

        self.view.addSubview(webview)

        let button = UIButton(frame: CGRect(x: 200, y: 50, width: 88, height: 88))
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(handleReload), for: .touchUpInside)
        view.addSubview(button)

        if localPath.count > 0 {
            let url = URL(fileURLWithPath: localPath)
            self.webview.loadFileURL(url,
                                     allowingReadAccessTo: url.deletingLastPathComponent().deletingLastPathComponent())
        } else {
            if let res = Bundle.main.path(forResource: "Resource/test", ofType: "html") {
                let url = URL(fileURLWithPath: res)
                self.webview.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        }
    }

    @objc
    func handleReload() {
        let url = URL(fileURLWithPath: localPath)
        self.webview.loadFileURL(url,
                                 allowingReadAccessTo: url.deletingLastPathComponent().deletingLastPathComponent())
    }
}

