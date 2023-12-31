//
//  DocsCoverUtilTests.swift
//  SpaceDemoTests
//
//  Created by lijuyou on 2022/3/7.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
import SpaceInterface
import SKInfra

//SKDocsCoverUtil.swift
class DocsCoverUtilTests: XCTestCase {
    
    func testGetCoverType() {
        //https://bytedance.feishu.cn/docx/doxcncwx7EqdxC7myMOhAufUy0f
        
        var coverType = SKDocsCoverUtil.getCoverType(width: 100.0, height: 100.0, scale: 1, useDisplayWidth: true)
        XCTAssertEqual(coverType, DocCommonDownloadType.small)
        
        coverType = SKDocsCoverUtil.getCoverType(width: 600.0, height: 600.0, scale: 1, useDisplayWidth: false)
        XCTAssertEqual(coverType, DocCommonDownloadType.middle)
        
        // TODO: lijuyou 处理
//        coverType = SKDocsCoverUtil.getCoverType(width: 1000.0, height: 1000.0, scale: 1, useDisplayWidth: true)
//        XCTAssertEqual(coverType, DocCommonDownloadType.bigCover)
    }
}
