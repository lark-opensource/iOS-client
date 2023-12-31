//
//  MapperTests.swift
//  SKCommonTests
//
//  Created by huayufan on 2022/7/27.
//  Copyright © 2022 Bytedance.All rights reserved.


import XCTest
@testable import SKCommon
import SKFoundation

class MapperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
   
   
   func testMapModel() {
      // 正常解析
       let logParams1: [String: Any] = ["level": 0, 
                                       "msg": "test",
                                       "tag": "clip"]
      
      let model1: ClippingLogModel? = logParams1.mapModel()
      XCTAssertNotNil(model1)


      // 缺少必要字段
      let logParams2: [String: Any] = ["msg": "test",
                                       "tag": "clip"]
      let model2: ClippingLogModel? = logParams2.mapModel()
      XCTAssertNil(model2)
   }
}
