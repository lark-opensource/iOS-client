//
//  DictionaryExtenstionTests.swift
//  EENavigatorDevEEUnitTest
//
//  Created by xiongmin on 2021/10/18.
//

import Foundation
import XCTest
import EENavigator

class DictionaryExtenstionTests: XCTestCase {
    
    func testInitWithParmas() {
        var naviParmas = NaviParams()
        naviParmas.openType = .push
        let dict = Dictionary(naviParams: naviParmas)
        let result = (dict[ContextKeys.naviParams]) as? NaviParams
        XCTAssert(result?.openType == naviParmas.openType)
    }

}
