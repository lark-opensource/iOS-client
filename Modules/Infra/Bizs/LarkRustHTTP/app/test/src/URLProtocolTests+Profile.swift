//
//  URLProtocolTests+Profile.swift
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2019/4/11.
//

import Foundation

// #if true
#if !DEBUG

import Foundation
import XCTest
import RxSwift
import LarkRustClient
import LarkRustHTTP
import Swifter

extension URLProtocolTests {
    func testProfile() {
        sleep(10) // sleep等启动热身
        // let url = URL(string: "https://travel.bytedance.com/")!
        // let url = URL(string: "https://internal-api.feishu.cn/space/api/user/")!
        // let url = URL(string: "https://internal-api.feishu.cn/space/api/ping/")!
        let url = URL(string: "https://www.baidu.com/")!
        var req = URLRequest(url: url)
        req.enableComplexConnect = self.enableComplexConnect
        req.retryCount = 3
        func run() {
            URLCache.shared.removeAllCachedResponses()
            resume(request: req) { (_, _, error) -> Void in
                if let error = error {
                    print("error: \(error)")
                }
            }
            waitTasks()
        }
        run() // warm up. the first always slow
        self.measure(run)
    }
}

#endif
