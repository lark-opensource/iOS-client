//
//  DocURLCorrectorTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by huayufan on 2023/3/1.
//  


import XCTest
@testable import SKFoundation


final class DocURLCorrectorTests: XCTestCase {

    let linkRegex = "/(((https?|s?ftp|ftps|nfs|ssh):\\/\\/)?((localhost(:[0-9]{2,5})?)|((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}(2[0-4][0-9]|25[0-5]|1[0-9]{2}|[1-9][0-9]|[0-9])(:[0-9]{2,5})?))\\b([/?#][-a-zA-Z0-9@:%_+.~#?&/=;()$,!\\*\\[\\]{}^|<>]*)?)|((((https?|s?ftp|ftps|nfs|ssh):\\/\\/([\\-a-zA-Z0-9:%_+~#@]{1,256}\\.){1,50}[a-z\\-]{2,15})|(([\\-a-zA-Z0-9:%_+~#@]{1,256}\\.){1,50}(com|org|net|int|edu|gov|mil|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|site|top|wtf|xxx|xyz|cloud|engineering|help|one)))(:[0-9]{2,5})?\\b([/?#][-a-zA-Z0-9@:%_+.~#?&/=;()$,!\\*\\[\\]{}^|<>]*)?)|(^(?!data:)((mailto:[\\w.!#$%&'*+-/=?^_\\`{|}~]{1,2000}@[A-Za-z0-9_.-]+\\.[a-z\\-]{2,15})|([\\w.!#$%&'*+-/=?^_\\`{|}~]{1,2000}@[A-Za-z0-9_.-]+\\.(com|org|net|int|edu|gov|mil|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|site|top|wtf|xxx|xyz|cloud|engineering|help|one)))\\b)/gi"
    
    let corrector = DocURLCorrector(blackList: [".", ",", "!", "?", "'", ":", ";", "#", "@"])
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLongURL() {
        let testStr = "(https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g){https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g}[https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g]<https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g>《https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g》「https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g」（https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g）【https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g】https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g."
        let ranges = testStr.docs.regularUrlRanges(pattern: linkRegex)
        var result: [NSRange] = []
        for range in ranges {
            result.append(contentsOf: corrector.correctRange(urlRange: range, urlStr: testStr, linkRegex: linkRegex))
        }
        let src = subStrings(str: testStr, ranges: result)
        let dst = Array<String>(repeating: "https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g", count: 9)
        XCTAssertTrue(src.count == 9)
        XCTAssertTrue(compareStringArray(src: src, dst: dst))
    }
    
    
    func testURL() {
        XCTAssertTrue(testOne(urlString: "哈哈哈21421(https://www.baidu.com/e(f3331(w)aaddda<awfaf>ascaf.).sadfw.]f(e)afw 21u498u90", expectation: "https://www.baidu.com/e(f3331(w)aaddda<awfaf>ascaf.).sadfw"))
        XCTAssertTrue(testOne(urlString: "https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g()...;!:'?!", expectation: "https://bytedance.feishu.cn/docx/VNcad7hTdoJ0hqxKCBnct6pkn1g()"))
        
        XCTAssertTrue(testOne(urlString: "(https://bytedance.feishu.cn/docx/VNcad[hTdoJ0hq}xKC]Bnct6pkn1g()...;!:'?!", expectation: "https://bytedance.feishu.cn/docx/VNcad"))
        
        XCTAssertTrue(testOne(urlString: "(https://bytedance.feishu.cn/docx/VNcad[hTdoJ[0h]q}xKC]Bnct6pkn1g()...;!:'?!", expectation: "https://bytedance.feishu.cn/docx/VNcad"))
        
        let array = ["&", "^", "?", "'", ";", "*", "|", "[", "]",
        "{", "}", "<", ">"] // "%", ":", "#", "@", "-", "+"
        for value in array {
            var str = value + "www.xxx.com"
            XCTAssertTrue(testOne(urlString: str, expectation: "www.xxx.com"), "\(str) valid fail")
            str += value
            XCTAssertTrue(testOne(urlString: str, expectation: "www.xxx.com"), "\(str) valid fail")
        }
    
        XCTAssertTrue(testOne(urlString: "(www.xxx.com/yyy", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "(www.xxx.com/yyy)", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "(www.xxx.com/yyy[", expectation: "www.xxx.com/yyy"))
        
        XCTAssertTrue(testOne(urlString: "(www.xxx.com/yyy[(1)]2", expectation: "www.xxx.com/yyy[(1)]2"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[1((]2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: ")www.xxx.com/yyy[2)3(4]2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[3)4)1]2", expectation: "www.xxx.com/yyy"))
        
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[2)1](2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[1(5[(2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "(www.xxx.com/yyy[2)[(2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[2(]](2", expectation: "www.xxx.com/yyy"))
        
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[5](4)2", expectation: "www.xxx.com/yyy[5](4)2"))
        XCTAssertTrue(testOne(urlString: ">www.xxx.com/yyy[]))2", expectation: "www.xxx.com/yyy[]"))
        XCTAssertTrue(testOne(urlString: "<www.xxx.com/yyy[1]((2", expectation: "www.xxx.com/yyy[1]"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy[2])(2", expectation: "www.xxx.com/yyy[2]"))
    
        XCTAssertTrue(testOne(urlString: "{www.xxx.com/yyy][()2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: ">www.xxx.com/yyy][((2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: "<www.xxx.com/yyy][))2", expectation: "www.xxx.com/yyy"))
        XCTAssertTrue(testOne(urlString: ")www.xxx.com/yyy][)(2", expectation: "www.xxx.com/yyy"))
        
        
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy{ab}][2", expectation: "www.xxx.com/yyy{ab}"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy(42)]]2", expectation: "www.xxx.com/yyy(42)"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy()[[2", expectation: "www.xxx.com/yyy()"))
        XCTAssertTrue(testOne(urlString: "[www.xxx.com/yyy)([]2", expectation: "www.xxx.com/yyy"))
  
    }
    
    func testSuffix() {
        let array = [".", ",", "!", "?", "'", ":", ";", "#", "@"]
        for value in array {
            let str =  "www.xxx.com" + value
            XCTAssertTrue(testOne(urlString: str, expectation: "www.xxx.com"), "\(str) valid fail")
        }
    }
    
    func testOne(urlString: String, expectation: String) -> Bool {
        let ranges = urlString.docs.regularUrlRanges(pattern: linkRegex)
        var result: [NSRange] = []
        for range in ranges {
            result.append(contentsOf: corrector.correctRange(urlRange: range, urlStr: urlString, linkRegex: linkRegex))
        }
        let array = subStrings(str: urlString, ranges: result)
        return array.count == 1 && array[0] == expectation
    }

    func subStrings(str: String, ranges: [NSRange]) -> [String] {
        var res: [String] = []
        for range in ranges {
            guard let strRange = Range(range, in: str) else { continue }
            let str = String(str[strRange])
            res.append(str)
        }
        return res
    }
    
    func compareStringArray(src: [String], dst: [String]) -> Bool {
        if src.count != dst.count {
            return false
        }
        return src.joined(separator: ",") == dst.joined(separator: ",")
    }
}
