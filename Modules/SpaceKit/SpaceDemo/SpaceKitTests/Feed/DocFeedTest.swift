//
//  DocFeedTest.swift
//  DocsTests
//
//  Created by maxiao on 2019/8/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import SwiftyJSON
@testable import SpaceKit
@testable import Docs

class DocFeedTest: QuickSpec {
    var dataService: DocsFeedDataService!
    let disposeBag = DisposeBag()

    func log(_ str: String) {
        print("DocFeedTest \(str)")
    }

    func initNetwork() {
        NetConfig.shared.authDelegate = FakeNetWorkDelete.shared
        NetConfig.shared.configWith(baseURL: OpenAPI.docs.baseUrl, additionHeader: [:])
    }

    override func spec() {
        beforeSuite {
            self.dataService = DocsFeedDataService(dependency: self)
            self.initNetwork()
        }

        afterSuite {
            print("DocFeedTest done")
        }

//        describe("获取feed数据") {
//            it("获取feed数据", closure: {
//                waitUntil(timeout: 10, action: { (done) in
//                    self.dataService.getNewData()
//                        .subscribe(onNext: { (data) in
//                            expect(data.0.count == data.1.count).to(beTrue())
//                            expect(data.2.count == data.1.count).to(beTrue())
//                            done()
//                        }, onError: { (error) in
//                            expect(error).to(beNil())
//                            done()
//                        }, onCompleted: {
//
//                        }, onDisposed: {
//                            self.log("disposeds")
//                        })
//                    .disposed(by: self.disposeBag)
//                })
//            })
//        }

//        describe("从前端获取feed数据") {
//            it("从千吨啊获取feed数据", closure: {
//                waitUntil(timeout: 10, action: { (done) in
//                    let data = DocFeedDataCacher.getCacheData()
//                    expect(data).notTo(beNil())
//                    self.dataService.handleData(data: data!)
//                        .subscribe(onNext: { (data) in
//                            expect(data.0.count == data.1.count).to(beTrue())
//                            expect(data.2.count == data.1.count).to(beTrue())
//                            done()
//                        }, onError: { (error) in
//                            expect(error).to(beNil())
//                            done()
//                        }, onDisposed: {
//
//                        })
//                        .disposed(by: self.disposeBag)
//                })
//            })
//        }
    }
}

extension DocFeedTest: DocsFeedDataDependency {
    var docInfo: DocsInfo {
        return DocsInfo(type: .doc, objToken: "doccnZ0jwNfAuO2WKuBGIYu62Jg")
    }
}

class DocFeedDataCacher {
    class func getCacheData() -> [String: Any]? {
        let feedData = AudioCacheService.audioData(with: "doccnZ0jwNfAuO2WKuBGIYu62Jg")
//        return feedData as? [String: Any]
        return [:]
    }
}
