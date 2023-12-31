//
//  OPJSRuntimeBackgroundAPIReportTests.swift
//  TTMicroApp-Unit-Tests
//
//  Created by baojianjun on 2023/7/8.
//

import XCTest
import OPFoundation
@testable import TTMicroApp

@available(iOS 13.0, *)
final class OPJSRuntimeBackgroundAPIReportTests: XCTestCase {
    
    private let report = OPJSRuntimeBackgroundAPIReport()
    private let testUniqueID = OPAppUniqueID(appID: "testAppID", identifier: nil, versionType: .current, appType: .gadget)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_oneElement() throws {
        
        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 1,
            "duration": 1,
            "api_list": "testAPIName1",
            "api_name1": "testAPIName1",
            "api_count1": 1,
            "api_name2": "",
            "api_count2": 0,
            "api_name3": "",
            "api_count3": 0,
            "api_name4": "",
            "api_count4": 0,
            "api_name5": "",
            "api_count5": 0,
        ]
        
        let result = categoryMap(queue: ["testAPIName1"], duration: 1)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    func test_fiveElement() throws {
        
        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 5,
            "duration": 10,
            "api_list": [
                "testAPIName1",
                "testAPIName2",
                "testAPIName3",
                "testAPIName1",
                "testAPIName2",
            ].joined(separator: ","),
            "api_name1": "testAPIName1",
            "api_count1": 2,
            "api_name2": "testAPIName2",
            "api_count2": 2,
            "api_name3": "testAPIName3",
            "api_count3": 1,
            "api_name4": "",
            "api_count4": 0,
            "api_name5": "",
            "api_count5": 0,
        ]
        
        let result = categoryMap(queue: [
            "testAPIName1",
            "testAPIName2",
            "testAPIName3",
            "testAPIName1",
            "testAPIName2",
        ], duration: 10)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    func test_eightElement() throws {
        
        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 8,
            "duration": 10,
            "api_list": [
                "testAPIName1",
                "testAPIName2",
                "testAPIName3",
                "testAPIName4",
                "testAPIName5",
                "testAPIName6",
                "testAPIName7",
                "testAPIName7",
            ].joined(separator: ","),
            "api_name1": "testAPIName7",
            "api_count1": 2,
            "api_name2": "testAPIName1",
            "api_count2": 1,
            "api_name3": "testAPIName2",
            "api_count3": 1,
            "api_name4": "testAPIName3",
            "api_count4": 1,
            "api_name5": "testAPIName4",
            "api_count5": 1,
        ]
        
        let result = categoryMap(queue: [
            "testAPIName1",
            "testAPIName2",
            "testAPIName3",
            "testAPIName4",
            "testAPIName5",
            "testAPIName6",
            "testAPIName7",
            "testAPIName7",
        ], duration: 10)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    func test_14Element() throws {
        
        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 14,
            "duration": 10,
            "api_list": [
                "testAPIName1",
                "testAPIName2",
                "testAPIName3",
                "testAPIName4",
                "testAPIName5",
                "testAPIName6",
                "testAPIName7",
                "testAPIName1",
                "testAPIName1",
                "testAPIName1",
                "testAPIName4",
                "testAPIName4",
                "testAPIName6",
                "testAPIName3",
            ].joined(separator: ","),
            "api_name1": "testAPIName1",
            "api_count1": 4,
            "api_name2": "testAPIName4",
            "api_count2": 3,
            "api_name3": "testAPIName3",
            "api_count3": 2,
            "api_name4": "testAPIName6",
            "api_count4": 2,
            "api_name5": "testAPIName2",
            "api_count5": 1,
        ]
        
        let result = categoryMap(queue: [
            "testAPIName1",
            "testAPIName2",
            "testAPIName3",
            "testAPIName4",
            "testAPIName5",
            "testAPIName6",
            "testAPIName7",
            "testAPIName1",
            "testAPIName1",
            "testAPIName1",
            "testAPIName4",
            "testAPIName4",
            "testAPIName6",
            "testAPIName3",
        ], duration: 10)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    func test_twentyoneElement() throws {
        
        let apiList: [(String, Int)] = [
            ("testAPIName5", 5),
            ("testAPIName1", 4),
            ("testAPIName2", 4),
            ("testAPIName3", 4),
            ("testAPIName4", 4),
        ]
        
        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 21,
            "duration": 10,
            "api_list": toJSONString(sortedPairs: apiList),
            "api_name1": "testAPIName5",
            "api_count1": 5,
            "api_name2": "testAPIName1",
            "api_count2": 4,
            "api_name3": "testAPIName2",
            "api_count3": 4,
            "api_name4": "testAPIName3",
            "api_count4": 4,
            "api_name5": "testAPIName4",
            "api_count5": 4,
        ]
        
        let result = categoryMap(queue: [
            "testAPIName1",
            "testAPIName1",
            "testAPIName1",
            "testAPIName1",
            "testAPIName2",
            "testAPIName2",
            "testAPIName2",
            "testAPIName2",
            "testAPIName3",
            "testAPIName3",
            "testAPIName3",
            "testAPIName3",
            "testAPIName4",
            "testAPIName4",
            "testAPIName4",
            "testAPIName4",
            "testAPIName5",
            "testAPIName5",
            "testAPIName5",
            "testAPIName5",
            "testAPIName5",
        ], duration: 10)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    func test_fortyElement() throws {
        
        let apiList: [(String, Int)] = [
            ("value1", 3),
            ("value2", 3),
            ("value3", 3),
            ("value4", 3),
            ("value5", 3),
            ("value6", 3),
            ("value7", 3),
            ("value8", 3),
            ("value9", 3),
            ("value10", 3),
            ("value11", 2),
            ("value12", 2),
            ("value13", 2),
            ("value14", 2),
            ("value15", 2),
        ]

        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 40,
            "duration": 10,
            "api_list": toJSONString(sortedPairs: apiList),
            "api_name1": "value1",
            "api_count1": 3,
            "api_name2": "value2",
            "api_count2": 3,
            "api_name3": "value3",
            "api_count3": 3,
            "api_name4": "value4",
            "api_count4": 3,
            "api_name5": "value5",
            "api_count5": 3,
        ]
        
