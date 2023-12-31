//
//  LKStringFixTest.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import UIKit
import Foundation
import XCTest
@testable import LKContentFix

class LKStringFixTest: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// 测试修复1w次的耗时情况
    func testFix10000Count() {
        let systemFont = UIFont.systemFont(ofSize: 17)
        // 内容中的你和我两个内容会被替换
        let testString = "无关字符无关字符无关字符无关字符你无关字符无关字符无关字符无关字符无关字符无关字符无关字符无关字符我无关字符无关字符无关字符无关字符你无关字符无关字符无关字符无关字符无关字符无关字符无关字符无关字符我"
        let config = StringFixConfig(fieldGroups: [StringFixConfig.key:
        """
            {
                "11.0-13.99": {
                    "\\u4f60": {
                        "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "PingFangSC-Medium"}]
                    },
                    "\\u6211": {
                        "replaceContent": {"to": "\\u65e0"},
                    },
            "\\u7ba1": {
                "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "PingFangSC-Medium"}]
            },
            "\\u63a7": {
                "replaceContent": {"to": "\\u65e0"},
            },
            "\\u6574": {
                "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "PingFangSC-Medium"}]
            },
            "\\u4f53": {
                "replaceContent": {"to": "\\u65e0"},
            },
            "\\u65b9": {
                "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "PingFangSC-Medium"}]
            },
            "\\u6848": {
                "replaceContent": {"to": "\\u65e0"},
            },
            "\\u53ca": {
                "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "PingFangSC-Medium"}]
            },
            "\\u8fdb": {
                "replaceContent": {"to": "\\u65e0"},
            }
                }
            }
        """])!
        LKStringFix.shared.reloadConfig(config)
        var allDate = 0.0
        for _ in 0..<10 {
            let beginDate = NSDate().timeIntervalSince1970
            for _ in 0..<10_000 {
                _ = LKStringFix.shared.fix(NSAttributedString(string: testString, attributes: [.font: systemFont]))
            }
            allDate += (NSDate().timeIntervalSince1970 - beginDate)
        }
        // 初版测试10次平均值为0.92s，所以这里写上0.95s，如果后续改动造成耗时超过0.95s，请检查并优化代码
        print("跑1w次的耗时：\(allDate / 10)")
        assert((allDate / 10) < 0.95)
    }

    /// 测试线程安全
    func testThreadSafe() {
        let systemFont = UIFont.systemFont(ofSize: 17)
        let config = StringFixConfig(fieldGroups: [StringFixConfig.key:
            """
                {
                    "11.0-13.99": {
                        "\\u4ed6": {
                            "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "PingFangSC-Medium"}]
                        },
                        "\\u6211": {
                            "replaceContent": {"to": "\\u4f60"},
                        }
                    }
                }
            """])!
        LKStringFix.shared.reloadConfig(config)
        let expect = expectation(description: "async")
        for _ in 0..<10_000 {
            DispatchQueue.global().async {
                let attr = NSAttributedString(string: "我他我他我他我他我他我他我他我他我他我他我他我他我他我他我他",
                                              attributes: [.font: systemFont])
                _ = LKStringFix.shared.fix(attr)
            }
        }
        for i in 0..<200_000 {
            DispatchQueue.global().async {
                LKStringFix.shared.reloadConfig(config)
                if i == 200_000 - 1 { expect.fulfill() }
            }
        }
        wait(for: [expect], timeout: 10.0)
    }

    /// 测试属性更新
    func testUpdateAttribute() {
        let systemFont = UIFont.systemFont(ofSize: 17)
        let replaceToFont = UIFont(name: "PingFangSC-Medium", size: 17)!
        let config = StringFixConfig(fieldGroups: [StringFixConfig.key:
            """
                {
                    "11.0-13.99": {
                        "\\u4ed6": {
                            "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "\(replaceToFont.fontName)"}]
                        },
                        "\\u6211": {
                            "updateAttribute": [{"attribute": "fontName", "from": "\(systemFont.fontName)", "to": "\(replaceToFont.fontName)"}]
                        }
                    }
                }
            """])!
        let attrStr = NSAttributedString(string: "他我他我他我他我他我他我我我我他他他他", attributes: [.font: systemFont])
        LKStringFix.shared.reloadConfig(config)
        // 预期所有内容的字体都替换为了PingFangSC-Medium
        let resultAttrStr = LKStringFix.shared.fix(attrStr)
        resultAttrStr.enumerateAttribute(.font, in: NSRange(location: 0, length: resultAttrStr.length), options: []) { (attr, _, _) in
            assert((attr as? UIFont)?.fontName == replaceToFont.fontName)
        }
    }

    /// 测试内容更新
    func testReplaceContent() {
        let config = StringFixConfig(fieldGroups: [StringFixConfig.key:
            """
                {
                    "11.0-13.99": {
                        "\\u4ed6": {
                            "replaceContent": {"to": "\\u0031"}
                        },
                        "\\u6211": {
                            "replaceContent": {"to": "\\u0031"}
                        }
                    }
                }
            """])!
        let attrStr = NSAttributedString(string: "他我他我他我他我他我他我我我我他他他他我")
        LKStringFix.shared.reloadConfig(config)
        // 预期所有内容都替换为了1
        let resultAttrStr = LKStringFix.shared.fix(attrStr)
        assert(resultAttrStr.string == "11111111111111111111")
    }
}
