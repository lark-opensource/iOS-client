//
//  CCMTextDraftManagerTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/8/16.
//  


import XCTest
@testable import SKCommon
@testable import SKComment
import SpaceInterface

class CCMTextDraftManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testUpdateModel() {
        let mgr = CCMTextDraftManager(path: "test_path")
        let model = MockModel(myValue: "someValue")
        let key = MockKey(customKey: "myKey")
        mgr.updateModel(model, forKey: key)
        
        let result: Swift.Result<MockModel, Error> = mgr.getModel(forKey: key)
        switch result {
        case .success(let model2):
            XCTAssert(model2.myValue == model.myValue)
        case .failure:
            XCTFail("update model failed")
        }
    }
    
    func testGetModel() {
        let mgr = CCMTextDraftManager(path: "test_path2")
        let model = MockModel(myValue: "someValue2")
        let key = MockKey(customKey: "myKey2")
        mgr.updateModel(model, forKey: key)
        
        let result: Swift.Result<MockModel, Error> = mgr.getModel(forKey: key)
        switch result {
        case .success(let model2):
            XCTAssert(model2.myValue == model.myValue)
        case .failure:
            XCTFail("get model failed")
        }
    }
    
    func testRemoveModel() {
        let mgr = CCMTextDraftManager(path: "test_path3")
        let model = MockModel(myValue: "someValue3")
        let key = MockKey(customKey: "myKey3")
        mgr.updateModel(model, forKey: key)
        mgr.removeModel(forKey: key)
        
        let result: Swift.Result<MockModel, Error> = mgr.getModel(forKey: key)
        switch result {
        case .success:
            XCTFail("remove model failed")
        case .failure:
            break // 符合预期
        }
    }
}

private struct MockKey: CCMTextDraftKey {
    
    var entityId: String? { nil }
    
    let customKey: String
}

private struct MockModel: Codable {
    
    let myValue: String
    
    enum CodingKeys: String, CodingKey {
        case myValue
    }
    
    init(myValue: String) {
        self.myValue = myValue
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        myValue = try values.decode(String.self, forKey: .myValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myValue, forKey: .myValue)
    }
}
