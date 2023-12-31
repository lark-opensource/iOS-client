//
//  InlineAIURLParserTests.swift
//  LarkAIInfra-Unit-Tests
//
//  Created by huayufan on 2023/10/31.
//  


import XCTest
import RxSwift
import RxCocoa
import LarkDocsIcon

@testable import LarkAIInfra

final class InlineAIURLParserTests: XCTestCase {

    let regexString = "/(((https?|s?ftp|ftps|nfs|ssh):\\/\\/)?((localhost(:[0-9]{2,5})?)|((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}(2[0-4][0-9]|25[0-5]|1[0-9]{2}|[1-9][0-9]|[0-9])(:[0-9]{2,5})?))\\b([/?#][-a-zA-Z0-9@:%_+.~#?&/=;()$,!\\*\\[\\]{}^|<>]*)?)|((((https?|s?ftp|ftps|nfs|ssh):\\/\\/([\\-a-zA-Z0-9:%_+~#@]{1,256}\\.){1,50}[a-z\\-]{2,15})|(([\\-a-zA-Z0-9:%_+~#@]{1,256}\\.){1,50}(com|org|net|int|edu|gov|mil|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|site|top|wtf|xxx|xyz|cloud|engineering|help|one)))(:[0-9]{2,5})?\\b([/?#][-a-zA-Z0-9@:%_+.~#?&/=;()$,!\\*\\[\\]{}^|<>]*)?)|(^(?!data:)((mailto:[\\w.!#$%&'*+-/=?^_\\`{|}~]{1,2000}@[A-Za-z0-9_.-]+\\.[a-z\\-]{2,15})|([\\w.!#$%&'*+-/=?^_\\`{|}~]{1,2000}@[A-Za-z0-9_.-]+\\.(com|org|net|int|edu|gov|mil|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|site|top|wtf|xxx|xyz|cloud|engineering|help|one)))\\b)/gi"

    class TestURLRequest: InlineAIURLRequest {
        
        var testToken: String
        
        var testType: Int
        
        var title: String

        var setError = false
        
        var needAsync = true
    
        var count: Int = 0
        
        init(testToken: String, testType: Int, title: String = "123") {
            self.testToken = testToken
            self.testType = testType
            self.title = title
        }
    
        func sendAsyncHttpRequest(token: String, type: CCMDocsType) -> Observable<[String: Any]?> {
           let setError = self.setError
           count += 1
           let text = self.title
           return Observable.create { ob in
               func onNext(ob: AnyObserver<[String: Any]?>) {
                   let res: [String: Any] = ["token": self.testToken,
                                              "title": text,
                                              "obj_type": self.testType]
                   if setError {
                       ob.onNext([:])
                   } else {
                       ob.onNext(["data" : res])
                   }
               }
               if self.needAsync {
                   DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                      onNext(ob: ob)
                   }
               } else {
                   onNext(ob: ob)
               }
               return Disposables.create {}
            }
        }
    }
    
    class TestInlineAIDocURLAnalysis: InlineAIDocURLAnalysis {
        
        var token: String
        var type: LarkDocsIcon.CCMDocsType

        init(token: String, type: LarkDocsIcon.CCMDocsType) {
            self.token = token
            self.type = type
        }
        
        func getFileInfoNewFrom(_ url: URL) -> (token: String?, type: LarkDocsIcon.CCMDocsType?) {
            return (token, type)
        }
    }

    var parser: InlineAIURLParser?
    
    var contentExtra: [String: Any]?

    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
        self.contentExtra = nil
    }

    
    func testParser() {
        let token = "wikcnPWH1693BZNKcPAM4VOGNKs"
        var text = "this is 1234 https://xxx.feishu.cn/wiki/\(token)  daacfaslvakvaskvasiojvsaoijvoaijv"
        
        let analysis = TestInlineAIDocURLAnalysis(token: token, type: .wiki)
        
        let request = TestURLRequest(testToken: "FJPVcYErSoVM6Axelq8c95nMnMh", testType: LarkDocsIcon.CCMDocsType.docX.rawValue)
        request.needAsync = false
        self.parser = InlineAIURLParser(regexString: regexString, docsIconRequest: request, docsUrlUtil: analysis)

        self.parser?.delegate = self
        

        self.parser?.parse(with: text)
        
        
        
        let dict = self.contentExtra ?? [:]
        let key = token
        let result = (dict[key] as? [String: Any]) ?? [:]
        XCTAssertEqual((result["token"] as? String) ?? "", "FJPVcYErSoVM6Axelq8c95nMnMh")
        XCTAssertEqual((result["icon_type"] as? Int), LarkDocsIcon.CCMDocsType.docX.rawValue)
        XCTAssertEqual((result["title"] as? String) ?? "", "123")
        // downLoading中不处理
        XCTAssertEqual(request.count, 1)
        
        text += "sicfhaocjaop test"
        // downLoading中不处理
        self.parser?.parse(with: text)
        
        // 复用缓存
        self.parser?.parse(with: text)
        XCTAssertEqual(request.count, 1)
    }
    
    // 失败可再次请求
    func testFailureTask() {
        let token = "wikcnPWH1693BZNKcPAM4VOGNKs"
        let text = "this is 1234 https://xxx.feishu.cn/wiki/\(token)  daacfaslvakvaskvasiojvsaoijvoaijv"
        
        let analysis = TestInlineAIDocURLAnalysis(token: "FJPVcYErSoVM6Axelq8c95nMnMh", type: .wiki)
        
        let request = TestURLRequest(testToken: "wikcnPWH1693BZNKcPAM4VOGNKs", testType: LarkDocsIcon.CCMDocsType.docX.rawValue)
        
        self.parser = InlineAIURLParser(regexString: regexString, docsIconRequest: request, docsUrlUtil: analysis)
        self.parser?.delegate = self

        request.setError = true
        request.needAsync = false
        
        self.parser?.parse(with: text)
        
        request.setError = false
        self.parser?.parse(with: text)
        
        XCTAssertEqual(request.count, 2)
    }
    
    func testEmptyTitle() {

        let types: [LarkDocsIcon.CCMDocsType] = [.doc, .docX, .wiki, .wikiCatalog, .sheet, .folder, .bitable, .mindnote, .slides, .file, .mediaFile, .whiteboard, .imMsgFile]
        
        for type in types {
            let token = "wikcnPWH1693BZNKcPAM4VOGNKs"
            let text = "this is 1234 https://xxx.feishu.cn/wiki/\(token)  daacfaslvakvaskvasiojvsaoijvoaijv"
            let analysis = TestInlineAIDocURLAnalysis(token: token, type: .wiki)
            let request = TestURLRequest(testToken: "FJPVcYErSoVM6Axelq8c95nMnMh", testType: type.rawValue, title: "")
            request.needAsync = false
            self.parser = InlineAIURLParser(regexString: regexString, docsIconRequest: request, docsUrlUtil: analysis)
            self.parser?.delegate = self
            
            self.parser?.parse(with: text)
            
            let dict = self.contentExtra ?? [:]
            let key = token
            let result = (dict[key] as? [String: Any]) ?? [:]
            XCTAssertEqual((result["icon_type"] as? Int), type.rawValue)
        }
        
    }
}


extension InlineAIURLParserTests: InlineAIURLParserDelegate {
    
    func didFinishParse(result: [String: Any]) {
        self.contentExtra = result
    }
    
    var tenantId: String {
        return "1"
    }
}

