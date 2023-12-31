//
//  BDTestOpenDocsAndSheet.swift
//  DocsTests
//
//  Created by huahuahu on 2018/10/11.
//  Copyright © 2018 Bytedance. All rights reserved.
//

// 测试若干文档可以成功打开

import XCTest
@testable import SpaceKit
@testable import Docs

class BDTestOpenDocsAndSheet: BDTestBase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func xtestOpenFilesOK() {
        delay(10)
        let files = getFiles()
        guard let navigationVC = nav as? UINavigationController else {
            fatalError("no navigation vc")
        }

        files.forEach({ (url) in
            let vc = sdk.open(url)
            nav.push(vc, false, false)
            DocsLogger.info("start push url is \(url)")
            self.expectation(forNotification: NSNotification.Name.OpenFileRecord.OpenEnd, object: nil) { (notify) -> Bool in
                guard let userInfo = notify.userInfo else {
                    fatalError("no user info in notification?")
                }
                DocsLogger.info("open file ok", extraInfo: userInfo as? [String: Any], error: nil, component: nil)
                let resultKey = userInfo[OpenFileRecord.ReportKey.resultKey.rawValue] as? String
                let resultCode = userInfo[OpenFileRecord.ReportKey.resultCode.rawValue] as? Int
                let errMsg = "open doc \(url) fail with info \(userInfo)"
                XCTAssertEqual(resultKey, "other", errMsg)
                XCTAssertEqual(resultCode, 0, errMsg)
                return true
            }
            self.waitForExpectations(timeout: 20) { (_) in
                let errMsg = "open doc \(url) overtime"
                DocsLogger.info(errMsg)
            }
            delay(2)
            navigationVC.popToRootViewController(animated: true)
            delay(3)
        })
    }

    private func getFiles() -> [String] {
        let bigUrl = "https://docs.bytedance.net/doc/n35rLQImUBgZhLVO6CX5Db" //大文档
        let middleUrl = "https://docs.bytedance.net/doc/gSFQzwT707BNFPytWvIIVh"// 中文档
        let smallUrl = "https://docs.bytedance.net/doc/1pnX7XXufUokcg3w4uV2Vh" //小文档
        let smallSheet = "https://docs.bytedance.net/sheet/dQKSLxGKyBkfQVnSZ1cWSa" // 小的独立sheet
        let bigSheet = "https://docs.bytedance.net/sheet/eEklOEWxLk38YK88bNSCuh" //有多页的sheet
        let sheetInDocs = "https://docs.bytedance.net/doc/n6t533WTLaa5lqWrveEiZd" // 小的sheet in docs
        let sheetinDocs1 = "https://docs.bytedance.net/doc/KHYkTVLhPFGrazXyvTw2eb" //很多 sheet 在一个大的docs

        return [bigUrl, middleUrl, smallUrl, smallSheet, bigSheet, sheetInDocs, sheetinDocs1]
    }
}
