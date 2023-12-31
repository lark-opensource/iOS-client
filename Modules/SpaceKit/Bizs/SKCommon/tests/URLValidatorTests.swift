//
//  URLValidatorTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/6/24.
//

@testable import SKCommon
import XCTest
import SKInfra


class URLValidatorTests: XCTestCase {
    
    func testReplaceOriginUrlIfNeed() {
        
        //模拟setting下发的正则配置
        var domainConfig = [String: Any]()
        domainConfig[DomainConfigKey.previousDomainReg.rawValue] = "(bytedance(\\.(sg|us|jp))?)\\.feishu\\.cn"
        domainConfig[DomainConfigKey.newDomainReplacement.rawValue] = "$1.larkoffice.com"
        
        
        //预期：替换 bytedance.feishu.cn => bytedance.larkoffice.com
        var originUrl = "https://bytedance.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        var replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertEqual(replaceUrl?.absoluteString, "https://bytedance.larkoffice.com/docx/dtfkuyfylgylgkkhb?query=param")
        
        //预期：替换 bytedance.sg.feishu.cn => bytedance.sg.larkoffice.com
        originUrl = "https://bytedance.sg.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertEqual(replaceUrl?.absoluteString, "https://bytedance.sg.larkoffice.com/docx/dtfkuyfylgylgkkhb?query=param")
        
        //预期：替换 bytedance.us.feishu.cn => bytedance.us.larkoffice.com
        originUrl = "https://bytedance.us.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertEqual(replaceUrl?.absoluteString, "https://bytedance.us.larkoffice.com/docx/dtfkuyfylgylgkkhb?query=param")
        
        //预期：不会替换， bytedance.aa.feishu.cn
        originUrl = "https://bytedance.aa.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertNil(replaceUrl) //没有替换返回nil
        
        //预期：替换 test.bytedance.us.feishu.cn => test.bytedance.us.larkoffice.com
        originUrl = "https://test.bytedance.us.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertEqual(replaceUrl?.absoluteString, "https://test.bytedance.us.larkoffice.com/docx/dtfkuyfylgylgkkhb?query=param")
        
        
        //预期：不会替换， nio.feishu.cn
        originUrl = "https://nio.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertNil(replaceUrl) //没有替换返回nil
        
        //预期：不会替换， nio.sg.feishu.cn
        originUrl = "https://nio.sg.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertNil(replaceUrl) //没有替换返回nil
        
        //预期：不会替换， test.test.feishu.cn
        originUrl = "https://test.test.feishu.cn/docx/dtfkuyfylgylgkkhb?query=param"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertNil(replaceUrl) //没有替换返回nil
        
        //预期：只替换域名，query不会替换
        //    bytedance.feishu.cn/xxxxx?query=bytedance.feishu.cn
        // => bytedance.larkoffice.com/xxxxx?query=bytedance.feishu.cn
        originUrl = "https://bytedance.feishu.cn/docx/dtfkuyfylgylgkkhb?query=bytedance.feishu.cn"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertEqual(replaceUrl?.absoluteString, "https://bytedance.larkoffice.com/docx/dtfkuyfylgylgkkhb?query=bytedance.feishu.cn")
        
        
        //预期：只替换域名，query不会替换
        //    bytedance.sg.feishu.cn/xxxxx?query=bytedance.us.feishu.cn
        // => bytedance.sg.larkoffice.com/xxxxx?query=bytedance.us.feishu.cn
        originUrl = "https://bytedance.sg.feishu.cn/docx/dtfkuyfylgylgkkhb?query=bytedance.us.feishu.cn"
        replaceUrl = URLValidator.replaceOriginUrlIfNeed(originUrl: URL(string: originUrl)!, domainConfig: domainConfig)
        XCTAssertEqual(replaceUrl?.absoluteString, "https://bytedance.sg.larkoffice.com/docx/dtfkuyfylgylgkkhb?query=bytedance.us.feishu.cn")
        
    }
}
