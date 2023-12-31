//
//  BDRustHttpTest.swift
//  DocsTests
//
//  Created by guotenghu on 2019/3/6.
//  Copyright © 2019 Bytedance. All rights reserved.

import XCTest
@testable import SpaceKit
@testable import Docs
import Quick
import Nimble
import LarkRustClient
import LarkRustHTTP
import LarkLocalizations
import SwiftyJSON
import LarkReleaseConfig

let enableRustHttpKey = "enableRustHttpKeyForTest"

final class RustTestHelper {
    private var rustClient: RustClient?
    let logId = "==TestRustHttp=="
    private var isEnable = false
    func log(_ str: String) {
        print("\(logId) \(str)")
    }

    func initRust() {
        let location = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        let storagepath = (location as NSString).appendingPathComponent("drive")
        if !FileManager.default.fileExists(atPath: storagepath) {
            do {
                try FileManager.default.createDirectory(atPath: storagepath,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                DocsLogger.info("创建目录失败")
            }
        }
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let envForRust = RustClientConfiguration.EnvType(rawValue: OpenAPI.DocsDebugEnv.current.envType)!

        var domainInitConfig = DomainInitConfig()
        domainInitConfig.channel = ReleaseConfig.releaseChannel
        domainInitConfig.isCustomizedKa = ReleaseConfig.isKA
        domainInitConfig.kaInitConfigPath = Bundle.main.bundleURL.appendingPathComponent("DocsApp.bundle").path

        rustClient = {
            let url = URL(fileURLWithPath: storagepath)

            let configuration = RustClientConfiguration(
                identifier: "DocsRustClient",
                storagePath: url,
                version: appVersion,
                userAgent: UserAgent.defaultNativeApiUA,
                env: envForRust,
                appId: "1229",
                localeIdentifier: LanguageManager.current.altTableName,
                clientLogStoragePath: "",
                userId: "6563053707162812680",
                domainInitConfig: domainInitConfig
            )

            // 可能抛出SIGPIPE错误，主工程把他隐藏了
            // 这个信号在一般APP中也没什么用，忽略不会有什么影响. 下面有一个猜测的解释
            // https://stackoverflow.com/questions/8369506/why-does-sigpipe-exist
            signal(SIGPIPE, { v in
                print("RECEIVE SIGPIPE \(v)")
            })

            let client = RustClient(configuration: configuration)
            RustHttpManager.rustService = { client }
            return client
        }()
        self.log("Rust 初始化")
    }

    func enableRust() {
        self.log("enableRust")
        isEnable = true
        UserDefaults.standard.set(true, forKey: enableRustHttpKey)
    }

    func disableRust() {
        self.log("disableRust")
        isEnable = false
        UserDefaults.standard.set(nil, forKey: enableRustHttpKey)
    }

    func checkRustStatus() {
        expect(DocsSDK.isEnableRustHttp).to(equal(isEnable))
    }

    func makeUpdateRequest() -> DocsRequest<JSON> {
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

    func makeBaiduRequest() -> DocsRequest<JSON> {
        let url = "https://www.toutiao.com/"
        return DocsRequest<JSON>(url: url, params: [:]).set(method: .GET).set(needVerifyData: false)
    }

    func initDocsNet() {
        NetConfig.shared.authDelegate = FakeNetWorkDelete.shared
        NetConfig.shared.configWith(baseURL: OpenAPI.docs.baseUrl, additionHeader: [:])
    }
}

class RustHttpTestSpec: QuickSpec {
    var currentRequest: DocsRequest<JSON>?
    let rustTestHeper = RustTestHelper()

    func enableRust() {
        rustTestHeper.enableRust()
    }

    func disableRust() {
        rustTestHeper.disableRust()
    }

    func checkRustStatus() {
        rustTestHeper.checkRustStatus()
    }

    func makeUpdateRequest() -> DocsRequest<JSON> {
        return rustTestHeper.makeUpdateRequest()
    }

    func makeBaiduRequest() -> DocsRequest<JSON> {
        return rustTestHeper.makeBaiduRequest()
    }

    func log(_ str: String) {
        rustTestHeper.log(str)
    }

    func initRust() {
        rustTestHeper.initRust()
    }

    override func spec() {
        beforeSuite {
            self.enableRust()
            self.rustTestHeper.initDocsNet()
            self.initRust()
            self.log("called beforeSuite")
        }
        afterSuite {
            UserDefaults.standard.set(nil, forKey: enableRustHttpKey)
            self.log("called afterSuite")
        }
        describe("正常访问请求") {
            it("app升级请求", closure: {
                waitUntil(timeout: 10, action: { (done) in
                    self.checkRustStatus()
                    self.currentRequest = self.makeUpdateRequest()
                    self.log("app升级请求 开始")
                    self.currentRequest?.start(result: { (json, error) in
                        expect(error).to(beNil())
                        expect(json).notTo(beNil())
                        expect(json!["success"].boolValue).to(beTrue())
                        self.currentRequest = nil
                        self.log("app升级请求 成功")
                        done()
                    })
                })
            })
            it("百度请求", closure: {
                waitUntil(timeout: 10, action: { (done) in
                    self.checkRustStatus()
                    self.currentRequest = self.makeBaiduRequest()
                    self.log("百度请求 开始")
                    self.currentRequest?.start(rawResult: { (_, _, error) in
                        expect(error).to(beNil())
                        self.currentRequest = nil
                        self.log("百度请求 成功")
                        done()
                    })
                })
            })
        }

        describe("可以被取消") {
            it("app升级请求", closure: {
                waitUntil(timeout: 10, action: { (done) in
                    self.checkRustStatus()
                    self.currentRequest = self.makeUpdateRequest()
                    self.log("app升级请求 开始")
                    self.currentRequest?.start(result: { (_, error) in
                        let errorCode = (error as? URLError)?.errorCode
                        expect(errorCode!).to(equal(-999))
                        self.log("app升级请求 成功被取消")
                        done()
                    })
                    self.currentRequest?.cancel()
                })
            })
        }
    }
}
