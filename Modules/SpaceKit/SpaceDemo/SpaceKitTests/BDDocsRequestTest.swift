//
//  BDDocsRequestTest.swift
//  DocsTests
//
//  Created by guotenghu on 2019/3/12.
//  Copyright © 2019 Bytedance. All rights reserved.

import XCTest
@testable import SpaceKit
@testable import Docs
import Quick
import Nimble
import SwiftyJSON

class DocsRequestSpec: QuickSpec {
    let rustTestHeper = RustTestHelper()

    let logId = "==TestDocsRequestSpec=="
    func log(_ str: String) {
        print("\(logId) \(str)")
    }

    private func makeUpdateRequest() -> DocsRequest<JSON> {
        let url = "https://docs-download.bytedance.net/api/version/query/newest/update/"
        let parameters = ["platform": "iOS",
                          "app_id": 1,
                          "version": "1.1.0",
                          "language": "en",
                          "version_code": 12,
                          "user_id": 6563053707162812680,
                          "device_id": "296FA1CC-9B1C-4388-A57B-841682F38E78",
                          "tenant_id": 1] as [String: Any]
        return DocsRequest<JSON>(url: url, params: parameters).set(method: .GET).set(needVerifyData: false)
    }

    override func spec() {
        beforeSuite {
            self.rustTestHeper.initDocsNet()
            UserDefaults.standard.set(nil, forKey: enableRustHttpKey)
            self.log("called beforeSuite")
        }
        afterSuite {
            self.log("called afterSuite")
        }
        describe("生命周期正确") {
            it("设置reference以后可以等到网络回来", closure: {
                var returned = false
                waitUntil(timeout: 10, action: { (done) in
                    let currentRequest = self.makeUpdateRequest()
                    currentRequest.makeSelfReferenced()
                    self.log("设置reference app升级请求 开始")
                    currentRequest.start(result: { (json, error) in
                        expect(json).notTo(beNil())
                        expect(error).to(beNil())
                        self.log("设置reference app升级请求 回来了")
                        returned = true
                        done()
                    })
                })
                self.log("设置reference app 升级请求，结束了")
                expect(returned).to(beTrue())
            })

            it("不设置reference以后等不到网络回来", closure: {
                var returned = false
                waitUntil(timeout: 10, action: { (done) in
                    let currentRequest = self.makeUpdateRequest()
                    self.log("app升级请求 开始")
                    currentRequest.start(result: { (_, _) in
                        self.log("app升级请求 回来了")
                        returned = true
                        done()
                    })
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 9, execute: {
                        self.log("手动done")
                        done()
                    })
                })
                self.log("app 升级请求，结束了")
                expect(returned).to(beFalse())
            })
        }
    }
}
