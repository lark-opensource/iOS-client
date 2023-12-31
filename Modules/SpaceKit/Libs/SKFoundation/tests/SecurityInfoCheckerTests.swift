//
//  SecurityInfoCheckerTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/6/19.
//  


import XCTest
@testable import SKFoundation

class SecurityInfoCheckerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testEncryptLogIfNeed() {
        let list = ["doxcnXDUZUUc72xEHHnrCrTOLrf",
                    "wikcn39y16thSfETXiM7KEJ6XOc",
                    "boxcnajTX2Hol9ApYjamrJOyi1d",
                    "bmncnORD1oRB5gtJjcITTmsWMHG",
                    "WBjOdjPXMoKk9dxKs9floCFvgag", //new wiki
                    "NG0Od5GOyo6oefxch2NlpiImg3f", //new docx
                    "SXBTsMufdhz9hstO0yblvRLXg8b", //new sheet
                    "PBWqbr4YJauLYksxxiPlnSVUgKz",
                    "ZiSYdHFEVoHLWExRIMslelXIgIb"] //new bitable
        let tokenStr = list.joined(separator: ",")
        let error = NSError(domain: "test", code: 1002, userInfo: ["data": "wikcn39y16thSfETXiM7KEJ6XOc"])
        let logEvent = DocsLogEvent(level: .error,
                    message: tokenStr,
                    extraInfo: ["token": "bmncnORD1oRB5gtJjcITTmsWMHG"],
                    error: error,
                    component: nil,
                    time: 0,
                    thread: nil,
                    fileName: "test",
                    funcName: "test",
                    funcLine: 1)
        let expect = expectation(description: "test encryptLog")
        SecurityInfoChecker.shared.encryptLogIfNeed(logEvent) { event in
            for token in list {
                XCTAssertFalse(String(describing: event).contains(token))
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testEncryptToShort() {
        let list = ["doxcnXDUZUUc72xEHHnrCrTOLrf",
                    "wikcn39y16thSfETXiM7KEJ6XOc",
                    "boxcnajTX2Hol9ApYjamrJOyi1d",
                    "bmncnORD1oRB5gtJjcITTmsWMHG",
                    "WBjOdjPXMoKk9dxKs9floCFvgag", //new wiki
                    "NG0Od5GOyo6oefxch2NlpiImg3f", //new docx
                    "SXBTsMufdhz9hstO0yblvRLXg8b", //new sheet
                    "PBWqbr4YJauLYksxxiPlnSVUgKz",
                    "ZiSYdHFEVoHLWExRIMslelXIgIb"] //new bitable
        let tokenStr = list.joined(separator: ",")
        let result = SecurityInfoChecker.shared.encryptToShort(text: tokenStr)
        for token in list {
            XCTAssertFalse(result.contains(token))
        }
    }
}
