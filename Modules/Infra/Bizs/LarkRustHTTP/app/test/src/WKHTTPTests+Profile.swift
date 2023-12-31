//
//  WKHTTPTests+Profile.swift
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2019/4/11.
//

#if ENABLE_WKWebView
// #if true
#if !DEBUG

import Foundation
import XCTest
import RxSwift
import LarkRustClient
import LarkRustHTTP
import WebKit
import Swifter

@available(iOS 11.0, *)
extension WKHTTPTests {
    func testProfile() {
        let url = URL(string: "https://travel.bytedance.com/")!
        func run() {
            wait(completable: clearWebCache()
                .andThen(navigation { self.webView.load(URLRequest(url: url)) })
                .catchError { (error) in
                    print("error: \(error)")
                    return Completable.empty()
                }
                .do(onCompleted: {
                    self.webView.stopLoading()
                }))
        }
        run() // warm up. the first always slow
        self.measure(run)
    }
}

#endif
#endif