        let array: [String] = [
            "value1", "value2", "value3", "value4", "value5",
            "value6", "value7", "value8", "value9", "value10",
            "value11", "value12", "value13", "value14", "value15",
            "value1", "value2", "value3", "value4", "value5",
            "value6", "value7", "value8", "value9", "value10",
            "value11", "value12", "value13", "value14", "value15",
            "value1", "value2", "value3", "value4", "value5",
            "value6", "value7", "value8", "value9", "value10"
        ]
        
        let result = categoryMap(queue: array, duration: 10)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    func test_114Element() throws {
        
        let apiList = [
            ("element1", 8),
            ("element2", 7),
            ("element26", 6),
            ("element20", 5),
            ("element3", 3),
            ("element4", 3),
            ("element5", 3),
            ("element6", 3),
            ("element7", 3),
            ("element8", 3),
            ("element9", 3),
            ("element10", 3),
            ("element11", 3),
            ("element12", 3),
            ("element13", 3),
            ("element14", 3),
            ("element15", 3),
            ("element16", 3),
            ("element17", 3),
            ("element18", 3),
            ]

        let resultExample: [String: any Codable & Equatable] = [
            "api_count" : 114,
            "duration": 10,
            "api_list": toJSONString(sortedPairs: apiList),
            "api_name1": "element1",
            "api_count1": 8,
            "api_name2": "element2",
            "api_count2": 7,
            "api_name3": "element26",
            "api_count3": 6,
            "api_name4": "element20",
            "api_count4": 5,
            "api_name5": "element3",
            "api_count5": 3,
        ]
        
        let array: [String] = [
            "element1", "element2", "element3", "element4", "element5",
            "element6", "element7", "element8", "element9", "element10",
            "element11", "element12", "element13", "element14", "element15",
            "element16", "element17", "element18", "element19", "element20",
            "element21", "element22", "element23", "element24", "element25",
            "element26", "element27", "element28", "element29", "element30",
            "element1", "element2", "element3", "element4", "element5",
            "element6", "element7", "element8", "element9", "element10",
            "element11", "element12", "element13", "element14", "element15",
            "element16", "element17", "element18", "element19", "element20",
            "element21", "element22", "element23", "element24", "element25",
            "element26", "element27", "element28", "element29", "element30",
            "element1", "element2", "element3", "element4", "element5",
            "element6", "element7", "element8", "element9", "element10",
            "element11", "element12", "element13", "element14", "element15",
            "element16", "element17", "element18", "element19", "element20",
            "element21", "element22", "element23", "element24", "element25",
            "element26", "element27", "element28", "element29", "element30",
            "element31", "element32", "element33", "element34", "element35",
            "element36", "element37", "element38", "element39", "element40",
            "element1", "element1", "element1", "element1", "element1",
            "element2", "element2", "element2", "element2",
            "element26", "element26", "element26",
            "element20", "element20",
        ]
        
        let result = categoryMap(queue: array, duration: 10)
        
        resultExample.forEach { key, value in
            if let item = result[key] {
                XCTAssert(Self.isEqualTo(item, value), "key: \(key), value: \(item) is not equalTo \(value)")
            } else {
                XCTAssert(false, "can not find key \(key) in categoryMap: \(String(describing: categoryMap))")
            }
        }
    }
    
    fileprivate static func isEqualTo(_ lhs: Any, _ rhs: Any) -> Bool {
        if let lhsNumber = lhs as? Double, let rhsNumber = rhs as? Double {
            return lhsNumber == rhsNumber
        } else if let lhsNumber = lhs as? Int, let rhsNumber = rhs as? Int {
            return lhsNumber == rhsNumber
        } else if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString == rhsString
        } else if let lhsDict = lhs as? Dictionary<AnyHashable, Any>, let rhsDict = rhs as? Dictionary<AnyHashable, Any> {
            var result = true
            lhsDict.forEach { key, value in
                guard result else {
                    return
                }
                if let rhsValue = rhsDict[key] {
                    result = isEqualTo(value, rhsValue)
                } else {
                    result = false
                }
            }
            return result
        } else if let lhsArray = lhs as? [String], let rhsArray = rhs as? [String] {
            return lhsArray == rhsArray
        }
        return false
    }
    
    func test_multiThreadedScenario() throws {
        // 创建一个期望
        let expectation = XCTestExpectation(description: "Multi-threaded scenario")
        
        report.enterBackground()
        
        let dispatchGroup = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "com.bytedance.concurrentQueue", attributes: .concurrent)

        let totalTasks = 20
        for i in 1...totalTasks {
            
            dispatchGroup.enter()
            
            concurrentQueue.async {
                // 执行你的并发任务逻辑
                self.report.push(apiName: "apiName\(i)")
                
                dispatchGroup.leave()
            }
        }

        // 当所有任务完成时触发期望完成
        dispatchGroup.notify(queue: DispatchQueue.main) {
            XCTAssert(self.report.queue.count == 20)
            expectation.fulfill()
        }

        // 等待期望达成，最多等待 10 秒钟
        wait(for: [expectation], timeout: 10.0)
    }
}
