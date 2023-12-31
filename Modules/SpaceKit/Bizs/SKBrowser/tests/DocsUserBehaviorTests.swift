//
//  DocsUserBehaviorTests.swift
//  SKBrowser-Unit-Tests
//
//  Created by lijuyou on 2023/3/31.
//  


import XCTest
@testable import SKBrowser
@testable import SKFoundation
import SKCommon

final class DocsUserBehaviorTests: XCTestCase {
    
    var baseList = [Int]()

    override func setUpWithError() throws {
        UserScopeNoChangeFG.setMockFG(key: "ccm.docs.forecast_enable", value: true)
        AssertionConfigForTest.disableAssertWhenTesting()
        for _ in 0..<100 {
            baseList.append(0)
        }
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        AssertionConfigForTest.reset()
    }
    
    
    func newList(_ list: [Int]) -> [Int] {
        let result = baseList + list
        return result
    }
    
    func testLoadData() {
        DocsUserBehaviorManager.shared.userDidLogin()
        DocsUserBehaviorManager.shared.queue.async {
            XCTAssertTrue(DocsUserBehaviorManager.shared.docsTypeUsages.count() > 0)
            DocsUserBehaviorManager.shared.docsTypeUsages.all().forEach { (key, usage) in
                //登录后会新增一个0次的数据
                XCTAssertTrue(!usage.recentOpenCount.isEmpty)
                XCTAssertTrue(usage.recentOpenCount.last! == 0)
            }
        }
    }
    
    
    func testPreloadTypes() throws {
        
        //按使用次数排序，并且不能超过五个
        let testData = [2: newList([0,0,0,0]),
                        22: newList([0,0,2,1]),
                        8: newList([5,5,2,2]),
                        3: newList([0,0,3,1]),
                        16: newList([0,0,0,3]),
                        30: newList([0,0,0,2]),
                        12: newList([0,0,0,1]),
                        111: newList([0,0,0,1]),
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData)
        let types = DocsUserBehaviorManager.shared.getPreloadTypes()
        let maxCount = DocsUserBehaviorManager.shared.maxPreloadTypeCount
        XCTAssertNotNil(types)
        XCTAssertTrue(types!.count <= maxCount)  //不能超过5个
        XCTAssertTrue(types == ["bitable", "sheet", "docx", "wiki", "slides"])
        
        //只返回满足条件的类型，其它很久没使用则淘汰
        let testData2 = [2: newList([10,0]),
                         22: newList([0,0,2,1]),
                         3: newList([0,1,2,2]),
                         8: newList([0,0,0,0]),
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData2)
        let types2 = DocsUserBehaviorManager.shared.getPreloadTypes()
        XCTAssertNotNil(types2)
        XCTAssertTrue(types2 == ["doc", "sheet", "docx"])
        
        //很久都没有打开文档，则应该返回空数组
        let testData3 = [2: newList([0,0]),
                         22: newList([0,0,0,0,0,0,0]),
                         3: newList([0,0,0,0]),
                         8: newList([0,0,0,0]),
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData3)
        let types3 = DocsUserBehaviorManager.shared.getPreloadTypes()
        XCTAssertNotNil(types3)
        XCTAssertTrue(types3!.isEmpty)
        
        //数据不够时，按默认配置
        let testData4 = [2: [0,0],
                         22: [0,0,0,0,0,0,0],
                         3: [0,0,0,0],
                         8: [0,0,0,0],
                         16: [0,0],
                         11: [0,0,0]
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData4)
        let types4 = DocsUserBehaviorManager.shared.getPreloadTypes()
        XCTAssertNotNil(types4)
        XCTAssertTrue(types4 == ["docx", "sheet", "bitable", "doc", "wiki"])
        
        
        //数据不够时，按默认配置，并按使用次数排序
        let testData5 = [2: [321,0],
                         22: [0,0,0,0,0,0,0],
                         3: [0,0,0,0],
                         8: [0,0,0,0],
                         16: [0,0],
                         11: [0,0,0]
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData5)
        let types5 = DocsUserBehaviorManager.shared.getPreloadTypes()
        XCTAssertNotNil(types5)
        XCTAssertTrue(types5 == ["doc", "docx", "sheet", "bitable", "wiki"])
    }
    
