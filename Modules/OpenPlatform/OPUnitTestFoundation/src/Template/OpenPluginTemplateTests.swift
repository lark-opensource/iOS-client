//
//  OpenPluginTemplateTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/2.
//  iOS-飞书-开平API 单测通用模板
/*
import XCTest
import ECOProbe
@testable import LarkOpenPluginManager

@available(iOS 13.0, *)
final class OpenPluginTemplateTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        AssertionConfigForTest.reset()
    }

    func test_asyncAPI() async throws {
        
        let apiName = "showToast"
        let params: [AnyHashable: Any] = [
            "title" : "testTitle"
        ]
        
        let exp = XCTestExpectation(description: "async")
        OpenPluginGadgetTestUtils().asyncCall(apiName: apiName, params: params) { response in
            switch response {
            case .failure(let error):
                print(error)
            case .success(let data):
                if let data = data {
                    print(data)
                }
            case .continue(let event, let data):
                print(event)
                if let data = data {
                    print(data)
                }
            @unknown default:
                fatalError()
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 2)
   }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
*/
