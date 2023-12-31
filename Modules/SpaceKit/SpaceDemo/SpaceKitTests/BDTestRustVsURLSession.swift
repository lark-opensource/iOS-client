//
//  BDTestRustVsURLSession.swift
//  DocsTests
//
//  Created by guotenghu on 2019/5/27.
//  Copyright © 2019 Bytedance. All rights reserved.
//swiftlint:disable force_cast

import XCTest
@testable import SpaceKit
@testable import Docs
import Quick
import Nimble
import SwiftyJSON
import Alamofire

class RustVsNativeSpec: QuickSpec {
    let rustTestHelper = RustTestHelper()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        return formatter
    }()
    var startTimeStr: String!
    private let requestCount = 10
    private func log(_ str: @autoclosure () -> String) {
        print("rust Vs Native: \(str())")
    }

    private func computeStatistics() {
        let rustStatistics = TestTracker.statisticsValue.filter { (arg) -> Bool in
            let (_, params) = arg
            return (params["http_channel"] as? String) == "rustChannel"
        }
        let nativeStatistics = TestTracker.statisticsValue.filter { (arg) -> Bool in
            let (_, params) = arg
            return (params["http_channel"] as? String) == "nativeUrlSession"
        }
        expect(rustStatistics.count).to(equal(requestCount))
        expect(nativeStatistics.count).to(equal(requestCount))
        func analy(_ params: [[AnyHashable: Any]]) {
            let succ = params.filter { (arg) -> Bool in
                return (arg["code"] as? Int) == 0
            }
            let average = succ.map {
                let costTime = $0["cost_time"] as! Double
                log("single: \(costTime)")
                return costTime
            }.reduce(0.0, +) / Double(succ.count)
            log("success \(succ.count), averageTime \(average)ms")
        }
        log("startTime: \(self.startTimeStr!) rust result:====")
        analy(rustStatistics.map { $0.params })
        log("native result:====")
        analy(nativeStatistics.map { $0.params })
    }

    override func spec() {
        beforeSuite {
            self.rustTestHelper.initDocsNet()
            self.rustTestHelper.initRust()
            self.log("before suite, \(self.dateFormatter.string(from: Date()))")
            self.startTimeStr = self.dateFormatter.string(from: Date())
        }
        afterSuite {
            self.log("end suite")
            self.computeStatistics()
        }
        context("启用了rust ") {
            beforeEach {
                self.rustTestHelper.enableRust()
                self.rustTestHelper.checkRustStatus()
                NetConfig.shared.updateBaseUrl("www.dd.ee")
                waitUntil(timeout: 100, action: { (done) in
                    let request = self.rustTestHelper.makeInternalApiTest().makeSelfReferenced()
                    request.start(rawResult: { (_, _, _) in
                        done()
                    })
                })
            }
            it("get 请求", closure: {
                (0..<self.requestCount).forEach { _ in
                    waitUntil(timeout: 100, action: { (done) in
                        let request = self.rustTestHelper.makeInternalApiTest().makeSelfReferenced()
                        request.startWithAlamofireResponse({ (response) in
//                            expect(response.error).to(beNil())
                            _ = response.mapError { error -> Error in
                                self.log("rust get fail \(error)")
                                return error
                            }
                            _ = response.map({ _ in
                                self.log("rust get success ")
                            })
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                                done()
                            })
                        })
                    })
                }
            })
        }

        context("没有启用rust") {
            beforeEach {
                self.rustTestHelper.disableRust()
                self.rustTestHelper.checkRustStatus()
                NetConfig.shared.updateBaseUrl("www.dd.uu")
                waitUntil(timeout: 100, action: { (done) in
                    let request = self.rustTestHelper.makeInternalApiTest().makeSelfReferenced()
                    request.start(rawResult: { (_, _, _) in
                        done()
                    })
                })
            }
            it("get 请求", closure: {

                (0..<self.requestCount).forEach { _ in
                    waitUntil(timeout: 100, action: { (done) in
                        let request = self.rustTestHelper.makeInternalApiTest().makeSelfReferenced()
                        request.startWithAlamofireResponse({ (response) in
                            _ = response.mapError { error -> Error in
                                self.log("no rust get fail \(error)")
                                return error
                            }
                            _ = response.map({ _ in
                                self.log("no rust get success ")
                            })
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                                done()
                            })
                        })
                    })
                }
            })
        }
    }
}

struct TestTracker: StatisticsServcie {
    static var statisticsValue = [(event: String, params: [AnyHashable: Any])]()
    static func log(event: String, parameters: [AnyHashable: Any]?, shouldAddPrefix: Bool) {
        if event == "dev_performance_native_network_request" {
            statisticsValue.append((event, parameters ?? [:]))
        }
    }
}

extension DocsRequest {
    func startWithAlamofireResponse(_ handler: @escaping (DataResponse<Data>) -> Void) {
        contructInternalRequest()
        let dataRequest = self.request as? DataRequest
        dataRequest?.responseData(completionHandler: { [weak self] (response) in
            guard let `self` = self else { return }
            let reporter = NetStatisticsReporter(identifier: "test", useRust: self.context.session.useRust, statisticServiceType: TestTracker.self)
            reporter.doStatisticsFor(request: dataRequest, response: response)
            handler(response)
        })
    }
}

extension RustTestHelper {
    func makeInternalApiTest() -> DocsRequest<JSON> {
        let url = URL(string: "https://internal-api.feishu.cn/space/api/user/")!
        let token = "XN0YXJ0-25bdbbe3-ae31-4ae3-9014-ebc352961a75-WVuZA"
        if let cookie = url.cookie(value: token, forName: "bear-session") {
            HTTPCookieStorage.shared.setCookie(cookie)
        }

        return DocsRequest<JSON>(url: url.absoluteString, params: [:]).set(method: .GET).set(needVerifyData: false)
    }
}