    func testOpenType() {
        let testData3 = [2: newList([0,0]),
                         3: newList([0,0,3,1]),
                         8: newList([0,0,2,0]),
                         11: newList([0,0,0])
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData3)
        
        //没有配置的类型，也不在setting默认配置里的mindnote不能预加载
        var shouldOpenMindnote = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .mindnote)
        XCTAssertFalse(shouldOpenMindnote)
        
        //docx也没有配置，但在setting默认配置，可以预加载
        let shouldOpenDocX = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .docX)
        XCTAssertTrue(shouldOpenDocX)
        
//        let expect1 = expectation(description: "testOpenType")
        let docsInfo = DocsInfo(type: .mindnote, objToken: "tempXXXXFDSSDFSDFSDFSDFSDF")
        DocsUserBehaviorManager.shared.openDocs(docsInfo: docsInfo)
        shouldOpenMindnote = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .mindnote)
        XCTAssertFalse(shouldOpenMindnote) //异步保存
//        DocsUserBehaviorManager.shared.queue.async {
//            //异步保存完成后，mindnote可以预加载了
//            shouldOpenMindnote = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .mindnote)
//            XCTAssertTrue(shouldOpenMindnote)
//            expect1.fulfill()
//        }
//        waitForExpectations(timeout: 10) { error in
//            XCTAssertNil(error)
//        }
    }
    
    
    func testShouldPreloadTemplate() {
        let testData = [2: newList([0,0,0,0]),
                        22: newList([0,0,2,1]),
                        8: newList([5,5,2,2]),
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData)
        
        let shouldOpenDoc = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .doc)
        XCTAssertFalse(shouldOpenDoc)
        let shouldOpenDocX = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .docX)
        XCTAssertTrue(shouldOpenDocX)
        let shouldOpenSheet = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .sheet)
        XCTAssertTrue(shouldOpenSheet)
        let shouldOpenBitable = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .bitable)
        XCTAssertTrue(shouldOpenBitable)
        let shouldOpenSlides = DocsUserBehaviorManager.shared.shouldPreloadTemplate(type: .slides)
        XCTAssertFalse(shouldOpenSlides)
    }

    func testPreloadWebView() {
        let testData2 = [2: newList([10,0]),
                         22: newList([0,0,2,1]),
                         3: newList([0,1,2,2]),
                         8: newList([0,0,0,0]),
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData2)
        
        let shouldPreloadWebview = DocsUserBehaviorManager.shared.shouldPreloadWebView()
        XCTAssertTrue(shouldPreloadWebview)
        
        //太久没使用了，不预加载webview
        let testData3 = [2: newList(newList([0,0])),
                         22: newList(newList([0,0,0,0,0,0,0])),
                         3: newList(newList([0,0,0,0])),
                         8: newList(newList([0,0,0,0])),
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData3)
        let shouldPreloadWebview2 = DocsUserBehaviorManager.shared.shouldPreloadWebView()
        // 仅在低端机生效，单测还mock不了
        // XCTAssertFalse(shouldPreloadWebview2)
        
        //数据不足，也要正常预加载
        let testData4 = [2: [0,0],
                         22: [0,0,0,0,0,0,0],
                         3: [0,0,0,0],
                         8: [0,0,0,0],
        ]
        DocsUserBehaviorManager.shared.injectTestData(testData4)
        let shouldPreloadWebview4 = DocsUserBehaviorManager.shared.shouldPreloadWebView()
        XCTAssertTrue(shouldPreloadWebview4)
    }
}
