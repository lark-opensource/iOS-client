//
//  BDTestEditorPool.swift
//  DocsTests
//
//  Created by huahuahu on 2018/9/26.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import XCTest
@testable import SpaceKit
@testable import Docs

class BDTestEditorPool: BDTestBase {

    final private let doc1 = "https://docs.bytedance.net/doc/W7CAG0ekyhyckshhYsRFOc"
    final private let doc2 = "https://docs.bytedance.net/doc/FipP936C6RxRYJWxvqUylc"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //连续打开几个，前几个是预加载的，后几个是非预加载的
    func xtestEditorPoolPreload() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        delay(10)
        DocsLogger.info("start test")
        UserDefaults.standard.set(5, forKey: RemoteConfigUpdater.ConfigKey.editorPoolMaxCount.rawValue)
        UserDefaults.standard.set(1, forKey: RemoteConfigUpdater.ConfigKey.editorPoolMaxUsedCountPerItem.rawValue)

        let docs = self.getDocs()
        let poolCount = OpenAPI.docs.editorPoolMaxCount
        DocsLogger.info("pool count is \(poolCount)")
        docs.enumerated().forEach { (index, url) in
            let vc = sdk.open(url)
            nav.push(vc, false, false)
            DocsLogger.info("start push \(index) url, url is \(url)")
            self.expectation(forNotification: NSNotification.Name.OpenFileRecord.OpenEnd, object: nil) { (notify) -> Bool in
                guard let userInfo = notify.userInfo, let openType = userInfo["docs_open_type"] as? String else {
                    fatalError("no user info in notification?")
                }
                DocsLogger.info("open doc finish with info \(userInfo)", extraInfo: nil, error: nil, component: nil)
                if poolCount > index {
                    XCTAssertEqual(openType, OpenFileRecord.OpenType.preload.rawValue, "open type fail for \(index)")
                } else {
                }
                return true
            }
            self.waitForExpectations(timeout: 20) { (_) in
                DocsLogger.info("log timeout")
            }
            DocsLogger.info("push \(url) end")
        }
    }

    func xtestReUse() {
        DocsLogger.info("start test")
        delay(10)
        DocsLogger.info("really start test")

        let docs = self.getDocs()
        UserDefaults.standard.set(1, forKey: RemoteConfigUpdater.ConfigKey.editorPoolMaxCount.rawValue)
        UserDefaults.standard.set(5, forKey: RemoteConfigUpdater.ConfigKey.editorPoolMaxUsedCountPerItem.rawValue)

        let pooluseCount = OpenAPI.docs.editorPoolItemMaxUseCount
        DocsLogger.info("pool use count is \(pooluseCount)")

        guard let navigationVC = nav as? UINavigationController else {
            fatalError("no navigation vc")
        }
        docs.enumerated().forEach { (index, url) in
            let vc = sdk.open(url)
            nav.push(vc, false, false)
            DocsLogger.info("start push \(index) url, url is \(url)")
            self.expectation(forNotification: NSNotification.Name.OpenFileRecord.OpenEnd, object: nil) { (notify) -> Bool in
                guard let userInfo = notify.userInfo, let openType = userInfo["docs_open_type"] as? String else {
                    fatalError("no user info in notification?")
                }
                DocsLogger.info("open doc finish with info \(userInfo)", extraInfo: nil, error: nil, component: nil)
                if pooluseCount > index {
                    XCTAssertEqual(openType, OpenFileRecord.OpenType.preload.rawValue, "open type fail for \(index)")
                } else {
                }
                return true
            }
            self.waitForExpectations(timeout: 20) { (_) in
                DocsLogger.info("log timeout")
            }
            navigationVC.popToRootViewController(animated: false)
            DocsLogger.info("push \(url) end")
        }
    }

    func getDocs() -> [String] {
        return ["https://docs.bytedance.net/doc/FipP936C6RxRYJWxvqUylc",
                    "https://docs.bytedance.net/doc/pbIOlUbNFHzb1xBYOhPUcc",
        "https://docs.bytedance.net/doc/n2qANZbDdAeVZIozsxjhQa",
        "https://docs.bytedance.net/doc/BqUfpQCFrEM0mfkpmVS0Nc",
        "https://docs.bytedance.net/doc/AikNfUeAVKPwLpHGVTSEaf",
        "https://docs.bytedance.net/doc/T5NDLC0HFIfauJkGi72qpa"]
    }
}
