//
//  LKWebViewControllerTest.swift
//  LarkMessengerUnitTest
//
//  Created by JackZhao on 2020/8/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import UIKit
import WebKit

class LKWebViewControllerTest: XCTestCase {

    func testOpenQuaryEqualNumberURL() {
        let urlString = "https://www.google.com/search?q=123"
        let expectUrlString = "https://www.google.com/search?q=123"
        let expectation = self.expectation(description: "pl3131ay")
        let vc = WebViewController(urlString: urlString,
                                   expectUrlString: expectUrlString,
                                   expectation: expectation)
        vc.viewDidLoad()
        wait(for: [expectation], timeout: 3)
    }

    func testOpenQuaryEqualabcURL() {
        let urlString = "https://www.google.com/search?q=abc"
        let expectUrlString = "https://www.google.com/search?q=abc"
        let expectation = self.expectation(description: "pl3131ay")
        let vc = WebViewController(urlString: urlString,
                                   expectUrlString: expectUrlString,
                                   expectation: expectation)
        vc.viewDidLoad()
        wait(for: [expectation], timeout: 3)
    }

    func testOpenQuaryEqualzhURL() {
        let urlString = "https://www.google.com/search?q=成都"
        let expectUrlString = "https://www.google.com/search?q=%E6%88%90%E9%83%BD"
        let expectation = self.expectation(description: "pl3131ay")
        let vc = WebViewController(urlString: urlString,
                                   expectUrlString: expectUrlString,
                                   expectation: expectation)
        vc.viewDidLoad()
        wait(for: [expectation], timeout: 3)
    }

    func testOpenQuaryEqualEmojiURL() {
        let urlString = "https://www.google.com/search?q=😅"
        let expectUrlString = "https://www.google.com/search?q=%F0%9F%98%85"
        let expectation = self.expectation(description: "pl3131ay")
        let vc = WebViewController(urlString: urlString,
                                   expectUrlString: expectUrlString,
                                   expectation: expectation)
        vc.viewDidLoad()
        wait(for: [expectation], timeout: 3)
    }

    func testOpenQuaryEqualEnocdeURL() {
        let urlString = "https://accounts.google.com/o/oauth2/v2/auth?client_id=407440207476-18s2lf12sn6317eu06llthplbfj4gal2.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fcanny.io%2Fauth&response_type=code&scope=openid%20profile%20email&state=%7B%22authType%22%3A%22google%22%2C%22stage%22%3A2%2C%22close%22%3Atrue%7D"
        let expectUrlString = "https://accounts.google.com/o/oauth2/v2/auth?client_id=407440207476-18s2lf12sn6317eu06llthplbfj4gal2.apps.googleusercontent.com&redirect_uri=https://canny.io/auth&response_type=code&scope=openid%20profile%20email&state=%7B%22authType%22:%22google%22,%22stage%22:2,%22close%22:true%7D"
        let expectation = self.expectation(description: "pl3131ay")
        let vc = WebViewController(urlString: urlString,
                                   expectUrlString: expectUrlString,
                                   expectation: expectation)
        vc.viewDidLoad()
        wait(for: [expectation], timeout: 3)
    }

    func testOpenQuaryEqualEnocdeTwoTimeURL() {
        let urlString = "https://www.google.com.hk/search?q=%25E7%25BF%25BB%25E8%25AF%2591&oq=fanyi&aqs=chrome.1.69i59j0l7.4613j0j7&sourceid=chrome&ie=UTF-8"
        let expectUrlString = "https://www.google.com.hk/search?q=%25E7%25BF%25BB%25E8%25AF%2591&oq=fanyi&aqs=chrome.1.69i59j0l7.4613j0j7&sourceid=chrome&ie=UTF-8"
        let expectation = self.expectation(description: "pl3131ay")
        let vc = WebViewController(urlString: urlString,
                                   expectUrlString: expectUrlString,
                                   expectation: expectation)
        vc.viewDidLoad()
        wait(for: [expectation], timeout: 3)
    }
}

class WebViewController: UIViewController {
    let webView = WKWebView(frame: UIScreen.main.bounds, configuration: WKWebViewConfiguration())

    let urlString: String

    let expectUrlString: String

    let expectation: XCTestExpectation

    init(urlString: String,
         expectUrlString: String,
         expectation: XCTestExpectation) {
        self.urlString = urlString
        self.expectUrlString = expectUrlString
        self.expectation = expectation
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.view.addSubview(webView)
        let urlString = self.urlString
        self.webView.evaluateJavaScript(LKWebViewController.openAndCloseScript) { [weak self] (_, _) in
            self?.webView.evaluateJavaScript("window.open(\"\(urlString)\")", completionHandler: { (_, _) in

            })
        }
        super.viewDidLoad()
    }
}

extension WebViewController: WKNavigationDelegate {
    // MARK: - loadingNavigationDelegate
    //decide
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        guard let url = navigationAction.request.url else { return }
        if url.scheme == LKWebScheme.open.rawValue {
            let absoluteString = LKWebViewController.processURL(url)
            XCTAssert(absoluteString == self.expectUrlString)
            self.expectation.fulfill()
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
}
